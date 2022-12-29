classdef RiskPositions < handle
  
  properties (Constant)
    MAX_ACTIVE_REQUESTS = 32;
    
    OMS_STATUS_MANUAL = 1;
    OMS_STATUS_AUTO = 2;
    OMS_STATUS_REQPENDING = 3;
    OMS_STATUS_CANCELLING = 4;
    OMS_STATUS_REPORTPENDING = 5;
    OMS_STATUS_DELAY = 6;
    OMS_STATUS=...
      {'MANUAL','AUTO','REQPENDING','CANCELLING',...
      'REPORTPENDING','DELAY'};
    
    OMSREPORTS_ORDTYPE_LIMIT = 1;
    OMSREPORTS_ORDTYPE_STOP = 2;
    OMSREPORTS_ORDTYPE_IOC = 3;
    
    REQSIZE = 50000;
    REPORTSIZE = 50000;
    %TRADESIZE = 10000;
    TRADESIZE = 20000;
    
    PROFILESIZE = 30000; % alterado por abend no profileposition graph
  end 
  
  properties
    Main
    Instance
    keys
    %Classes
    IO
    Account
    Strategy
    Symbol
    OMS
    %states
    rolltrades = false;
    simulated = true
    activeOMS = 0
    npos = 0
    nsignal = 0;
    %time 
    period
    timeid
    timevec
    %POSITION PROFILE CONTROL
    strategyfunction
    %% TAGS
    %POSITION STATUS
    autotrade
    status
    %RISK MANAGEMENT
    alocation       %max equity in position
    stoploss        %stoploss price / result
    %SETPOINTS
    setpositionprofile
    setrlogprofile
    %CALCULATED PROFILES
    reqordersprofile
    reqpositionprofile
    reqresultprofile
    %TRADE REQUESTS
    activeidx
    reqorders
    reqtrade
    %TRADES INPUTS
    ntrades = 0
    trades
    tradedirection
    contracts
    avgprice
    notional
    resultclosed
    %stats
    positions = 0;
    positionscontracts = zeros(5000,1);
    positionsequity = zeros(5000,1);
    positionslong = zeros(5000,1);
    positionsshort = zeros(5000,1);
    positionspoints = zeros(5000,1);
    positionsreturn = zeros(5000,1);
    positionsresult = zeros(5000,1);
    
  end
  
  methods
  %% CONSTRUCTOR
    function this = RiskPositions(Account,Strategy,Symbol,instance)
      if nargin > 0
        this.Main = Symbol.Main;
        this.Account = Account;
        this.Strategy = Strategy;
        this.Instance = instance;
        this.Symbol = Symbol;
        %Database file path, tablename & keys
        this.Instance.Attributes.table = 'riskpositions';
        if strcmp(this.Instance.Attributes.simulated,'false')
          this.simulated = false;
        end
        if this.simulated
          this.Instance.Attributes.source = 'SIM';
          this.Instance.Attributes.IO = 'output';
        else
          this.Instance.Attributes.source = 'RT';
          if (this.Main.sim || this.Main.backtest)
            this.Instance.Attributes.IO = 'input';
          else
            this.Instance.Attributes.IO = 'output';
          end
        end
        %this.Instance.Attributes.history = this.Main.history;
        this.Instance.Attributes.history = ...
          str2double(this.Account.Instance.Attributes.history);
        this.keys = this.Instance.Attributes;
        %I/O Files initialization
        this.IO = FileIO(this.Main,this.Instance);
        this.strategyfunction = str2func(this.keys.strategy);
        InitPosition(this);
        InitOMS(this);
        InitSignals(this);
      end
    end
    function InitPosition(this)
      %tags initialize
      this.autotrade = zeros(1,this.IO.cols_count);
      this.status = zeros(1,this.IO.cols_count);
      this.alocation = zeros(1,this.IO.cols_count);
      pcol = this.IO.cols;
      allocation = getAllocation(this,fix(now));
      if isempty(allocation)
        this.alocation(pcol.value) = str2double(this.keys.alocation);
      else
        this.alocation(pcol.value) = allocation;
      end
      this.stoploss = zeros(1,this.IO.cols_count);
      this.setpositionprofile=zeros(1,this.PROFILESIZE);
      this.setrlogprofile=zeros(1,this.PROFILESIZE);
      this.reqtrade = zeros(1,this.IO.cols_count);
      this.reqorders=zeros(this.MAX_ACTIVE_REQUESTS,this.IO.cols_count);
      this.reqpositionprofile = zeros(1,this.PROFILESIZE);
      this.reqresultprofile = zeros(1,this.PROFILESIZE);
      this.period = str2double(this.Instance.Attributes.period);
      this.period = datenum(0,0,0,0,0,this.period);
      this.timevec = this.period:this.period:1;
      this.timeid = 0;
    end
    function InitOMS(this)
      this.OMS = OMSConnector.empty;
      %INIT OMS
      for o=1:length(this.Account.Instance.oms)
        inst = this.Instance;
        if length(this.Account.Instance.oms) == 1
          inst.Attributes.oms = this.Account.Instance.oms.Attributes.oms;
          inst.Attributes.db = this.Account.Instance.oms.Attributes.db;
          inst.Attributes.active=...
            this.Account.Instance.oms.Attributes.active;
          inst.Attributes.from=...
            this.Account.Instance.Attributes.from;
        else
          inst.Attributes.oms=this.Account.Instance.oms{o}.Attributes.oms;
          inst.Attributes.db=this.Account.Instance.oms{o}.Attributes.db;
          inst.Attributes.active=...
            this.Account.Instance.oms{o}.Attributes.active;
          inst.Attributes.from=...
            this.Account.Instance.Attributes.from;
        end
        this.OMS(length(this.OMS)+1) = OMSConnector(this,inst);
        if strcmp(inst.Attributes.active,'true')
          this.activeOMS = length(this.OMS);
        end
      end
      cols_count = this.OMS(1).OMSTrades.cols_count;
      this.trades = zeros(this.TRADESIZE,cols_count);
      this.tradedirection = zeros(this.TRADESIZE,1);
      this.contracts = zeros(this.TRADESIZE,1);
      this.avgprice = zeros(this.TRADESIZE,1);
      this.notional = zeros(this.TRADESIZE,1);
      this.resultclosed = zeros(this.TRADESIZE,1);
    end
    function InitSignals(this)
      this.npos=this.keys.npos;
      for s=1:length(this.Symbol.signals)
        currsig = this.Symbol.signals(s).signal;
        if strcmp(this.keys.strategy,currsig)
          this.nsignal = s;
          break;
        end
      end
    end
    function InitResults(this)
      symbol = this.Symbol;
      n=symbol.n;
      np = this.npos;
      q = this.Symbol.tickvalue/this.Symbol.ticksize;
      pcol = this.IO.cols;
      quotes = this.Main.quotes;
      if any(symbol.positions.contracts(np,:))
      symbol.positions.resultcurrent(np,:)=...
        (symbol.positions.contracts(np,:).*q.*...
        (this.Main.quotes.close(n,:)-symbol.positions.avgprice(np,:)))+...
        symbol.positions.resultclosed(np,:);
      end
      for d=1:length(quotes.tradedates)
        fb = quotes.firstbar(d);
        ob = quotes.openbar(n,d);
        lb = quotes.lastbar(n,d);
        if fb>1
          closep = quotes.close(n,fb-1);
        else
          closep = quotes.close(n,fb);
        end
        allocation = 0;
        allocation = this.getAllocation(quotes.tradedates(d));
        if isempty(allocation)
          allocation = max(abs(symbol.positions.contracts(np,fb:lb)));
        end
        maxcts=allocation/(closep*q);
        maxcts = round(maxcts/symbol.lotmin)*symbol.lotmin;
        if maxcts>0
          symbol.positions.delta(np,fb:lb) = ...
            symbol.positions.contracts(np,fb:lb)./maxcts;    
          symbol.positions.gamma(np,fb:lb) = ...
            [0,diff(symbol.positions.delta(np,fb:lb))];
          symbol.positions.alocation(np,fb:lb)=maxcts*closep*q;
          symbol.positions.equity(np,fb:lb) = ...
            symbol.positions.alocation(np,fb:lb)+...
            (symbol.positions.resultcurrent(np,fb:lb)-...
              symbol.positions.resultcurrent(np,fb));
          symbol.positions.rlog(np,fb:lb)=...
            [0, log(symbol.positions.equity(np,fb+1:lb)./...
                    symbol.positions.equity(np,fb:lb-1))];
        end
        symbol.positions.lastbar(np) = lb;
      end
      symbol.positions.rlogaccum(np,:)=cumsum(symbol.positions.rlog(np,:));
      symbol.positions.gammaaccum(np,:)=...
        cumsum(abs(symbol.positions.gamma(np,:)));
      if this.nsignal>0
        radj=symbol.signals(this.nsignal).rlog(1:quotes.lastbar(n,end));
        firstid = find(symbol.positions.delta(np,:),1,'first');
        if ~isempty(firstid)
          radj(1:firstid)=0;
        end
        lastid = find(symbol.positions.delta(np,:),1,'last');
        if ~isempty(lastid)
          lidx = find(quotes.lastbar(n,:)>lastid,1,'first');
          if ~isempty(lidx)
            lastid = quotes.lastbar(n,lidx);
            radj(lastid:end)=0;
          end
        end
        symbol.positions.rlogaccumadj(np,:)= cumsum(radj);
        maxalloc = max(symbol.positions.alocation(np,:));
        if maxalloc>0
          allocratio = symbol.positions.alocation(np,:)./maxalloc;
          symbol.positions.rlogaccumalloc(np,:)= cumsum(radj.*allocratio);
        end
        symbol.positions.slippage(np,:) = ...
          (symbol.positions.rlogaccum(np,:)...
          -symbol.positions.rlogaccumadj(np,:));
        symbol.positions.gammaslippage(np) = ...
          symbol.positions.slippage(np,end)/...
          symbol.positions.gammaaccum(np,end);
        
        fprintf('\nSymbol: %s, avgslippage: %f',...
          symbol.symbol,symbol.positions.gammaslippage(np));
      end
    end
    function allocation = getAllocation(this,tradedate)
      query = sprintf(['SELECT d_allocation '...
        'FROM dbaccounts.omsquotes '...
        'WHERE s_source=''RT'' '...
        'AND s_tradedate=''%s'' '...
        'AND s_account=''%s'' '...
        'AND s_strategy=''%s'' '...
        'AND s_symbol like ''%s%%'' ;'],...
        datestr(tradedate,'yyyy-mm-dd'),...
        this.Instance.Attributes.account,...
        this.Instance.Attributes.strategy,...
        this.Symbol.symbol(1:3));
      h = mysql( 'open', this.Main.db.dbaccounts.host,...
        this.Main.db.dbaccounts.user, this.Main.db.dbaccounts.password );
      allocation = mysql(query);
      mysql('close') ;
    end
    
  %% POSITION MANAGEMENT
    function ManagePosition(this)
      symbol = this.Symbol;
      n=symbol.n;
      if this.Main.quotes.lastbar(n,end) > 0
        pcol = this.IO.cols;
        %EXECUTION SIMULATION
        if this.simulated
          SimulateExecutions(this);
        end
        %POSITION TRADES RESULTS
        UpdateTrades(this,false);
        CalculateResults(this,false);
        %ORDERS MANAGEMENT
        if ~this.simulated
          for o=1:length(this.OMS)
            currOMS = this.OMS(o);
            if currOMS.OMSRequests.isinput
              currOMS.UpdateRequests();
            end
            currOMS.UpdateOrders();
            if o==this.activeOMS
              this.status(pcol.value) = ...
                currOMS.UpdateStatus(this.autotrade(pcol.value));
            end
          end
        end
        %POSITION PROFILE FUNCTION
        this.strategyfunction(this);
        %REQUEST POSITION PROFILE
        Updatereqpositionprofile(this);
        %APPLY POSITION
        if this.period==0
          if this.autotrade(pcol.value) && ...
                ~this.simulated && ~this.Main.charting
            this.ApplyPosition();
          end
        else
          currtimeid=floor((this.Main.time-fix(this.Main.time))/this.period);
          if currtimeid>this.timeid
            this.timeid = currtimeid;
            if this.autotrade(pcol.value) && ...
                ~this.simulated && ~this.Main.charting
              this.ApplyPosition();
            end
          end
        end
      end
    end
    function SimulateExecutions(this)
      n=this.Symbol.n;
      lb = this.Main.quotes.lastbar(n,end);
      closep = this.Main.quotes.close(n,lb-1);
      maxp = this.Main.quotes.max(n,lb);
      minp = this.Main.quotes.min(n,lb);
      
      pcol = this.IO.cols;
      tag = this.IO.tags;
      tagid = this.IO.tagid;
      lastid = this.OMS(this.activeOMS).OMSTrades.lastid;
      tbuff = this.OMS(this.activeOMS).OMSTrades;
      tcol = tbuff.cols;
      tradetag = tbuff.tagid(tbuff.tags.tradeagressor);
      %simtime = this.Main.time + datenum(0,0,0,this.Main.GMT,0,0);
      simtime = this.Main.time;
      % REQTRADE IOC ORDERS
      longidx = this.reqtrade(:,pcol.value) > 0;
      if any(longidx)
        limitidx = this.reqtrade(:,pcol.tag)==tagid(tag.reqlimit);
        tradeidx=limitidx & closep<=this.reqtrade(:,pcol.price) & longidx;
        if any(tradeidx)
          tradepx = this.reqtrade(tradeidx,pcol.price);
          if tradepx > closep
            tradepx = closep;
          end
          nt = sum(tradeidx);
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = ones(nt,1).*tradepx;
          newtrades(:,tcol.value) = this.reqtrade(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
        end
        this.reqtrade(:,pcol.value) = 0;
      end
      shortidx = this.reqtrade(:,pcol.value) < 0;
      if any(shortidx)
        limitidx = this.reqtrade(:,pcol.tag)==tagid(tag.reqlimit);
        tradeidx= limitidx & closep>=this.reqtrade(:,pcol.price) & shortidx;
        if any(tradeidx)
          tradepx = this.reqtrade(tradeidx,pcol.price);
          if tradepx < closep
            tradepx = closep;
          end
          nt = sum(tradeidx);
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = ones(nt,1).*tradepx;
          newtrades(:,tcol.value) = this.reqtrade(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
        end
        this.reqtrade(:,pcol.value) = 0;
      end
      
      % PENDING ORDERS
      longidx = this.reqorders(:,pcol.value) > 0;
      if any(longidx)
        % LONG LIMIT ORDERS
        limitidx = this.reqorders(:,pcol.tag)==tagid(tag.reqlimit);
        tradeidx=limitidx & minp<this.reqorders(:,pcol.price) & longidx;
        if any(tradeidx)
          nt = sum(tradeidx);
          tradepx = this.reqorders(tradeidx,pcol.price);
          trademinidx = tradepx > maxp;
          if any(trademinidx)
            tradepx(trademinidx) = maxp;
          end
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = tradepx;
          newtrades(:,tcol.value) = this.reqorders(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
          this.reqorders(tradeidx,pcol.value) = 0;
        end
        % LONG STOP ORDERS
        stopidx = this.reqorders(:,pcol.tag)==tagid(tag.reqstop);
        tradeidx= stopidx & maxp>=this.reqorders(:,pcol.price) & longidx;
        if any(tradeidx)
          nt = sum(tradeidx);
          tradepx = this.reqorders(tradeidx,pcol.price);
          trademinidx = tradepx > maxp;
          if any(trademinidx)
            tradepx(trademinidx) = maxp;
          end
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = tradepx;
          newtrades(:,tcol.value) = this.reqorders(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
          this.reqorders(tradeidx,pcol.value) = 0;
        end
      end
      shortidx = this.reqorders(:,pcol.value) < 0;
      if any(shortidx)
        % SHORT LIMIT ORDERS
        limitidx = this.reqorders(:,pcol.tag)==tagid(tag.reqlimit);
        tradeidx= limitidx & maxp>this.reqorders(:,pcol.price) & shortidx;
        if any(tradeidx)
          nt = sum(tradeidx);
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = this.reqorders(tradeidx,pcol.price);
          newtrades(:,tcol.value) = this.reqorders(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
          this.reqorders(tradeidx,pcol.value) = 0;
        end
        % SHORT STOP ORDERS
        stopidx = this.reqorders(:,pcol.tag)==tagid(tag.reqstop);
        tradeidx=stopidx & minp<=this.reqorders(:,pcol.price) & shortidx;
        if any(tradeidx)
          nt = sum(tradeidx);
          newtrades = zeros(nt,tbuff.cols_count);
          lastid = lastid + nt;
          newtrades(:,tcol.id) = [lastid-nt+1:lastid]';
          newtrades(:,tcol.tag) = tradetag;
          newtrades(:,tcol.time) = ones(nt,1).*simtime;
          newtrades(:,tcol.timestamp) = ones(nt,1).*simtime;
          newtrades(:,tcol.price) = this.reqorders(tradeidx,pcol.price);
          newtrades(:,tcol.value) = this.reqorders(tradeidx,pcol.value);
          if isempty(tbuff.buffer)
            tbuff.buffer = newtrades;
          else
            tbuff.buffer(end+1:end+nt,:) = newtrades;
          end
          this.reqorders(tradeidx,pcol.value) = 0;
        end
      end
    end
    function UpdateTrades(this,init)
      lastntrades = this.ntrades;
      %% parse trades
      for o=1:length(this.OMS)
        if ~isempty(this.OMS(o).OMSTrades.buffer)
          newtrades = size(this.OMS(o).OMSTrades.buffer,1);
          this.trades(this.ntrades+1:this.ntrades+newtrades,:) = ...
            this.OMS(o).OMSTrades.buffer;
          this.ntrades = this.ntrades + newtrades;
          if this.Main.backtest || ...
              ~this.simulated || ~this.OMS(o).OMSTrades.isoutput
            this.OMS(o).OMSTrades.buffer = [];
          end
        end
      end
      
      if init
        try
          inicts = str2double(this.Instance.Attributes.position);
          inim2m = str2double(this.Instance.Attributes.m2m);
          
          tcol = this.OMS(1).OMSTrades.cols;
          this.trades(1:this.ntrades,:) = sortrows(...
            this.trades(1:this.ntrades,:),tcol.timestamp);
          delidx = ...
            find(this.trades(1:this.ntrades,tcol.timestamp)<fix(now));
          this.trades(delidx,:) = [];
          nrows = size(this.trades,1);
          ncols = size(this.trades,2);
          this.trades(end+1:this.TRADESIZE,:) = zeros(this.TRADESIZE-nrows,ncols);
          this.ntrades = this.ntrades-length(delidx);
          this.ntrades = this.ntrades+1;
          symbol = this.Symbol;
          this.trades(this.ntrades,tcol.timestamp) = symbol.Main.quotes.time(end);
          this.trades(this.ntrades,tcol.time) = symbol.Main.quotes.time(end);
          this.trades(this.ntrades,tcol.price) = inim2m;
          this.trades(this.ntrades,tcol.value) = inicts;
        catch ME
            disp('')
            disp('Error Initializing positions. Message: ')
            disp(ME.message)
        end
      end
      
      %% update trade results
      if this.ntrades>lastntrades
        tcol = this.OMS(1).OMSTrades.cols;
        this.trades(lastntrades+1:this.ntrades,:) = sortrows(...
          this.trades(lastntrades+1:this.ntrades,:),tcol.timestamp);
        for p=lastntrades+1:this.ntrades
          q = this.Symbol.tickvalue/this.Symbol.ticksize; 
          if p<=1
            this.tradedirection(p) = 1;
            this.contracts(p) = this.trades(p,tcol.value);
            this.avgprice(p) = this.trades(p,tcol.price);
            this.resultclosed(p) = 0;
            %positions stats
            this.positions = this.positions+1;
            if this.trades(p,tcol.value)>0
              this.positionslong(this.positions) = ...
                this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
              this.positionsshort(this.positions) = 0;
            elseif this.trades(p,tcol.value)<0
              this.positionsshort(this.positions) = ...
                this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
              this.positionslong(this.positions) = 0;
            end
            this.positionscontracts(this.positions) = this.contracts(p);
            this.positionsequity(this.positions) = ...
              this.positionslong(this.positions)...
              +this.positionsshort(this.positions);
            this.positionspoints(this.positions) = 0;
            this.positionsreturn(this.positions) = 0;
            this.positionsresult(this.positions) = 0;   
          else
            %integrate postion
            this.contracts(p) = ...
              this.contracts(p-1)+this.trades(p,tcol.value);
            %calculate tradedirection
            if this.contracts(p) == 0 
              %closed position
              this.tradedirection(p)=0;
              %position stats
              if this.trades(p,tcol.value)>0
                this.positionslong(this.positions) = ...
                  this.positionslong(this.positions)+...
                  this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
              elseif this.trades(p,tcol.value)<0
                this.positionsshort(this.positions) = ...
                  this.positionsshort(this.positions)+...
                  this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
              end
              this.positionsresult(this.positions) = ...
                -(this.positionslong(this.positions)+...
                this.positionsshort(this.positions));
              this.positionsreturn(this.positions) = ...
                this.positionsresult(this.positions)/...
                abs(this.positionsequity(this.positions));
              this.positionspoints(this.positions) = ...
                this.positionsresult(this.positions)/...
                (q*abs(this.positionscontracts(this.positions)));
            elseif this.contracts(p) > 0 
              %long position
              %trade direction
              if this.contracts(p-1) >= 0
                %trade direction
                if this.trades(p,tcol.value) > 0
                  %position increased
                  this.tradedirection(p)=1;
                elseif this.trades(p,tcol.value) < 0
                  %position decreased
                  this.tradedirection(p)=0;
                end
                %position stats
                if this.contracts(p-1)==0
                  %new position
                  this.positions = this.positions+1;
                  this.positionscontracts(this.positions) = 0;
                  this.positionsequity(this.positions) = 0;
                  this.positionslong(this.positions) = 0;
                  this.positionsshort(this.positions) = 0;
                end
                if this.trades(p,tcol.value)>0
                  this.positionslong(this.positions) = ...
                    this.positionslong(this.positions)+...
                    this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
                elseif this.trades(p,tcol.value)<0
                  this.positionsshort(this.positions) = ...
                    this.positionsshort(this.positions)+...
                    this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
                end
                this.positionscontracts(this.positions) = ...
                  max(this.positionscontracts(this.positions),...
                  this.contracts(p));
                this.positionsequity(this.positions) = ...
                  max(this.positionsequity(this.positions),...
                  this.positionslong(this.positions)...
                  +this.positionsshort(this.positions));
              else
                %position invertion
                this.tradedirection(p)=-1;
                %position stats
                lastposition = this.contracts(p-1);
                if this.trades(p,tcol.value)>0
                  this.positionslong(this.positions) = ...
                    this.positionslong(this.positions)...
                    -lastposition*this.trades(p,tcol.price)*q;
                elseif this.trades(p,tcol.value)<0
                  this.positionsshort(this.positions) = ...
                    this.positionsshort(this.positions)...
                    -lastposition*this.trades(p,tcol.price)*q;
                end
                this.positionsresult(this.positions) = ...
                  -(this.positionslong(this.positions)+...
                  this.positionsshort(this.positions));
                this.positionsreturn(this.positions) = ...
                  this.positionsresult(this.positions)/...
                  abs(this.positionsequity(this.positions));
                this.positionspoints(this.positions) = ...
                  this.positionsresult(this.positions)/...
                  (q*abs(this.positionscontracts(this.positions)));
                %new position
                this.positions = this.positions+1;
                this.positionscontracts(this.positions) = ...
                  this.trades(p,tcol.value)+lastposition;
                this.positionsequity(this.positions) = ...
                  this.positionscontracts(this.positions)*...
                  q*this.trades(p,tcol.price);
                this.positionslong(this.positions) = 0;
                this.positionsshort(this.positions) = 0;
                if this.positionsequity(this.positions)>0
                  this.positionslong(this.positions)=...
                    this.positionsequity(this.positions);
                elseif this.positionsequity(this.positions)<0
                  this.positionsshort(this.positions)=...
                    this.positionsequity(this.positions);
                end
              end
            elseif this.contracts(p) < 0
              %short position
              if this.contracts(p-1) <= 0 
                %trade direction
                if this.trades(p,tcol.value) < 0
                  %position increased
                  this.tradedirection(p)=1;
                elseif this.trades(p,tcol.value) > 0
                  %position decreased 
                  this.tradedirection(p)=0;
                end
                %position stats
                if this.contracts(p-1)==0
                  %new position
                  this.positions = this.positions+1;
                  this.positionscontracts(this.positions) = 0;
                  this.positionsequity(this.positions) = 0;
                  this.positionslong(this.positions) = 0;
                  this.positionsshort(this.positions) = 0;
                end
                if this.trades(p,tcol.value)>0
                  this.positionslong(this.positions) = ...
                    this.positionslong(this.positions)+...
                    this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
                elseif this.trades(p,tcol.value)<0
                  this.positionsshort(this.positions) = ...
                    this.positionsshort(this.positions)+...
                    this.trades(p,tcol.value)*this.trades(p,tcol.price)*q;
                end
                this.positionscontracts(this.positions) = ...
                  min(this.positionscontracts(this.positions),...
                  this.contracts(p));
                this.positionsequity(this.positions) = ...
                  min(this.positionsequity(this.positions),...
                  this.positionslong(this.positions)...
                  +this.positionsshort(this.positions));
              else
                %position invertion
                this.tradedirection(p)=-1;
                %position stats
                lastposition = this.contracts(p-1);
                if this.trades(p,tcol.value)>0
                  this.positionslong(this.positions) = ...
                    this.positionslong(this.positions)...
                    -lastposition*this.trades(p,tcol.price)*q;
                elseif this.trades(p,tcol.value)<0
                  this.positionsshort(this.positions) = ...
                    this.positionsshort(this.positions)...
                    -lastposition*this.trades(p,tcol.price)*q;
                end
                this.positionsresult(this.positions) = ...
                  -(this.positionslong(this.positions)+...
                  this.positionsshort(this.positions));
                this.positionsreturn(this.positions) = ...
                  this.positionsresult(this.positions)/...
                  abs(this.positionsequity(this.positions));
                this.positionspoints(this.positions) = ...
                  this.positionsresult(this.positions)/...
                  (q*abs(this.positionscontracts(this.positions)));
                %new position
                this.positions = this.positions+1;
                this.positionscontracts(this.positions) = ...
                  this.trades(p,tcol.value)+lastposition;
                this.positionsequity(this.positions) = ...
                  this.positionscontracts(this.positions)*...
                  q*this.trades(p,tcol.price);
                this.positionslong(this.positions) = 0;
                this.positionsshort(this.positions) = 0;
                if this.positionsequity(this.positions)>0
                  this.positionslong(this.positions)=...
                    this.positionsequity(this.positions);
                elseif this.positionsequity(this.positions)<0
                  this.positionsshort(this.positions)=...
                    this.positionsequity(this.positions);
                end
              end
            end
            
            %calculate position result/avgprice
            if this.tradedirection(p)==0
              this.resultclosed(p) = ...
                 this.resultclosed(p-1)+this.trades(p,tcol.value)*q*...
                 (this.avgprice(p-1)-this.trades(p,tcol.price));
              if this.contracts(p) == 0 
                this.avgprice(p) = 0;
              else
                this.avgprice(p) = this.avgprice(p-1);
              end
            elseif this.tradedirection(p)==1
              this.resultclosed(p) = this.resultclosed(p-1);
              this.avgprice(p) =...
               ((this.avgprice(p-1)*this.contracts(p-1))+...
               (this.trades(p,tcol.value)*this.trades(p,tcol.price)))/...
                this.contracts(p);
            elseif this.tradedirection(p)==-1
              this.resultclosed(p) = this.resultclosed(p-1)+...
                     (this.avgprice(p-1)-this.trades(p,tcol.price))*...
                      -this.contracts(p-1)*q;
              this.avgprice(p) = this.trades(p,tcol.price);
            end
          end
          symbol = this.Symbol;
          np = this.npos;
          %update timesample position
          currtime = this.trades(p,tcol.timestamp);
          currdate = fix(currtime);
          gmt = this.Main.gmtvec(this.Main.tradedatevec==currdate);
          %tadj = this.trades(p,tcol.timestamp)-datenum(0,0,0,gmt,0,0);
          tadj = this.trades(p,tcol.timestamp);
          %tadj = this.trades(p,tcol.time);
          tid = ceil(tadj/symbol.Main.quotes.dt);
          if tid>symbol.Main.quotes.timeid(1)
              if p==476
                  disp('cheguei')
              end
            tid = find(symbol.Main.quotes.timeid>=tid,1,'first');
            if isempty(tid)
                tid = max(symbol.Main.quotes.timeid);
            end
            this.trades(p,tcol.id) = tid;
            symbol.positions.contracts(np,tid:end) = this.contracts(p);
            symbol.positions.avgprice(np,tid:end) = this.avgprice(p);
            symbol.positions.resultclosed(np,tid:end)=this.resultclosed(p);
          end
        end
        this.OMS(this.activeOMS).UpdatePositionProfile();
      end
    end
    function CalculateResults(this,init)
      symbol = this.Symbol;
      n=symbol.n;
      np = this.npos;
      q = this.Symbol.tickvalue/this.Symbol.ticksize;
      pcol = this.IO.cols;
      quotes = this.Main.quotes;
      if init
        InitResults(this);
      end
      fb = quotes.firstbar(end);
      ob = quotes.openbar(n,end);
      lb = quotes.lastbar(n,end);
      lid = symbol.positions.lastbar(np);
      if lid==fb
        tvec = lid:lb;
      else
        tvec = lid+1:lb;
      end
      for t=tvec
        symbol.positions.resultcurrent(np,t)=...
          (symbol.positions.contracts(np,t)*q*...
            (quotes.close(n,t)-symbol.positions.avgprice(np,t)))...
            +symbol.positions.resultclosed(np,t);
        closep = quotes.close(n,fb-1);
        maxcts = this.alocation(pcol.value)/closep/q;
        maxcts = round(maxcts/symbol.lotmin)*symbol.lotmin;
        maxeq = maxcts*q*closep;
        symbol.positions.alocation(np,t) = maxeq;
        symbol.positions.delta(np,t) = ...
            symbol.positions.contracts(np,t)./maxcts;    
          
        symbol.positions.equity(np,t) = ...
              symbol.positions.alocation(np,t)+...
              symbol.positions.resultcurrent(np,t)-...
              symbol.positions.resultcurrent(np,fb);
        if t>fb
          symbol.positions.rlog(np,t)=...
            log(symbol.positions.equity(np,t)/...
                symbol.positions.equity(np,t-1));
        end
        symbol.positions.rlogaccum(np,t)=...
            symbol.positions.rlogaccum(np,t-1)+...
            symbol.positions.rlog(np,t);
        if this.nsignal>0 && any(symbol.positions.rlog(np,fb:lb))
          if size(symbol.signals(this.nsignal).rlog,2)>=t
            symbol.positions.rlogaccumadj(np,t)=...
             symbol.positions.rlogaccumadj(np,t-1)...
             +symbol.signals(this.nsignal).rlog(t);
           symbol.positions.slippage(np,t) = ...
            (symbol.positions.rlogaccum(np,t)...
            -symbol.positions.rlogaccumadj(np,t));
          end
        end
        
        symbol.positions.lastbar(np)=lb;
      end
    end
    function Updatereqpositionprofile(this)
      tcol = this.OMS(this.activeOMS).OMSTrades.cols;
      rcol = this.IO.cols;
      tag = this.IO.tags;
      tagid = this.IO.tagid;
      q = this.Symbol.tickvalue/this.Symbol.ticksize; 
      this.activeidx = this.reqorders(:,rcol.value) ~= 0 &...
        this.reqorders(:,rcol.price) > 0;
      nactive = sum(this.activeidx);
      if nactive > 0
        this.reqpositionprofile = zeros(1,this.PROFILESIZE);
        this.reqresultprofile = zeros(1,this.PROFILESIZE);
        this.reqordersprofile = this.reqorders(this.activeidx,:);
        this.reqordersprofile(:,rcol.value) = 0;
        activeids = find(this.activeidx);
        for p=1:nactive
          currorder = this.reqorders(activeids(p),:);
          currpx = round(currorder(rcol.price)/this.Symbol.ticksize);
          if currpx~=0
          if currorder(rcol.tag) == tagid(tag.reqlimit)
            %limit order
            if currorder(rcol.value) > 0
              %long limit
              this.reqpositionprofile(1:currpx) =...
                this.reqpositionprofile(1:currpx)+...
                  currorder(rcol.value);
              this.reqresultprofile(1:currpx) =...
                this.reqresultprofile(1:currpx)+...
                ([1:currpx].*this.Symbol.ticksize-currorder(rcol.price)).*...
                currorder(rcol.value)*q;
              priceidx = ...
                this.reqordersprofile(:,rcol.price) <= currorder(rcol.price);
              if any(priceidx)
                this.reqordersprofile(priceidx,rcol.value) =...
                  this.reqordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            elseif currorder(rcol.value) < 0
              %short limit
              this.reqpositionprofile(currpx:end) =...
                this.reqpositionprofile(currpx:end) + ...
                  currorder(rcol.value);
              this.reqresultprofile(currpx:end) =...
                this.reqresultprofile(currpx:end)+...
                ([currpx:this.PROFILESIZE].*this.Symbol.ticksize - currorder(rcol.price)).*...
                currorder(rcol.value)*q;
              priceidx = ...
                this.reqordersprofile(:,rcol.price) >= currorder(rcol.price);
              if any(priceidx)
                this.reqordersprofile(priceidx,rcol.value) =...
                  this.reqordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            end
          elseif currorder(rcol.tag) == tagid(tag.reqstop)
            %stop order
            if currorder(rcol.value) > 0
             %long stop
              this.reqpositionprofile(currpx:end) =...
                this.reqpositionprofile(currpx:end) + ...
                  currorder(rcol.value);
              this.reqresultprofile(currpx:end) =...
                this.reqresultprofile(currpx:end)+...
                ([currpx:this.PROFILESIZE].*this.Symbol.ticksize ...
              - currorder(rcol.price)).*currorder(rcol.value)*q;
              priceidx = ...
                this.reqordersprofile(:,rcol.price) >= currorder(rcol.price);
              if any(priceidx)
                this.reqordersprofile(priceidx,rcol.value) =...
                  this.reqordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            elseif currorder(rcol.value) < 0
              %short stop
              this.reqpositionprofile(1:currpx) =...
                this.reqpositionprofile(1:currpx) + ...
                  currorder(rcol.value);
               this.reqresultprofile(1:currpx) =...
                this.reqresultprofile(1:currpx)+...
                ([1:currpx].*this.Symbol.ticksize ...
                - currorder(rcol.price)).*currorder(rcol.value)*q;
              priceidx = ...
                this.reqordersprofile(:,rcol.price) <= currorder(rcol.price);
              if any(priceidx)
                this.reqordersprofile(priceidx,rcol.value) =...
                  this.reqordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            end
          end
          end
        end
        if this.ntrades>0
          this.reqpositionprofile = this.reqpositionprofile +...
            this.contracts(this.ntrades);
          this.reqresultprofile = this.reqresultprofile +...
            this.resultclosed(this.ntrades);
          if this.contracts(this.ntrades)~=0
            this.reqresultprofile = this.reqresultprofile + ...
              ([1:this.PROFILESIZE].*this.Symbol.ticksize - ...
              this.avgprice(this.ntrades)).*...
              this.contracts(this.ntrades)*q;
          end
          this.reqordersprofile(:,rcol.value) =...
            this.reqordersprofile(:,rcol.value)+...
            this.contracts(this.ntrades);
        end
        if this.reqtrade(rcol.value)~=0
          this.reqpositionprofile = this.reqpositionprofile +...
                                    this.reqtrade(rcol.value);
          this.reqresultprofile = this.reqresultprofile + ...
            ([1:this.PROFILESIZE].*this.Symbol.ticksize...
            -this.reqtrade(rcol.price)).*this.reqtrade(rcol.value)*q;
          this.reqordersprofile(:,rcol.value) =...
            this.reqordersprofile(:,rcol.value)+...
            this.reqtrade(rcol.value);
        end
      else
        this.reqpositionprofile = zeros(1,this.PROFILESIZE);
        this.reqresultprofile = zeros(1,this.PROFILESIZE);
        if this.ntrades>0
          this.reqpositionprofile = this.reqpositionprofile +...
            this.contracts(this.ntrades);
          this.reqresultprofile = this.reqresultprofile +...
            this.resultclosed(this.ntrades);
          if this.contracts(this.ntrades)~=0
            this.reqresultprofile = this.reqresultprofile + ...
              ([1:this.PROFILESIZE].*this.Symbol.ticksize - ...
              this.avgprice(this.ntrades)).*...
              this.contracts(this.ntrades)*q;
          end
        end
        if this.reqtrade(rcol.value)~=0
          this.reqpositionprofile = this.reqpositionprofile +...
                                    this.reqtrade(rcol.value);
          this.reqresultprofile = this.reqresultprofile + ...
            ([1:this.PROFILESIZE].*this.Symbol.ticksize...
            -this.reqtrade(rcol.price)).*this.reqtrade(rcol.value)*q;
        end
      end
    end
    function ApplyPosition(this)
      oms = this.OMS(this.activeOMS);
      if ~isempty(oms.OMSReports) && ~isempty(oms.OMSRequests)
        rcol = oms.OMSReports.cols;
        tag = this.IO.tags;
        tagid = this.IO.tagid;
        pcol = this.IO.cols;
        this.status(pcol.value) = ...
          oms.UpdateStatus(this.autotrade(pcol.value));
        if this.status(pcol.value)~=this.OMS_STATUS_REQPENDING && ...
              this.status(pcol.value)~=this.OMS_STATUS_REPORTPENDING && ...
              this.status(pcol.value)~=this.OMS_STATUS_DELAY &&...
              this.status(pcol.value)~=this.OMS_STATUS_CANCELLING
          %Cancel Pending Orders
          pendingorders = oms.orders(oms.activeidx,:);
          pendingordersid = find(oms.activeidx);
          npending = size(pendingorders,1);
          for o=1:npending
            currorder = pendingorders(o,:);
            currorderid = pendingordersid(o);
            if ~isempty(this.reqorders)
              priceidx =[];
              ordtypeidx =[];
              if oms.limitidx(currorderid)
                %LIMIT orders
                priceidx = ...
                  this.reqorders(:,pcol.price)==currorder(rcol.price) & ...
                  this.reqorders(:,pcol.value).*currorder(rcol.value)>0;
                ordtypeidx = ...
                  this.reqorders(:,pcol.tag)==tagid(tag.reqlimit);
              elseif oms.stopidx(currorderid)
                %STOP orders
                if ~oms.stoptriggeridx(currorderid)
                  %STOP pending
                  priceidx = ...
                    this.reqorders(:,pcol.price)==currorder(rcol.price) & ...
                    this.reqorders(:,pcol.value).*currorder(rcol.value)>0;
                  ordtypeidx=...
                    this.reqorders(:,pcol.tag)==tagid(tag.reqstop);
                else
                  %STOP triggered
                  spread = this.Symbol.ticksize;
                  if currorder(rcol.value)<0
                    spread = -spread;
                  end
                  priceidx = ...
                    (this.reqorders(:,pcol.price)==...
                                                currorder(rcol.price)|...
                    this.reqorders(:,pcol.price)+spread==...
                                                currorder(rcol.price)) & ...
                    this.reqorders(:,pcol.value).*currorder(rcol.value)>0;
                  ordtypeidx=...
                    this.reqorders(:,pcol.tag)==tagid(tag.reqstop);
                end
              end
              if ~any(priceidx & ordtypeidx)
                px = currorder(rcol.price);
                qty = currorder(rcol.value);
                orderid = currorder(rcol.orderid);
                oms.CancelOrder(orderid,px,qty);
              elseif any(priceidx)
                if this.reqorders(priceidx,pcol.value) == 0
                  px = currorder(rcol.price);
                  qty = currorder(rcol.value);
                  orderid = currorder(rcol.orderid);
                  oms.CancelOrder(orderid,px,qty);
                end
              end
            else
              px = currorder(rcol.price);
              qty = currorder(rcol.value);
              orderid = currorder(rcol.orderid);
              oms.CancelOrder(orderid,px,qty);
            end
          end
          %Add / Replace orders
          this.status(pcol.value) = ...
              oms.UpdateStatus(this.autotrade(pcol.value));
          reqordersid = find(this.reqorders(:,pcol.value));
          if ~isempty(reqordersid)
            for o =1:length(reqordersid)
              currorderid = reqordersid(o);
              currorder = this.reqorders(currorderid,:);
              if currorder(pcol.value)~=0
                pendidx=pendingorders(:,rcol.price)==currorder(pcol.price);
                if ~any(pendidx)
                  if this.status(pcol.value)~=this.OMS_STATUS_CANCELLING
                    if currorder(pcol.tag) == tagid(tag.reqlimit) ...
                        && currorder(pcol.value)~=0
                      oms.NewLimitOrder(currorder(pcol.price),...
                                        currorder(pcol.value));
                    elseif currorder(pcol.tag) == tagid(tag.reqstop)...
                        && currorder(pcol.value)~=0
                      oms.NewStopOrder(currorder(pcol.price),...
                                        currorder(pcol.value));
                    end
                  end
                else
                  pendid = find(pendidx,1);
                  porder = pendingorders(pendid,:);
                  if  porder(rcol.value)*currorder(pcol.value)>0 &&...
                      porder(rcol.value)~=currorder(pcol.value)
                    px = currorder(pcol.price);
                    qty = currorder(pcol.value);
                    orderid = porder(rcol.orderid);
                    oms.CancelReplaceOrder(orderid,px,qty);
                  end
                end
              end
            end
          end
          %IOC reqtrade execution
          if this.reqtrade(pcol.value)~=0
            oms.NewIOCOrder(this.reqtrade(pcol.price),...
                              this.reqtrade(pcol.value));
            this.reqtrade(pcol.value) = 0;
          end
        end
      end
    end
    
  end
end