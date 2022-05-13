classdef MarketMain < handle
    %MAIN Class that holds all subclasses
    % tradedb.cljnyverb6gc.sa-east-1.rds.amazonaws.com
    properties(SetAccess=private,GetAccess=public)
      %% INPUTS
      hObject
      handles
      Instance
      fields
      sim_stop
      sim_pause
      backtest
      sim
      charting
      startdate
      enddate
      timesample
      db
      marketdata
    end
    
    properties
      %% Classes
      Symbols
      Accounts
      Strategies
      Positions
      OMS
      %% IO
      Inputs
      Outputs
      %% CONFIGURATION
      ninit
      init
      initfile
      firstread = true
      %% TIME VARS
      history
      GMT
      time = 0
      dt
      simdates
      tradedatevec
      gmtvec
      tradedate
      sim_time
      sim_timeid
      sim_time_vec
      sim_last_timeid
      tinitsim
      tinitdate
      dottime
      plottime
      throughput_vec
      %% MARKET DATA
      quotes
      %% FIGURES
      nfigs = 0
      initcharts=true
    end
    
    methods
    %% CONSTRUCTOR
      function this = MarketMain(hObject,handles)
        %Load GUI variables
        InitializeGUI(this,hObject,handles);
        %Create Market instance
        this.init = xml2struct(this.initfile);
        this.Instance = this.init.matlab;  
        fprintf('Initializing market %s version %s...\n',...
          this.Instance.Attributes.instance,...
          this.Instance.Attributes.version);
        %load variables
        this.history = str2double(this.Instance.Attributes.history);
        this.throughput_vec = circVBuf(int64(100),int64(2));
        %load databases
        for d = 1:length(this.Instance.db)
          schema = this.Instance.db{d}.Attributes.schema;
          this.db.(schema) = this.Instance.db{d}.Attributes;
        end
        %initialize marketdata
        h = mysql( 'open', this.db.dbconfig.host, ...
          this.db.dbconfig.user, this.db.dbconfig.password );
        %generate folder path based on DB sequence
        query = sprintf(['SELECT marketdata FROM %s.marketdata ',...
                          'order by priority desc; '],...
                          this.db.dbconfig.schema);
        [ this.marketdata ] = mysql(query);
        mysql('close') 
        
        %load tradedates
        %initialize tradedatevec
        h = mysql( 'open', this.db.dbconfig.host, ...
          this.db.dbconfig.user, this.db.dbconfig.password );
        query = sprintf(['SELECT tradedate,gmt FROM %s.tradedate order by tradedate;'],...
                          this.db.dbconfig.schema);
        [ this.tradedatevec,this.gmtvec ] = mysql(query);
        mysql('close') 
        if (this.sim || this.backtest)
          simdateidx = this.tradedatevec>=this.startdate &...
                        this.tradedatevec<=this.enddate;
          if ~isempty(simdateidx)
            this.simdates = this.tradedatevec(simdateidx);
          else            
            this.simdates = [];
          end
        else
          %rt date 
          simdateidx = this.tradedatevec==this.startdate;
          if ~isempty(simdateidx)
            this.simdates = this.tradedatevec(simdateidx);
          else            
            this.simdates = [];
          end
        end
        %Initialize Classes
        this.InitializeClasses();
      end
      function InitializeGUI(this,hObject,handles)
        this.hObject = hObject;
        this.handles = handles;
        handles.sim_stop = false;
        this.sim_stop = handles.sim_stop;
        this.sim_pause = handles.sim_pause;
        this.backtest = handles.radiobuttonBT.Value;
        this.sim = handles.radiobuttonSIM.Value;
        this.charting = handles.chartsONLY.Value;
        this.startdate = datenum(handles.startdate.String);
        this.enddate = datenum(handles.enddate.String);
        this.timesample = str2double(handles.dt.String);
        this.dt = str2double(handles.dt.String);
        this.ninit = handles.popupmenu_init.Value;
        this.initfile = handles.popupmenu_init.String{this.ninit};
      end
      function InitializeClasses(this)
        this.Inputs = FileIO.empty;
        this.Outputs = FileIO.empty;
        
        this.Symbols = ExchangeSymbols.empty;
        this.fields = fieldnames(this.Instance);
        %INITIALIZE SYMBOLS
        for f = 1:length(this.fields)
          if strcmp('marketdata',this.fields(f))
            init_symbols_count = size(this.Instance.marketdata.symbols,2);
            for s=1:init_symbols_count
              symbol = this.Instance.marketdata.symbols(s);
              if iscell(symbol)
                  symbol = cell2mat(symbol);
              end
              symbol.Attributes.table = 'mdquotes';
              symbol.Attributes.source = 'RT';
              symbol.Attributes.IO = 'input';
              symbol.Attributes.period=...
                this.Instance.marketdata.Attributes.period;
              symbol.Attributes.marketdata=...
                this.Instance.marketdata.Attributes.marketdata;
              symbol.Attributes.db=this.Instance.marketdata.Attributes.db;
              this.AddSymbol(ExchangeSymbols(this,symbol,s));
            end
          end
        end
      end
      function oSymbol = AddSymbol(this,iSymbol)
        if isempty(this.Symbols)
          this.Symbols(1) = iSymbol;
          oSymbol = iSymbol;
        else
          symbol_count = length(this.Symbols);
          symbol_found = false;
          for s=1:symbol_count
            if iSymbol.isserie
              if strcmp(this.Symbols(s).serie,iSymbol.serie) && ...
                strcmp(this.Symbols(s).symbol,iSymbol.name)
                symbol_found = true;
                oSymbol = this.Symbols(s);
              end
            else
              if strcmp(this.Symbols(s).symbol,iSymbol.symbol)
                symbol_found = true;
                oSymbol = this.Symbols(s);
                break;
              end
            end
          end
          if ~symbol_found
            this.Symbols(symbol_count+1) = iSymbol;
            oSymbol = iSymbol;
          end
        end
      end
      function AddInputs(this,Inputs)
        input_count = 0;
        if ~isempty(this.Inputs)
          input_count = length(this.Inputs);
        end
        new_inputs = length(Inputs);
        for i=1:new_inputs
          if ~isempty(Inputs)
            this.Inputs(input_count+i) = Inputs(i);
          end
        end
      end
      function AddOutputs(this,iOutputs)
        output_count = 0;
        if ~isempty(this.Outputs)
          output_count = length(this.Outputs);
        end
        new_outputs = length(iOutputs);
        for i=1:new_outputs
          if ~isempty(iOutputs(i))
            this.Outputs(output_count+i) = iOutputs(i);
          end
        end
      end
      
    %% MARKETDATA HISTORY INITIALIZATION  
      function InitHistory(this,tradedate)
        fprintf('\n->Initializing history...\n');
        tinitht = tic;
        StartSymbols(this,tradedate);
        InitTradesHistory(this,tradedate);
        InitBarsHistory(this,tradedate,this.history);
        InitMDSymbols(this);
        InitMDDeltas(this);
        fprintf('\n->History initialized!(%2.4fs)\n',toc(tinitht));
      end
      function InitTradesHistory(this,tradedate)
        fprintf('\n->Loading trade history...\n');
        for s=1:length(this.Symbols)
          this.Symbols(s).InitMDTradesHistory(tradedate);
        end
      end
      function InitBarsHistory(this,tradedate,nhistory)
        this.dottime=tic;
        %Select first date id in tradedate vector
        currdateid = find(this.tradedatevec==tradedate,1,'first');
        if currdateid-this.history>=1
          firstdateid = currdateid-nhistory;
        else
          firstdateid = 1;
        end
        firstdate = this.tradedatevec(firstdateid);
        %allocate quotes memory
        n = length(this.Symbols);
        %create quotes headers
        this.quotes.dt = datenum(0,0,0,0,0,this.dt);
        this.quotes.tradedates=[];
        this.quotes.firstbar=[];
        this.quotes.openbar=[];
        this.quotes.lastbar=[];
        this.quotes.maxbar=[];
        this.quotes.minbar=[];
        %create linear time vector
        this.quotes.time=firstdate:this.quotes.dt:tradedate-this.quotes.dt;
        this.quotes.timeid = round(this.quotes.time./this.quotes.dt);
        %create quotes values
        this.quotes.open(n,:) = zeros(size(this.quotes.time));
        this.quotes.close(n,:) = zeros(size(this.quotes.time));
        this.quotes.max(n,:) = zeros(size(this.quotes.time));
        this.quotes.min(n,:) = zeros(size(this.quotes.time));
        this.quotes.volume(n,:) = zeros(size(this.quotes.time));
        this.quotes.buyvolume(n,:) = zeros(size(this.quotes.time));
        this.quotes.sellvolume(n,:) = zeros(size(this.quotes.time));
        this.quotes.bestbid(n,:) = zeros(size(this.quotes.time));
        this.quotes.bidqty(n,:) = zeros(size(this.quotes.time));
        this.quotes.bestask(n,:) = zeros(size(this.quotes.time));
        this.quotes.askqty(n,:) = zeros(size(this.quotes.time));
        %quotes indexes
        ftimeid = this.quotes.timeid(1);
        nzidx = zeros(size(this.quotes.time));
        %read quotes history
        for s=1:length(this.Symbols)
          currIO = this.Symbols(s).MDQuotes(1);
          if ~isempty(currIO)
            fprintf('\n->reading MDQuotes %s...\n',this.Symbols(s).name);
            thist =tic;
            currIO.keys.history = nhistory;
            currIO.InitHistory(tradedate);
            thist = toc(thist);
            fprintf('(%2.4f)',thist);
            n = this.Symbols(s).n;
            if ~isempty(currIO.buffer)
              cols = currIO.cols;
              timeid=round(currIO.buffer(:,cols.time)./this.quotes.dt)...
                -ftimeid+1;
              this.quotes.open(n,timeid)=currIO.buffer(:,cols.open);
              this.quotes.close(n,timeid)=currIO.buffer(:,cols.close);
              this.quotes.max(n,timeid)=currIO.buffer(:,cols.max);
              this.quotes.min(n,timeid)=currIO.buffer(:,cols.min);
              this.quotes.volume(n,timeid)=currIO.buffer(:,cols.volume);
              this.quotes.buyvolume(n,timeid)=currIO.buffer(:,cols.buyvolume);
              this.quotes.sellvolume(n,timeid)=currIO.buffer(:,cols.sellvolume);
              this.quotes.bestbid(n,timeid)=currIO.buffer(:,cols.bestbid);
              this.quotes.bidqty(n,timeid)=currIO.buffer(:,cols.bidqty);
              this.quotes.bestask(n,timeid)=currIO.buffer(:,cols.bestask);
              this.quotes.askqty(n,timeid)=currIO.buffer(:,cols.askqty);
              nzidx = nzidx | this.quotes.volume(s,:)~=0;
              currIO.buffer=[];
            end
          end
        end
        %Delete begining/end of day && tradedates with no trades
        fprintf('\n->Parsing MDQuotes...\n');
        thist =tic;
        tradedates = unique(fix(this.quotes.time));
        deleteidx = false(size(this.quotes.time));
        for t=1:length(tradedates)
          if toc(this.dottime)>1
            fprintf('.');
            this.dottime = tic;
          end
          currdate = tradedates(t);
          currdateidx = fix(this.quotes.time) == currdate;
          tradeidx = currdateidx & nzidx;
          if ~any(tradeidx)
            deleteidx = deleteidx | currdateidx;
          else
            firstbar = find(tradeidx,1,'first');
            lastbar = find(tradeidx,1,'last');
            tradeidx(firstbar:lastbar) = true;
            delidx = ~tradeidx & currdateidx;
            deleteidx = deleteidx | delidx;
          end
        end
        this.quotes.time(:,deleteidx)=[];
        this.quotes.timeid(:,deleteidx)=[];
        this.quotes.open(:,deleteidx)=[];
        this.quotes.close(:,deleteidx)=[];
        this.quotes.max(:,deleteidx)=[];
        this.quotes.min(:,deleteidx)=[];
        this.quotes.volume(:,deleteidx)=[];
        this.quotes.buyvolume(:,deleteidx)=[];
        this.quotes.sellvolume(:,deleteidx)=[];
        this.quotes.bestbid(:,deleteidx)=[];
        this.quotes.bidqty(:,deleteidx)=[];
        this.quotes.bestask(:,deleteidx)=[];
        this.quotes.askqty(:,deleteidx)=[];
        thist = toc(thist);
        fprintf('(%2.4f)',thist);
        fprintf('\n->Adjusting MDQuotes...\n');
        thist =tic;
        %Get firstbar openbar and lastbars
        tradedates = unique(fix(this.quotes.time));
        for t=1:length(tradedates)
          currdate = tradedates(t);
          if toc(this.dottime)>1
            fprintf('.');
            this.dottime = tic;
          end
          currdateidx = fix(this.quotes.time) == currdate;
          firstbar = find(currdateidx,1,'first');
          lastbar = find(currdateidx,1,'last');
          ns=length(this.Symbols);
          if isempty(this.quotes.tradedates)
            this.quotes.tradedates(1) = currdate;
            this.quotes.firstbar(1) = firstbar;
            this.quotes.lastbar(1:ns,1) = lastbar;
            for s=1:ns
              openbar = ...
                find(this.quotes.volume(s,:)~=0 & currdateidx,1,'first');
              if ~isempty(openbar)
                this.quotes.openbar(s,1) = openbar;
              else
                this.quotes.openbar(s,1) = 0;
              end
              maxp = max(this.quotes.max(s,currdateidx));
              maxbar=...
                find(this.quotes.max(s,:)==maxp & currdateidx,1,'first');
              if ~isempty(maxbar)
                this.quotes.maxbar(s,1) = maxbar;
              else
                this.quotes.maxbar(s,1) = 0;
              end
              minnzidx = this.quotes.min(s,:) ~= 0;
              minp = min(this.quotes.min(s,currdateidx & minnzidx));
              if ~isempty(minp)
              minbar=...
                find(this.quotes.min(s,:)==minp & currdateidx,1,'first');
                if ~isempty(minbar)
                  this.quotes.minbar(s,1) = minbar;
                else
                  this.quotes.minbar(s,1) = 0;
                end
              end
            end
          else
            this.quotes.tradedates(end+1) = currdate;
            this.quotes.firstbar(end+1) = firstbar;
            this.quotes.lastbar(1:ns,end+1)=lastbar;
            this.quotes.openbar(1:ns,end+1)=zeros(length(this.Symbols),1);
            this.quotes.maxbar(1:ns,end+1)=zeros(length(this.Symbols),1);
            this.quotes.minbar(1:ns,end+1)=zeros(length(this.Symbols),1);
            for s=1:ns
              openbar=...
                find(this.quotes.volume(s,:)~=0 & currdateidx,1,'first');
              if ~isempty(openbar)
                this.quotes.openbar(s,end) = openbar;
              else
                this.quotes.openbar(s,end) = 0;
              end
              maxp = max(this.quotes.max(s,currdateidx));
              maxbar=...
                find(this.quotes.max(s,:)==maxp & currdateidx,1,'first');
              if ~isempty(maxbar)
                this.quotes.maxbar(s,end) = maxbar;
              else
                this.quotes.maxbar(s,end) = 0;
              end
              minnzidx = this.quotes.min(s,:) ~= 0;
              minp = min(this.quotes.min(s,currdateidx & minnzidx));
              if ~isempty(minp)
                minbar=...
                  find(this.quotes.min(s,:)==minp & currdateidx,1,'first');
                if ~isempty(minbar)
                  this.quotes.minbar(s,end) = minbar;
                else
                  this.quotes.minbar(s,end) = 0;
                end
              end
            end
          end
        end
        thist = toc(thist);
        fprintf('(%2.4f)',thist);
        fprintf('\n->Calculating returns of MDQuotes...\n');
        thist =tic;
        for s=1:length(this.Symbols)
          n=this.Symbols(s).n;
          %propagate prices where theres zeros
          fnzid = find(this.quotes.volume(n,:),1,'first');
          if fnzid>1
            this.quotes.open(n,1:fnzid) = this.quotes.open(n,fnzid);
            this.quotes.close(n,1:fnzid) = this.quotes.close(n,fnzid);
            this.quotes.max(n,1:fnzid) = this.quotes.close(n,fnzid);
            this.quotes.min(n,1:fnzid) = this.quotes.close(n,fnzid);
          end
          zeroidx = this.quotes.close(n,:) == 0;
          if ~all(zeroidx)
            while any(zeroidx) 
              if toc(this.dottime)>1
                fprintf('.');
                this.dottime = tic;
              end
              shiftidx = [zeroidx(2:end),false];
              this.quotes.close(n,zeroidx) = this.quotes.close(n,shiftidx);
              zeroidx = this.quotes.close(n,:) == 0;
            end
          end
          zeroidx = this.quotes.open(n,:) == 0;
          this.quotes.open(n,zeroidx) = this.quotes.close(n,zeroidx);
          zeroidx = this.quotes.max(n,:) == 0;
          this.quotes.max(n,zeroidx) = this.quotes.close(n,zeroidx);
          zeroidx = this.quotes.min(n,:) == 0;
          this.quotes.min(n,zeroidx) = this.quotes.close(n,zeroidx);
          %calculate log returns
          this.quotes.rlog(n,:) = ...
            [0,log(this.quotes.close(n,2:end)./...
            this.quotes.close(n,1:end-1))];
          this.quotes.rlogintraday(n,:) = zeros(size(this.quotes.time));
          this.quotes.rlogdaily(n,:) = zeros(size(this.quotes.time));
          for t=1:length(this.quotes.tradedates)
            currdate = this.quotes.tradedates(t);
            if this.Symbols(s).isserie
              %remove roll return
              currdateidx = currdate == this.Symbols(s).seriedates;
              if any(currdateidx)
                if this.Symbols(s).serieroll(currdateidx)
                  ob = this.quotes.openbar(n,t);
                  if ob>0
                    this.quotes.rlog(n,ob) = 0;
                  end
                end
              end
            end
            %calculate intraday returns
            ob = this.quotes.openbar(n,t);
            if ob==0
              ob=1;
            end
            lb = this.quotes.lastbar(n,t);
            this.quotes.rlogintraday(n,ob+1:lb)=...
              cumsum(this.quotes.rlog(n,ob+1:lb));
            this.quotes.rlogdaily(n,ob:lb)=...
              cumsum(this.quotes.rlog(n,ob:lb));
          end
          this.quotes.rlogaccum(n,:) = cumsum(this.quotes.rlog(n,:));
        end
        thist = toc(thist);
        fprintf('(%2.4f)',thist);
      end
      function InitMDSymbols(this)
        fprintf('\n->Loading symbols history...\n');
        %init mdsymbols
        for f = 1:length(this.fields)
          if strcmp('marketdata',this.fields(f))
            mdfields = fieldnames(this.Instance.marketdata);
            for mdf = 1:length(mdfields)
              if strcmp('mdsymbols',mdfields(mdf))
                mdsymbols = this.Instance.marketdata.mdsymbols;
                
                markets = '';
                for m=1:length(mdsymbols.market)
                  markets = strcat(markets,'''');
                  markets = strcat(markets,...
                    mdsymbols.market{m}.Attributes.market);
                  markets = strcat(markets,''',');
                end
                markets=markets(1:end-1);
                
                h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user, this.db.dbconfig.password );
                query = sprintf(['SELECT COLUMN_NAME ',...
                                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                                  'AND TABLE_NAME = ''%s'';'],...
                                  'dbmarket',...
                                  'mdsymbols');
                [ sfields ] = mysql(query);
                mysql('close') 
                
                str_query = '';
                %create dictionary
                for fd=1:length(sfields)
                  column = strsplit(cell2mat(sfields(fd)),'_');
                  if size(column,2)>1
                      str_query = strcat(str_query,sfields{fd});
                      str_query = strcat(str_query,',');
                  end
                end
                str_query = str_query(1:end-1);
                %{
                startd = datenum(mdsymbols.Attributes.start,'yyyy-mm-dd');
                tdatesidx = this.tradedatevec >=startd &...
                  this.tradedatevec <= this.enddate;
                tdatesids = find(tdatesidx);
                %}
                for t=1:length(this.quotes.tradedates)
                  currdate = this.quotes.tradedates(t);
                  query = sprintf(['SELECT %s FROM dbmarket.mdsymbols '...
                  'WHERE s_exchange=''XBMF'''...
                  'AND s_market in (%s) '...
                  'AND s_tradedate=''%s'';'],...
                  str_query,markets,datestr(currdate,'yyyy-mm-dd'));
                  h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user, this.db.dbconfig.password );
                  [this.quotes.daily(t).s_source,this.quotes.daily(t).s_tradedate,this.quotes.daily(t).s_exchange,...
                    this.quotes.daily(t).s_symbol,this.quotes.daily(t).s_market,this.quotes.daily(t).s_contract,...
                    this.quotes.daily(t).s_contractType,this.quotes.daily(t).s_optionType,this.quotes.daily(t).s_m2mType,this.quotes.daily(t).s_lastM2mType,...
                    this.quotes.daily(t).s_symbolVoice,this.quotes.daily(t).s_channels,this.quotes.daily(t).t_strikedate,...
                    this.quotes.daily(t).t_lasttrade,this.quotes.daily(t).t_liquidation,this.quotes.daily(t).t_deliveryDate,...
                    this.quotes.daily(t).t_time,this.quotes.daily(t).d_open,this.quotes.daily(t).d_max,this.quotes.daily(t).d_min,...
                    this.quotes.daily(t).d_close,this.quotes.daily(t).d_closeQty,this.quotes.daily(t).d_lastClose,...
                    this.quotes.daily(t).d_last,this.quotes.daily(t).d_avg,this.quotes.daily(t).d_bestBid,this.quotes.daily(t).d_bidQty,...
                    this.quotes.daily(t).d_bestAsk,this.quotes.daily(t).d_askQty,this.quotes.daily(t).d_trades,...
                    this.quotes.daily(t).d_contracts,this.quotes.daily(t).d_openInterest,this.quotes.daily(t).d_volumeBRL,...
                    this.quotes.daily(t).d_volumeUSD,this.quotes.daily(t).d_pointvalue,this.quotes.daily(t).d_m2m,...
                    this.quotes.daily(t).d_lastM2m,this.quotes.daily(t).d_m2mReturn,this.quotes.daily(t).d_m2mValue,...
                    this.quotes.daily(t).d_dM2m,this.quotes.daily(t).d_dM2mValue,this.quotes.daily(t).d_strikeprice,...
                    this.quotes.daily(t).d_exercBRL,this.quotes.daily(t).d_exercUSD,this.quotes.daily(t).d_exercTrades,...
                    this.quotes.daily(t).d_exercContracts,this.quotes.daily(t).d_delta,this.quotes.daily(t).d_yieldDays,...
                    this.quotes.daily(t).d_totalDays,this.quotes.daily(t).d_busDays,this.quotes.daily(t).d_margin,...
                    this.quotes.daily(t).d_marginMM,this.quotes.daily(t).d_futSeq,this.quotes.daily(t).d_lowerLimit,...
                    this.quotes.daily(t).d_upperLimit] = mysql(query);
                  mysql('close')
                end
              end
            end
          end
        end
      end
      function InitMDDeltas(this,tradedate)
        fprintf('\n->Loading deltas history...\n');
        %init mddeltas
        for f = 1:length(this.fields)
          if strcmp('marketdata',this.fields(f))
            mdfields = fieldnames(this.Instance.marketdata);
            for mdf = 1:length(mdfields)
              if strcmp('mddeltas',mdfields(mdf))
                mddeltas = this.Instance.marketdata.mddeltas;
                markets = '';
                if length(mddeltas.market)>1
                  for m=1:length(mddeltas.market)
                    markets = strcat(markets,'''');
                    markets = strcat(markets,...
                      mddeltas.market{m}.Attributes.market);
                    markets = strcat(markets,''',');
                  end
                  markets=markets(1:end-1);
                else
                  markets = strcat(markets,'''');
                  markets = strcat(markets,...
                    mddeltas.market.Attributes.market);
                  markets = strcat(markets,'''');
                end
                h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user, this.db.dbconfig.password );
                query = sprintf(['SELECT COLUMN_NAME ',...
                                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                                  'AND TABLE_NAME = ''%s'';'],...
                                  'dbmarket',...
                                  'mddeltas');
                [ sfields ] = mysql(query);
                mysql('close') 
                str_query = '';
                %create dictionary
                for fd=1:length(sfields)
                  column = strsplit(cell2mat(sfields(fd)),'_');
                  if size(column,2)>1
                      str_query = strcat(str_query,sfields{fd});
                      str_query = strcat(str_query,',');
                  end
                end
                str_query = str_query(1:end-1);
                for t=1:length(this.quotes.tradedates)
                  currdate = this.quotes.tradedates(t);
                  if toc(this.dottime)>1
                    fprintf('.');
                    this.dottime = tic;
                  end
                  query = sprintf(['SELECT %s FROM dbmarket.mddeltas '...
                  'WHERE s_source=''RT'' '...
                  'AND s_exchange=''XBMF'' '...
                  'AND s_market in (%s) '...
                  'AND s_tradedate=''%s'';'],...
                  str_query,markets,datestr(currdate,'yyyy-mm-dd'));
                  h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user, this.db.dbconfig.password );
                  [this.quotes.deltas(t).s_source,this.quotes.deltas(t).s_tradedate,...
                    this.quotes.deltas(t).s_exchange,this.quotes.deltas(t).s_symbol,...
                    this.quotes.deltas(t).s_market,this.quotes.deltas(t).s_contract,...
                    this.quotes.deltas(t).s_contractType,this.quotes.deltas(t).s_m2mType,...
                    this.quotes.deltas(t).s_optionType,this.quotes.deltas(t).s_currencyCode,...
                    this.quotes.deltas(t).t_strikedate,this.quotes.deltas(t).d_strikeprice,...
                    this.quotes.deltas(t).d_impVol,this.quotes.deltas(t).d_delta] = mysql(query);
                  mysql('close')
                end
              end
            end
          end
        end
      end
      
    %% SIGNALS HISTORY INITIALIZATION
      function InitSignals(this)
        for s=1:length(this.Symbols)
          for ns=1:length(this.Symbols(s).signals)
            currsig = this.Symbols(s).signals(ns);
            symbol = this.Symbols(s);
            if ~currsig.init
              fprintf('\nInitializing signal %s in %s.',...
                currsig.signal,symbol.name);
              sigt = tic;
              symbol.signals(ns) = currsig.function(symbol,currsig);
              fprintf('(%2.4fs)\n',toc(sigt));
            end
          end
        end
      end
      
    %% POSITIONS HISTORY INITIALIZATION
      function InitPositions(this,tradedate)
        if isempty(this.Accounts)
          this.Accounts = RiskAccounts.empty;
          this.Strategies = RiskStrategies.empty;
          this.Positions = RiskPositions.empty;
          % INITIALIZE ACCOUNTS
          for f = 1:length(this.fields)
            if strcmp('riskaccounts',this.fields(f))
              init_accounts_count = size(this.Instance.riskaccounts,2);
              for a=1:init_accounts_count
                account = this.Instance.riskaccounts(a);
                if iscell(account)
                    account = cell2mat(account);
                end
                acc=length(this.Accounts);
                this.Accounts(acc+1) = RiskAccounts(this,account);
              end
            end
          end

          % INITIALIZE POSITIONS HISTORY
          for p=1:length(this.Positions)
            position = this.Positions(p);
            fprintf('\nInitializing %s positions %s...',...
              position.Strategy.strategy,position.Symbol.symbol);
            tp = tic;
            if toc(this.dottime)>1
              fprintf('.');
              this.dottime = tic;
            end
            for o=1:length(position.OMS)
              oms = position.OMS(o);
              oms.LoadOMSTradeHistory(tradedate);
              %oms.OMSTrades.InitHistory(tradedate);
            end
            %position results initialization
            sz = size(this.quotes.timeid);
            np = position.npos;
            symbol = position.Symbol;
            symbol.positions.lastbar(np) = 0;
            symbol.positions.gammaslippage(np) = 0;
            %trade dependent
            symbol.positions.contracts(np,:)=zeros(sz);
            symbol.positions.avgprice(np,:)=zeros(sz);
            symbol.positions.resultclosed(np,:)=zeros(sz);
            symbol.positions.delta(np,:)=zeros(sz);
            symbol.positions.gamma(np,:)=zeros(sz);
            symbol.positions.gammaaccum(np,:)=zeros(sz);
            symbol.positions.slippage(np,:)=zeros(sz);
            %risk input
            symbol.positions.alocation(np,:)=zeros(sz);
            %price dependent
            symbol.positions.equity(np,:)=zeros(sz);
            symbol.positions.resultcurrent(np,:)=zeros(sz);
            symbol.positions.rlog(np,:)=zeros(sz);
            symbol.positions.rlogaccum(np,:)=zeros(sz);
            symbol.positions.rlogaccumadj(np,:)=zeros(sz);
            symbol.positions.rlogaccumalloc(np,:)=zeros(sz);
            symbol.positions.rlogaccumearly(np,:)=zeros(sz);
            symbol.positions.rlogaccumlate(np,:)=zeros(sz);
            
            %update trades & results
            position.UpdateTrades(true);
            position.CalculateResults(true);
            for o=1:length(position.OMS)
              if ~isempty(position.OMS(o).OMSTrades.buffer)
                position.OMS(o).OMSTrades.buffer = [];
              end
            end
            fprintf('(%f)\n',toc(tp));
          end
        end
      end
      function InitFunds(this,tradedate)
        %{
        fundo='KAPITALO ZETA MASTER FIM';
        estrategia = 'Tendencias Moedas';

        query = sprintf(['select * from dbkptl.tbl_boletas1 '...
          'where str_estrategia=''%s'' '...
          'and str_fundo=''%s'' '...
          'order by dte_data asc;'],estrategia,fundo);

        h = mysql( 'open', 'localhost','traders', 'kapitalo' );

        [ boletas.data,  boletas.fundo,      boletas.corretora,...
            boletas.mercado,   boletas.codigo, boletas.serie,  ...
            boletas.descricao,...
            boletas.lote,...
            boletas.preco,boletas.baseroll,boletas.estrategia,...
            boletas.chavetrader, boletas.confirmacao,...
            boletas.hora,boletas.mesa,boletas.origem] = ...
            mysql(query);

        mysql('close') 

        query = sprintf(['select * from dbkptl.tbl_carteira1 '...
          'where str_estrategia=''%s'' '...
          'and str_fundo=''%s'' '...
          'order by dte_data asc;'],estrategia,fundo);
        h = mysql( 'open', 'localhost','traders', 'kapitalo' );

        [ carteira.data,  carteira.fundo,  carteira.mesa,...
            carteira.mercado,   carteira.codigo, carteira.serie,...
            carteira.lote, carteira.estrategia,...
            carteira.ID,carteira.origem] = ...
            mysql(query);

        mysql('close') 

        query = sprintf(['select dte_data,dbl_plpactual '...
          'from dbkptl.tbl_cotaspl '...
          'where str_fundo=''%s'' '...
          'order by dte_data asc;'],fundo);
        h = mysql( 'open', 'localhost','traders', 'kapitalo' );

        [ pl.data,  pl.pl] =  mysql(query);

        mysql('close') 

        trades = [];
        datas = unique(boletas.data);
        for d=1:length(datas)
          datestr(datas(d))
          didx = boletas.data==datas(d);
          codigo = boletas.codigo(didx);
          serie = boletas.serie(didx);
          lote = boletas.lote(didx);
          preco = boletas.preco(didx);
          clear symbols
          for c=1:length(codigo)
            symbols{c} = strcat(codigo{c},serie{c});
          end
          sym = unique(symbols);
          for s=1:length(sym)
            sidx = strcmp(symbols,sym{s});
            sidx=sidx';
            trades(d).codigo{s} = sym{s}(1:3);
            trades(d).serie{s} = sym{s}(4:end);
            trades(d).symbol{s} = sym{s};
            trades(d).buyqty(s) = 0;
            trades(d).buypx(s) = 0;
            trades(d).sellqty(s) = 0;
            trades(d).sellpx(s) = 0;

            longidx = lote>0;
            if any(sidx & longidx)
              longpx = preco(sidx & longidx);
              longqty = lote(sidx & longidx);
              trades(d).buyqty(s) = sum(lote(sidx & longidx));
              trades(d).buypx(s) = sum(longpx.*longqty)/sum(longqty);
            end
            shortidx = lote<0;
            if any(sidx & shortidx)
              shortpx = preco(sidx & shortidx);
              shortqty = lote(sidx & shortidx);
              trades(d).sellqty(s) = sum(lote(sidx & shortidx));
              trades(d).sellpx(s) = sum(shortpx.*shortqty)/sum(shortqty);
            end
            trades(d).qty(s) = ...
              trades(d).buyqty(s) + trades(d).sellqty(s);
            trades(d).preco(s) = ...
             - trades(d).buypx(s) + trades(d).sellpx(s);
          end
        end
        %}
      end
      
    %% TRADEDATE INITIALIZATION
      function StartTradedate(this,tradedate)
        this.tradedate = tradedate;
        fprintf('\n%s: Starting...\n',datestr(tradedate));
        this.dottime = tic;
        this.tinitsim = tic;
        currdate = fix(tradedate);
        this.GMT = this.gmtvec(this.tradedatevec==currdate);
        %Change symbols in series
        StartSymbols(this,tradedate);
        %Open files for writing
        OpenFileIO(this,tradedate);
        if (this.sim || this.backtest)
          %Read simulated tradedate inputs
          StartInputsSIM(this);
        end
        %handles quotes
        StartBars(this,tradedate);
        for s=1:length(this.Symbols)
          this.Symbols(s).StartMDTrades();
        end
        if ~this.sim
          for p=1:length(this.Positions)
            for o=1:length(this.Positions(p).OMS)
              this.Positions(p).OMS(o).UpdateRequests();
            end
            %reset reqtrade/reqorders
            pcol = this.Positions(p).IO.cols;
            this.Positions(p).reqtrade(pcol.value) = 0;
            this.Positions(p).reqorders(:,pcol.value) = 0;
          end
        end
        %start simulation
        initt = toc(this.tinitsim);
        fprintf('\n%s: Started...(%2.4fs)\n',datestr(tradedate),initt);
        this.tinitdate = tic;
        this.initcharts = true;
      end
      function StartSymbols(this,tradedate)
        this.tradedate = tradedate;
        this.dottime = tic;
        %initialize Symbols
        for s=1:length(this.Symbols)
          symbol = this.Symbols(s);
          if symbol.isserie
            symbolid = symbol.seriedates==tradedate;
            symbol.symbol = cell2mat(symbol.seriesymbols(symbolid));
          end
          for io=1:length(symbol.MDQuotes)
            symbol.MDQuotes(io).keys.symbol = symbol.symbol;
          end
          for io=1:length(symbol.MDTrades)
            symbol.MDTrades(io).keys.symbol = symbol.symbol;
          end
          for io=1:length(symbol.MDPriceMarket)
            symbol.MDPriceMarket(io).keys.symbol = symbol.symbol;
          end
          %load tick size
          h = mysql( 'open', this.db.dbconfig.host, ...
            this.db.dbconfig.user,this.db.dbconfig.password);
          query = sprintf(['SELECT ticksize,tickvalue,'...
                           'lotmin,lasttrade,liquidation,',...
                           'brokerage,fees',...
                           ' FROM %s.symbol ',...
                           'where symbol = ''%s'' '],...
                            this.db.dbconfig.schema,symbol.symbol);
          [symbol.ticksize,symbol.tickvalue,...
            symbol.lotmin,symbol.lasttrade,...
            symbol.liquidation,symbol.brokerage,...
            symbol.fees] = mysql(query);
          mysql('close')
        end
        %initialize Positions
        for p=1:length(this.Positions)
          position = this.Positions(p);
          position.IO.keys.symbol = position.Symbol.symbol;
          for o=1:length(position.OMS)
            oms = position.OMS(o);
            oms.OMSTrades.keys.symbol = oms.Symbol.symbol;
            if oms.Symbol.isserie
              oms.OMSTrades.keys.name = oms.Symbol.name;
              oms.OMSTrades.keys.serie = oms.Symbol.serie;
            end
            if ~isempty(oms.OMSRequests)
              oms.OMSRequests.keys.symbol = oms.Symbol.symbol;
              if oms.Symbol.isserie
                oms.OMSRequests.keys.name = oms.Symbol.name;
                oms.OMSRequests.keys.serie = oms.Symbol.serie;
              end
            end
            if ~isempty(oms.OMSReports)
              oms.OMSReports.keys.symbol = oms.Symbol.symbol;
              if oms.Symbol.isserie
                oms.OMSReports.keys.name = oms.Symbol.name;
                oms.OMSReports.keys.serie = oms.Symbol.serie;
              end
            end
          end
        end
      end
      function OpenFileIO(this,tradedate)
        for i=1:length(this.Inputs)
          this.Inputs(i).OpenFileIO(tradedate);
        end
        for o=1:length(this.Outputs)
          this.Outputs(o).OpenFileIO(tradedate);
        end
      end
      function [simstart, simend] = StartInputsSIM(this)
        simstart = 0;simend = 0;
        first = true;
        for i=1:length(this.Inputs)
          [ti, tf] = this.Inputs(i).ReadAll();
          if ti~=0 && tf~=0
            if first
              first = false;
              simstart = ti;
              simend = tf;
            else
              simstart = min(simstart,ti);
              simend = max(simend,tf);
            end
          end
        end
        this.sim_time = simstart;
        sim_step_sec = this.dt;
        mhour = datenum(0,0,0,1,0,0); %mlab one hour standard
        timesize = 24*60*60/sim_step_sec;
        dthour = 24/timesize;
        hours=0:dthour:24-dthour;
        tvec = datevec(this.tradedate);
        t0 = datenum(tvec(1),tvec(2),tvec(3),0,0,0);
        this.sim_time_vec = t0+(hours.*mhour);
        this.sim_timeid = find(this.sim_time_vec>=simstart,1,'first');
        this.sim_last_timeid = find(this.sim_time_vec>=simend,1,'first');
      end
      function StartBars(this,tradedate)
        if this.sim
          l=size(this.quotes.time,2);
          for s=1:length(this.Symbols)
            n=this.Symbols(s).n;
            lstnzid = find(this.quotes.close(n,:),1,'last');
            if lstnzid<l
              for k = lstnzid:l
                if this.quotes.close(n,k) == 0
                  this.quotes.close(n,k) = this.quotes.close(n,k-1);
                end
                if this.quotes.max(n,k) == 0
                  this.quotes.max(n,k) = this.quotes.close(n,k);
                end
                if this.quotes.min(n,k) == 0
                  this.quotes.min(n,k) = this.quotes.close(n,k);
                end
              end
            end
          end
        end
        if this.quotes.tradedates(end)<tradedate
          this.quotes.tradedates(end+1)=tradedate;
          this.quotes.firstbar(end+1)=0;
          this.quotes.lastbar(:,end+1)=0;
          this.quotes.openbar(:,end+1)=0;
        end
      end
      
    %% TRADEDATE LOOP
      function RealtimeLoop(this)
        this.handles = guidata(this.hObject);
        this.sim_stop = this.handles.sim_stop;
        this.sim_pause = this.handles.sim_pause;
        this.plottime = tic;
        while(~this.sim_stop)
          if this.sim_pause
            pause(0.5);
            drawnow;
            %handles = guidata(this.hObject);
            this.sim_stop = this.handles.sim_stop;
            this.sim_pause = this.handles.sim_pause;
            GUIUpdate(this);
          else
            ti = tic;
            %read inputs
            nread = this.ReadInputs();
            if ~this.charting
              %update RT w/ system time
              this.time = max(this.time,now);
            end
            %if any new input
            if nread > 0
              %update inputs cache
              this.UpdateInputs();
            end
            %manage positions
            this.ManagePositions();
            %write outputs
            nwrite = this.WriteOutputs();
            if nread > 0 || nwrite > 0
              %calculate throughput
              throughput = toc(ti);
              this.throughput_vec.append([now,throughput*1000]);
            end
          end
          GUIUpdate(this);
        end
      end
      function SimulationLoop(this)
        this.handles = guidata(this.hObject);
        this.sim_stop = this.handles.sim_stop;
        this.sim_pause = this.handles.sim_pause;
        this.plottime = tic;
        while(~this.sim_stop)
          if this.sim_pause
            pause(0.5);
            drawnow;
            %handles = guidata(this.hObject);
            this.sim_stop = this.handles.sim_stop;
            this.sim_pause = this.handles.sim_pause;
            GUIUpdate(this);
          else
            ti = tic;
            %read inputs
            if ~this.charting
              this.sim_time = this.sim_time_vec(this.sim_timeid);
              this.time = this.sim_time;
              this.sim_timeid = this.sim_timeid+1;
              nread = this.ReadInputsSIM(this.sim_time);
            else
              nread = this.ReadInputs();
            end
            %if any new input
            if nread > 0
              %update inputs cache
              this.UpdateInputs();
            end
            %manage positions
            if ~this.charting
              this.ManagePositions();
            end
            %write outputs
            nwrite = this.WriteOutputs();
            if nread > 0 || nwrite > 0
              %calculate throughput
              throughput = toc(ti);
              if (this.sim || this.backtest) && ~this.charting
                this.throughput_vec.append...
                  ([this.sim_time,throughput*1000*60/this.dt]);
              else
                this.throughput_vec.append([now,throughput*1000]);
              end
            end
          end
          GUIUpdate(this);
          if this.sim_timeid>size(this.sim_time_vec,2) ||...
            this.sim_timeid>this.sim_last_timeid
            break;
          end
        end
      end
      function BacktestLoop(this)
        this.handles = guidata(this.hObject);
        this.sim_stop = this.handles.sim_stop;
        this.sim_pause = this.handles.sim_pause;
        this.plottime = tic;
        fprintf('\nBacktest initialized %2.4fs\n',toc(this.plottime));
        %BacktestResults(this);
        WriteBacktestResultsDaily(this);
        while(~this.sim_stop)
          pause(0.25);
          drawnow;
          this.handles = guidata(this.hObject);
          this.sim_stop = this.handles.sim_stop;
          this.sim_pause = this.handles.sim_pause;
          GUIUpdate(this);
        end
      end
      function BacktestResults(this)
        fprintf('\nWriting Backtest results...\n');
        sheet = 1;
        xlswrite('backtest.xlsx',{'Start date:'},sheet,'A1');
        xlswrite('backtest.xlsx',...
          cellstr(datestr(this.quotes.tradedates(1),'yyyy-mm-dd')),...
          sheet,'B1');
        xlswrite('backtest.xlsx',{'End date:'},sheet,'C1');
        xlswrite('backtest.xlsx',...
          cellstr(datestr(this.quotes.tradedates(end),'yyyy-mm-dd')),...
          sheet,'D1');
        cols = {'Annualized Return','Sharpe','Max Drawdown','Trades %'};
        xlswrite('backtest.xlsx',cols',sheet,'A5');
        nsig = 0;
        for s=1:length(this.Symbols)
          nsig = nsig+length(this.Symbols(s).signals);
        end
        dret = zeros(length(this.quotes.tradedates),nsig);
        sigid = 0;
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            sigid = sigid+1;
            dret(:,sigid) = this.Symbols(s).signals(sig).dret;
          end
        end
        cmatrix = corr(dret);
        sigid = 0;
        xlswrite('backtest.xlsx',cmatrix,sheet,'C12');
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            sigid = sigid+1;
            name={this.Symbols(s).name,this.Symbols(s).signals(sig).signal};
            xlswrite('backtest.xlsx',name',sheet,strcat(char(65+sigid),'3'));
            xlswrite('backtest.xlsx',name',sheet,strcat(char(66+sigid),'10'));
            xlswrite('backtest.xlsx',name,sheet,strcat(char(65),num2str(11+sigid)));
            ndays = length(this.quotes.tradedates);
            cumret = cumsum(this.Symbols(s).signals(sig).dret);
            aret = (1+cumret(end))^(252/ndays)-1;
            gamma = sum(abs(this.Symbols(s).signals(sig).gamma));
            stats = [aret,this.Symbols(s).signals(sig).sharpe,...
                    this.Symbols(s).signals(sig).maxdrawdown,gamma];
            xlswrite('backtest.xlsx',stats',sheet,strcat(char(65+sigid),'5'));
          end
        end
        p = userpath;
        p = p(1:end-1);
        p(end+1)='\';
        e = actxserver('Excel.Application'); 
        ewb = e.Workbooks.Open(strcat(p,'backtest.xlsx')); 
        ewb.Worksheets.Item(sheet).Name = 'Strategy Stats'; 
        ewb.Save 
        ewb.Close(false)
        e.Quit
        
        %DAILY RETURNS
        sheet = 2;
        xlswrite('backtest.xlsx',{'Date'},sheet,'A1');
        xlswrite('backtest.xlsx',...
          cellstr(datestr(this.quotes.tradedates,'yyyy-mm-dd')),sheet,'A2');
        sigid = 0;
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            sigid = sigid+1;
            xlswrite('backtest.xlsx',...
              cellstr(this.Symbols(s).signals(sig).signal),sheet,...
              strcat(char(65+sigid),'1'));
            xlswrite('backtest.xlsx',...
              this.Symbols(s).signals(sig).dret',sheet,...
              strcat(char(65+sigid),'2'));
          end
        end
        p = userpath;
        p = p(1:end-1);
        p(end+1)='\';
        e = actxserver('Excel.Application'); 
        ewb = e.Workbooks.Open(strcat(p,'backtest.xlsx')); 
        ewb.Worksheets.Item(sheet).Name = 'Daily Returns'; 
        ewb.Save 
        ewb.Close(false)
        e.Quit
       
        %ACCUM RETURNS
        sheet = 3;
        xlswrite('backtest.xlsx',{'Date'},sheet,'A1');
        xlswrite('backtest.xlsx',...
          cellstr(datestr(this.quotes.tradedates,'yyyy-mm-dd')),sheet,'A2');
        sigid = 0;
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            sigid = sigid+1;
            xlswrite('backtest.xlsx',...
              cellstr(this.Symbols(s).signals(sig).signal),sheet,...
              strcat(char(65+sigid),'1'));
            xlswrite('backtest.xlsx',...
              cumsum(this.Symbols(s).signals(sig).dret)',sheet,...
              strcat(char(65+sigid),'2'));
          end
        end
        p = userpath;
        p = p(1:end-1);
        p(end+1)='\';
        e = actxserver('Excel.Application'); 
        ewb = e.Workbooks.Open(strcat(p,'backtest.xlsx')); 
        ewb.Worksheets.Item(sheet).Name = 'Accum Returns'; 
        ewb.Save 
        ewb.Close(false)
        e.Quit
        
        %ACCUM RETURNS
        sheet = 4;
        xlswrite('backtest.xlsx',{'Date'},sheet,'A1');
        xlswrite('backtest.xlsx',...
          cellstr(datestr(this.quotes.tradedates,'yyyy-mm-dd')),sheet,'A2');
        sigid = 0;
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            sigid = sigid+1;
            xlswrite('backtest.xlsx',...
              cellstr(this.Symbols(s).signals(sig).signal),sheet,...
              strcat(char(65+sigid),'1'));
            xlswrite('backtest.xlsx',...
              (this.Symbols(s).signals(sig).dretunderwater)',sheet,...
              strcat(char(65+sigid),'2'));
          end
        end
        p = userpath;
        p = p(1:end-1);
        p(end+1)='\';
        e = actxserver('Excel.Application'); 
        ewb = e.Workbooks.Open(strcat(p,'backtest.xlsx')); 
        ews = ewb.Worksheets;
        if ews.Count<sheet
          ews.Add([], ews.Item(ews.Count));
        end
        ewb.Worksheets.Item(sheet).Name = 'Underwater'; 
        ewb.Save 
        ewb.Close(false)
        e.Quit
        %}
        %}
      end
      function WriteBacktestResults(this)
        host='localhost';
        for s=1:length(this.Symbols)
          for sig = 1:length(this.Symbols(s).signals)
            currsig = this.Symbols(s).signals(sig);
            gammaids = find(currsig.gamma~=0);
            nlines=0;
            values = '';
            for i=1:length(gammaids)
              id = gammaids(i);
              line = sprintf(['('...
                '''KPTLInitRT'',''%s'',''XBMF'',''%s'',''%s'',15,''%s'','...
                '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f),'],...
                datestr(this.quotes.time(id),'yyyy-mm-dd'),...
                this.Symbols(s).symbol,currsig.signal,...
                datestr(this.quotes.time(id),'yyyy-mm-dd HH:MM:ss.fff'),...
                currsig.gamma(id),currsig.gammadir(id),currsig.delta(id),...
                currsig.capacity(id),currsig.rlog(id),currsig.slippage(id),...
                currsig.cost(id),currsig.rlogaccum(id),currsig.gammaaccum(id),...
                currsig.slippageaccum(id),currsig.costaccum(id),...
                currsig.rlognetaccum(id),currsig.rlogaccummax(id),...
                currsig.rlogunderwater(id));
              values = strcat(values,line);
              nlines = nlines + 1;
              if nlines>=100
                query = ['insert ignore into dbmarketdata.signals '...
                  '(s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater) VALUES '];
                query = strcat(query,values(1:end-1));
                h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user,this.db.dbconfig.password);
                ninsert = mysql(query);
                mysql('close')
                nlines = 0;
              end
            end
            if nlines>0
              query = ['insert ignore into dbmarketdata.signals '...
                '(s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater) VALUES '];
              query = strcat(query,values(1:end-1));
              h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user,this.db.dbconfig.password);
              ninsert = mysql(query);
              mysql('close')
              nlines = 0;
            end
          end
        end
      end
      function WriteBacktestResultsDaily(this)
        host='localhost';
        mysql('close');
        for s=1:length(this.Symbols)
          currsymbol=this.Symbols(s).symbol;
          for sig = 1:length(this.Symbols(s).signals)
            currsig = this.Symbols(s).signals(sig);
            nlines=0;
            values = '';
            tdays = unique(fix(this.quotes.time));
            firstDay = min(tdays);
            lastDay = max(tdays);
            query = sprintf(['delete from dbmarketdata.signals '...
              'where p_tradedate>=''%s'' and p_tradedate<=''%s'' '...
              'and s_market=''%s'' and p_signal=''%s'' '...
              'and p_period=%i limit 100000;'],...
              datestr(firstDay,'yyyy-mm-dd'),...
              datestr(lastDay,'yyyy-mm-dd'),...
              currsymbol(1:3),currsig.signal,86400);
            h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user,this.db.dbconfig.password);
            mysql(query);
            mysql('close');
            for i=1:length(tdays)
              t = tdays(i);
              id = fix(this.quotes.time)==t;
              lid = find(id);
              lid = lid(end);
              capacity = currsig.capacity(id);
              capacity(capacity==0) = [];
              capacity = mean(capacity);
              if isnan(capacity)
                capacity=-1;
              end
              if isinf(capacity)
                capacity=1000000;
              end
              ttime = t+1;
              sDate = this.Symbols(s).seriedates == t;
              symbol = cell2mat(this.Symbols(s).seriesymbols(sDate));
              line = sprintf(['('...
                '''LongFlyInitBT'',''%s'',''XBMF'',''%s'',''%s'',86400,''%s'',''%s'','...
                '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f),'],...
                datestr(this.quotes.time(lid),'yyyy-mm-dd'),...
                symbol,currsig.signal,...
                datestr(ttime,'yyyy-mm-dd HH:MM:ss.fff'),this.Symbols(s).symbol(1:3),...
                sum(currsig.gamma(id)),currsig.gammadir(lid),currsig.delta(lid),...
                capacity,sum(currsig.rlog(id)),sum(currsig.slippage(id)),...
                sum(currsig.cost(id)),currsig.rlogaccum(lid),currsig.gammaaccum(lid),...
                currsig.slippageaccum(lid),currsig.costaccum(lid),...
                currsig.rlognetaccum(lid),currsig.rlogaccummax(lid),...
                currsig.rlogunderwater(lid));
              values = strcat(values,line);
              nlines = nlines + 1;
              if nlines>=10
                query = ['insert ignore into dbmarketdata.signals '...
                  '(s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater) VALUES '];
                query = strcat(query,values(1:end-1));
                try
                  h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user,this.db.dbconfig.password);
                  ninsert = mysql(query);
                  mysql('close')
                catch
                  fprintf('Error inserting %s\n',currsig.signal);
                end
                nlines = 0;
              end
            end
            if nlines>0
              query = ['insert ignore into dbmarketdata.signals '...
                  '(s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater) VALUES '];
              query = strcat(query,values(1:end-1));
              try
                h = mysql( 'open', this.db.dbconfig.host,this.db.dbconfig.user,this.db.dbconfig.password);
                ninsert = mysql(query);
                mysql('close')
              catch
                fprintf('Error inserting %s\n',currsig.signal);
              end
              nlines = 0;
            end
          end
        end
      end
      
    %% GUI UPDATE  
      function GUIUpdate(this)
        tplot = toc(this.plottime);
        if tplot > 0.25
          this.plottime = tic;
          %gui handling
          drawnow;
          this.handles = guidata(this.hObject);
          this.sim_stop = this.handles.sim_stop;
          this.sim_pause = this.handles.sim_pause;
          % UPDATE CHARTS
          for c=1:this.handles.nMD_GUI
            curr_fig = this.handles.MD_GUI(c);
            if isvalid(curr_fig)
              cfighandles = guidata(curr_fig);
              if this.initcharts
                cla(cfighandles.ax_time_price);
                cla(cfighandles.ax_volume_price);
                cla(cfighandles.ax_time_volume);
              end
              cfighandles = GUIRefresh(this,cfighandles);
              if ~isempty(cfighandles.template)
                tmp = str2func(cfighandles.template);
                tmp(curr_fig,cfighandles,this);
              end
            end
          end
          this.initcharts = false;

          % UPDATE TABLES
          for c=1:this.handles.nACCOUNT_GUI
            curr_fig = this.handles.ACCOUNT_GUI(c);
            if isvalid(curr_fig)
              cfighandles = guidata(curr_fig);
              cfighandles = GUIRefresh(this,cfighandles);
              if ~isempty(cfighandles.template)
                tmp = str2func(cfighandles.template);
                tmp(curr_fig,cfighandles);
              end
            end
          end

          %UPDATE RISK
          for c=1:this.handles.nRISK_GUI
            curr_fig = this.handles.RISK_GUI(c);
            if isvalid(curr_fig)
            cfighandles = guidata(curr_fig);

            %SHOW SYMBOLS
            if length(cfighandles.popupmenu_symbol.String) ~=...
                length(this.Symbols)
              for s = 1:length(this.Symbols)
                cfighandles.popupmenu_symbol.String{s+1} =...
                  this.Symbols(s).symbol;
              end
            end

            %SHOW STRATEGIES
            if length(cfighandles.popupmenu_strategies.String) ~=...
                length(this.Strategies)
              for s = 1:length(this.Strategies)
                cfighandles.popupmenu_strategies.String{s+1} =...
                  this.Strategies(s).strategy;
              end
            end

            %SHOW ACCOUNTS
            if length(cfighandles.popupmenu_account.String) ~=...
                length(this.Accounts)
              for a = 1:length(this.Accounts)
                cfighandles.popupmenu_account.String{a+1} =...
                  this.Accounts(a).account;
              end
            end
            
            if ~isempty(cfighandles.parent)
                %SELECT ACCOUNT
                if strcmp(cfighandles.account,'')  
                  cfighandles.Account = [];
                else
                  for s=1:length(this.Accounts)
                    if strcmp(cfighandles.account,this.Accounts(s).account)
                      cfighandles.Account = this.Accounts(s);
                      break;
                    end
                  end
                end

                %SELECT STRATEGY
                if strcmp(cfighandles.strategy,'')  
                  cfighandles.Strategy = [];
                else
                  for s=1:length(this.Strategies)
                    if strcmp(cfighandles.strategy,this.Strategies(s).strategy) && ...
                        strcmp(cfighandles.account,this.Strategies(s).Account.account)
                      cfighandles.Strategy = this.Strategies(s);
                      break;
                    end
                  end
                end

                if ~isempty(cfighandles.Strategy)
                  for p=1:length(cfighandles.Strategy.Positions)
                    if strcmp(cfighandles.parent,...
                          cfighandles.Strategy.Positions(p).Symbol.symbol)
                        cfighandles.Position = ...
                          cfighandles.Strategy.Positions(p);
                        break;
                    end
                  end
                end
                
                

                for s=1:length(this.Symbols)
                  if strcmp(cfighandles.parent,this.Symbols(s).symbol)
                    cfighandles.symbol = this.Symbols(s);
                    tmp = str2func('RISK_GUI_Template');
                    tmp(curr_fig,cfighandles);
                    break;
                  end
                end

                % Update handles structure
                guidata(curr_fig, cfighandles);
            end
            end
          end
        end

        if isempty(this.handles.axes1.Children)
          plot(this.handles.axes1,...
            this.throughput_vec.alldata(:,1),...
            this.throughput_vec.alldata(:,2));
          datetick(this.handles.axes1,'x');
        else
          this.handles.axes1.Children.XData =...
            this.throughput_vec.alldata(:,1);
          this.handles.axes1.Children.YData =...
            this.throughput_vec.alldata(:,2);
          datetick(this.handles.axes1,'x');
        end
      end
      function cfighandles = GUIRefresh(this,cfighandles)
        %SHOW ACCOUNTS
        if length(cfighandles.popupmenu_account.String) ~=...
            length(this.Accounts)+1
          cfighandles.popupmenu_account.String{1} = '';
          for a = 1:length(this.Accounts)
            cfighandles.popupmenu_account.String{a+1} =...
              this.Accounts(a).account;
          end
        end
        account = cfighandles.popupmenu_account.String...
              {cfighandles.popupmenu_account.Value};
        %SELECT ACCOUNT
        if strcmp(account,'')  
          cfighandles.Account = [];
          cfighandles.Strategy = [];
          cfighandles.Position = [];
        else
          for s=1:length(this.Accounts)
            if strcmp(account,this.Accounts(s).account)
              cfighandles.Account = this.Accounts(s);
              break;
            end
          end
        end
        if ~isempty(cfighandles.Account)
          %SHOW STRATEGIES
          if length(cfighandles.popupmenu_strategies.String) ~=...
              length(cfighandles.Account.Strategies)+1
            for s = 1:length(cfighandles.Account.Strategies)
              cfighandles.popupmenu_strategies.String{s+1} =...
                cfighandles.Account.Strategies(s).strategy;
            end
          end
          strategy = cfighandles.popupmenu_strategies.String...
              {cfighandles.popupmenu_strategies.Value};
          %SELECT STRATEGY
          if strcmp(strategy,'')  
            cfighandles.Strategy = [];
          else
            for s=1:length(cfighandles.Account.Strategies)
              if strcmp(strategy,cfighandles.Account.Strategies(s).strategy)
                cfighandles.Strategy = cfighandles.Account.Strategies(s);
                break;
              end
            end
          end
          if ~isempty(cfighandles.Strategy)
            %SHOW SYMBOLS
            if length(cfighandles.popupmenu_symbol.String) ~=...
              length(cfighandles.Strategy.Positions)+1
              cfighandles.popupmenu_symbol.Value = 1;
              cfighandles.popupmenu_symbol.String = {''};
            end
            for s = 1:length(cfighandles.Strategy.Positions)
              cfighandles.popupmenu_symbol.String{s+1} =...
                cfighandles.Strategy.Positions(s).Symbol.name;
            end
            if ~isempty(cfighandles.parent)
              for p=1:length(cfighandles.Strategy.Positions)
                if strcmp(cfighandles.parent,...
                          cfighandles.Strategy.Positions(p).Symbol.name)
                    cfighandles.Position = cfighandles.Strategy.Positions(p);
                    break;
                end
              end
              for s=1:length(this.Symbols)
                if strcmp(cfighandles.parent,this.Symbols(s).name)
                  cfighandles.symbol = this.Symbols(s);
                  break;
                end
              end
            end
          else
            %SHOW SYMBOLS
            for s = 1:length(this.Symbols)
              cfighandles.popupmenu_symbol.String{s+1} =...
                this.Symbols(s).name;
            end
            if ~isempty(cfighandles.parent)
              for s=1:length(this.Symbols)
                if strcmp(cfighandles.parent,this.Symbols(s).name)
                  cfighandles.symbol = this.Symbols(s);
                  break;
                end
              end
            end
          end
        else
          %SHOW SYMBOLS
          for s = 1:length(this.Symbols)
            cfighandles.popupmenu_symbol.String{s+1} =...
              this.Symbols(s).name;
          end
          if ~isempty(cfighandles.parent)
            for s=1:length(this.Symbols)
              if strcmp(cfighandles.parent,this.Symbols(s).name)
                cfighandles.symbol = this.Symbols(s);
                nsig = length(this.Symbols(s).signals);
                if length(cfighandles.popupmenu_strategies.String)~=nsig+1
                  cfighandles.popupmenu_strategies.String = {' '};
                  for sig = 1:nsig
                    cfighandles.popupmenu_strategies.String{sig+1} =...
                      cfighandles.symbol.signals(sig).signal;
                  end
                end
                break;
              end
            end
          else
            cfighandles.symbol = [];
          end
        end
      end
      
    %% INPUTS READING
      function nread = ReadInputs(this)
        nread = 0;
        for i=1:length(this.Inputs)
          [t, r] = this.Inputs(i).ReadNew();
          nread = nread + r;
          if t>this.time
            this.time = t;
          end
        end
      end
      function nread = ReadInputsSIM(this,sim_time)
        nread = 0;
        for i=1:length(this.Inputs)
          [t, r] = this.Inputs(i).ReadUntil(sim_time);
          nread = nread + r;
        end
      end
      
    %% INPUTS UPDATING   
      function UpdateInputs(this)
        UpdateBars(this);
        for s=1:length(this.Symbols)
          this.Symbols(s).UpdateMDTrades();
          this.Symbols(s).UpdateMDPriceMarket();
          this.Symbols(s).CalculateSignals();
        end
      end
      function UpdateBars(this)
        for s=1:length(this.Symbols)
          currIO = this.Symbols(s).MDQuotes(1);
          n = this.Symbols(s).n;
          cols = currIO.cols;
          if ~isempty(currIO.buffer)
            firstbar = min(currIO.buffer(:,cols.time));
            closebar = max(currIO.buffer(:,cols.time));
            if ~isempty(this.time)
              closebar = max(closebar,this.time);
            end
            if closebar>this.quotes.time(end)
              NewBarsTradedate(this,firstbar);
            end
            firstid = this.quotes.firstbar(end);
            firsttimeid = this.quotes.timeid(firstid);
            ftid = firstid-firsttimeid;
            lastid=round(closebar/this.quotes.dt)+firstid-firsttimeid;
            timeid=ftid+round(currIO.buffer(:,cols.time)./this.quotes.dt);
            this.quotes.open(n,timeid) = currIO.buffer(:,cols.open);
            this.quotes.close(n,timeid) = currIO.buffer(:,cols.close);
            this.quotes.max(n,timeid) = currIO.buffer(:,cols.max);
            this.quotes.min(n,timeid) = currIO.buffer(:,cols.min);
            this.quotes.volume(n,timeid) = currIO.buffer(:,cols.volume);
            this.quotes.buyvolume(n,timeid)=...
              currIO.buffer(:,cols.buyvolume);
            this.quotes.sellvolume(n,timeid)=...
              currIO.buffer(:,cols.sellvolume);
            this.quotes.bestbid(n,timeid)=currIO.buffer(:,cols.bestbid);
            this.quotes.bidqty(n,timeid)=currIO.buffer(:,cols.bidqty);
            this.quotes.bestask(n,timeid)=currIO.buffer(:,cols.bestask);
            this.quotes.askqty(n,timeid)=currIO.buffer(:,cols.askqty);
            
            if this.quotes.openbar(n,end) == 0
              tradeidx =...
                this.quotes.volume(n,this.quotes.firstbar(end):end)>0;
              if any(tradeidx)
                this.quotes.openbar(n,end)=...
                  find(tradeidx,1,'first')+this.quotes.firstbar(end)-1;
              end
            end
            lstb = this.quotes.lastbar(n,end);
            if lstb == 0
              lstb = this.quotes.lastbar(n,end-1);
            end
            for k = lstb+1:lastid
              if this.quotes.close(n,k) == 0
                this.quotes.close(n,k) = this.quotes.close(n,k-1);
              end
              if this.quotes.open(n,k) == 0
                this.quotes.open(n,k) = this.quotes.close(n,k);
              end
              if this.quotes.max(n,k) == 0
                this.quotes.max(n,k) = this.quotes.close(n,k);
              end
              if this.quotes.min(n,k) == 0
                this.quotes.min(n,k) = this.quotes.close(n,k);
              end
              if k>1
                this.quotes.rlog(n,k) = ...
                  log(this.quotes.close(n,k)/this.quotes.close(n,k-1));
                this.quotes.rlogaccum(n,k) = ...
                  this.quotes.rlog(n,k)+this.quotes.rlogaccum(n,k-1);
                ob = this.quotes.openbar(n,end);
                if ob~=0
                  this.quotes.rlogintraday(n,k)=...
                    log(this.quotes.close(n,k)/this.quotes.close(n,ob));
                else
                  this.quotes.rlogintraday(n,k)=0;
                end
                fb = this.quotes.firstbar(end);
                this.quotes.rlogdaily(n,k)=...
                    log(this.quotes.close(n,k)/this.quotes.close(n,fb-1));
              end
            end
            this.quotes.lastbar(n,end)=...
              max(this.quotes.lastbar(n,end),lastid);
            
            currIO.buffer = [];
          elseif this.backtest || this.sim
            if this.quotes.lastbar(n,end) > 0 &&...
                this.quotes.firstbar(end)>0 &&...
               ~isempty(this.time)
              if this.time>this.quotes.time(end)
                firstbar = round(this.time/this.quotes.dt)*this.quotes.dt;
                NewBarsTradedate(this,firstbar);
              end
              firstid = this.quotes.firstbar(end);
              firsttimeid = this.quotes.timeid(firstid);
              lastid=floor(this.time/this.quotes.dt)+firstid-firsttimeid;
              for k = this.quotes.lastbar(n,end)+1:lastid
                if this.quotes.close(n,k) == 0
                  this.quotes.close(n,k) = this.quotes.close(n,k-1);
                end
                if this.quotes.open(n,k) == 0
                  this.quotes.open(n,k) = this.quotes.close(n,k);
                end
                if this.quotes.max(n,k) == 0
                  this.quotes.max(n,k) = this.quotes.close(n,k);
                end
                if this.quotes.min(n,k) == 0
                  this.quotes.min(n,k) = this.quotes.close(n,k);
                end
                ob = this.quotes.openbar(n,end);
                if ob~=0
                  this.quotes.rlogintraday(n,k)=...
                    log(this.quotes.close(n,k)/this.quotes.close(n,ob));
                else
                  this.quotes.rlogintraday(n,k)=0;
                end
                fb = this.quotes.firstbar(end);
                this.quotes.rlogdaily(n,k)=...
                    log(this.quotes.close(n,k)/this.quotes.close(n,fb-1));
              end
              this.quotes.lastbar(n,end)=...
                max(this.quotes.lastbar(n,end),lastid);
            end
          end
        end
      end
      function NewBarsTradedate(this,firstbar)
        lstp = 0;
        for s=1:length(this.Symbols)
          n = this.Symbols(s).n;
          lstb = find(this.quotes.volume(n,:),1,'last');
          if ~isempty(lstb)
            lstp = max(lstp,lstb);
          end
        end
        if lstp<size(this.quotes.time,2)
          this.quotes.time(lstp+1:end) = [];
          this.quotes.timeid(lstp+1:end) = [];
          this.quotes.open(:,lstp+1:end) = [];
          this.quotes.close(:,lstp+1:end) = [];
          this.quotes.max(:,lstp+1:end) = [];
          this.quotes.min(:,lstp+1:end) = [];
          this.quotes.volume(:,lstp+1:end) = [];
          this.quotes.buyvolume(:,lstp+1:end) = [];
          this.quotes.sellvolume(:,lstp+1:end) = [];
          this.quotes.bestbid(:,lstp+1:end) = [];
          this.quotes.bidqty(:,lstp+1:end) = [];
          this.quotes.bestask(:,lstp+1:end) = [];
          this.quotes.askqty(:,lstp+1:end) = [];
          this.quotes.rlog(:,lstp+1:end) = [];
          this.quotes.rlogintraday(:,lstp+1:end) = [];
          this.quotes.rlogdaily(:,lstp+1:end) = [];
          this.quotes.rlogaccum(:,lstp+1:end) = [];
          for s=1:length(this.Symbols)
            symbol = this.Symbols(s);
            if ~isempty(symbol.positions.contracts)
              symbol.positions.lastbar(:) = lstp;
              symbol.positions.delta(:,lstp+1:end) = [];
              symbol.positions.gamma(:,lstp+1:end) = [];
              symbol.positions.gammaaccum(:,lstp+1:end) = [];
              symbol.positions.slippage(:,lstp+1:end) = [];
              symbol.positions.contracts(:,lstp+1:end) = [];
              symbol.positions.avgprice(:,lstp+1:end) = [];
              symbol.positions.resultclosed(:,lstp+1:end) = [];
              symbol.positions.alocation(:,lstp+1:end) = [];
              symbol.positions.equity(:,lstp+1:end) = [];
              symbol.positions.resultcurrent(:,lstp+1:end) = [];
              symbol.positions.rlog(:,lstp+1:end) = [];
              symbol.positions.rlogaccum(:,lstp+1:end) = [];
              symbol.positions.rlogaccumadj(:,lstp+1:end) = [];
              symbol.positions.rlogaccumalloc(:,lstp+1:end) = [];
              symbol.positions.rlogaccumearly(:,lstp+1:end) = [];
              symbol.positions.rlogaccumlate(:,lstp+1:end) = [];
            end
          end
        end
        n=length(this.Symbols);
        newdaytime = firstbar:this.quotes.dt:fix(firstbar)+1-this.quotes.dt;
        L = size(newdaytime,2);
        this.quotes.firstbar(end) = lstp+1;
        this.quotes.time(lstp+1:lstp+L) = newdaytime;
        this.quotes.timeid(lstp+1:lstp+L) = round(newdaytime./this.quotes.dt);
        this.quotes.open(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.close(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.max(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.min(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.volume(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.buyvolume(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.sellvolume(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.bestbid(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.bidqty(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.bestask(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.askqty(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.rlog(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.rlogintraday(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.rlogdaily(:,lstp+1:lstp+L) = zeros(n,L);
        this.quotes.rlogaccum(:,lstp+1:lstp+L) = zeros(n,L);
        
        for s=1:length(this.Symbols)
          symbol = this.Symbols(s);
          if ~isempty(symbol.positions.contracts)
            for p=1:size(symbol.positions.contracts,1)
              symbol.positions.delta(p,lstp+1:lstp+L) =...
                symbol.positions.delta(p,lstp);
              symbol.positions.gamma(p,lstp+1:lstp+L) =...
                symbol.positions.gamma(p,lstp);
              symbol.positions.gammaaccum(p,lstp+1:lstp+L) =...
                symbol.positions.gammaaccum(p,lstp);
              symbol.positions.slippage(p,lstp+1:lstp+L) =...
                symbol.positions.slippage(p,lstp);
              symbol.positions.contracts(p,lstp+1:lstp+L) =...
                symbol.positions.contracts(p,lstp);
              symbol.positions.avgprice(p,lstp+1:lstp+L) =...
                symbol.positions.avgprice(p,lstp);
              symbol.positions.resultclosed(p,lstp+1:lstp+L) =...
                symbol.positions.resultclosed(p,lstp);
              symbol.positions.alocation(p,lstp+1:lstp+L) =...
                symbol.positions.alocation(p,lstp);
              symbol.positions.equity(p,lstp+1:lstp+L) =...
                symbol.positions.equity(p,lstp);
              symbol.positions.resultcurrent(p,lstp+1:lstp+L) =...
                symbol.positions.resultcurrent(p,lstp);
              symbol.positions.rlog(p,lstp+1:lstp+L) = zeros(1,L);
              symbol.positions.rlogaccum(p,lstp+1:lstp+L) =...
                symbol.positions.rlogaccum(p,lstp);
              symbol.positions.rlogaccumadj(p,lstp+1:lstp+L) =...
                symbol.positions.rlogaccumadj(p,lstp);
              symbol.positions.rlogaccumalloc(p,lstp+1:lstp+L) =...
                symbol.positions.rlogaccumalloc(p,lstp);
              symbol.positions.rlogaccumearly(p,lstp+1:lstp+L) =...
                symbol.positions.rlogaccumearly(p,lstp);
              symbol.positions.rlogaccumlate(p,lstp+1:lstp+L) =...
                symbol.positions.rlogaccumlate(p,lstp);
            end
          end
        end
      end
      
    %% POSITION MANAGEMENT   
      function ManagePositions(this)
        for p=1:length(this.Positions)
          this.Positions(p).ManagePosition();
        end
      end
      
    %% OUTPUTS WRITING
      function nwrite = WriteOutputs(this)
        nwrite = 0;
        for o=1:length(this.Outputs)
          nwrite = nwrite + this.Outputs(o).WriteOutputs();
        end
      end
      
    %% TRADEDATE CLOSING
      function FinishTradedate(this)
        for i=1:length(this.Inputs)
          this.Inputs(i).Close();
        end
        for o=1:length(this.Outputs)
          this.Outputs(o).Close();
        end
        initt = toc(this.tinitdate);
        fprintf('%s: Finished!(%2.4fs)\n',...
          datestr(this.tradedate),initt);
      end
      
    %% SIMULATION RESET
      function ResetSimulation(this)
        InitializeGUI(this,this.hObject,this.handles);
        startdateid = find(this.quotes.tradedates == this.startdate);
        if ~isempty(startdateid)
          %reset quotes
          this.quotes.tradedates(startdateid:end)=[];
          this.quotes.firstbar(startdateid:end)=[];
          this.quotes.openbar(:,startdateid:end)=[];
          this.quotes.lastbar(:,startdateid:end)=[];
          lstb = max(this.quotes.lastbar(:,end))+1;
          this.quotes.time(lstb:end) = [];
          this.quotes.timeid(lstb:end) = [];
          this.quotes.close(:,lstb:end) = [];
          this.quotes.max(:,lstb:end) = [];
          this.quotes.min(:,lstb:end) = [];
          this.quotes.volume(:,lstb:end) = [];
          this.quotes.buyvolume(:,lstb:end) = [];
          this.quotes.sellvolume(:,lstb:end) = [];
          %reset positions results
          for s=1:length(this.Symbols)
            symbol = this.Symbols(s);
            np=length(symbol.Positions);
            if ~isempty(symbol.positions.contracts)
              symbol.positions.lastbar(1:np) = lstb;
              symbol.positions.contracts(:,lstb:end) = [];
              symbol.positions.avgprice(:,lstb:end) = [];
              symbol.positions.resultclosed(:,lstb:end) = [];
              symbol.positions.alocation(:,lstb:end) = [];
              symbol.positions.equity(:,lstb:end) = [];
              symbol.positions.resultcurrent(:,lstb:end) = [];
              symbol.positions.rlog(:,lstb:end) = [];
              symbol.positions.rlogaccum(:,lstb:end) = [];
              symbol.positions.rlogaccumadj(:,lstb:end) = [];
            end
          end
          %reset position trades & oms requests/reports
          for p=1:length(this.Positions)
            position = this.Positions(p);
            position.InitPosition();
            if ~isempty(position.trades)
              tcol = position.OMS(1).OMSTrades.cols;
              tc_cnt = position.OMS(1).OMSTrades.cols_count;
              lsttime = this.quotes.time(end);
              lsttrade=...
                find(position.trades(:,tcol.time)>lsttime,1,'first');
              if ~isempty(lsttrade)
                position.ntrades = lsttrade-1;
                l = size(position.trades,1)-lsttrade+1;
                position.trades(lsttrade:end,:)=zeros(l,tc_cnt);
                position.tradedirection(lsttrade:end)=zeros(l,1);
                position.contracts(lsttrade:end)=zeros(l,1);
                position.avgprice(lsttrade:end)=zeros(l,1);
                position.resultclosed(lsttrade:end)=zeros(l,1);
              end
            end
            if ~position.simulated
              for o=1:length(position.OMS)
                currOMS = position.OMS(o);
                %reset requests
                reqcol = currOMS.OMSRequests.cols;
                rc_cnt = currOMS.OMSRequests.cols_count;
                lsttime = this.quotes.time(end);
                lstreq = ...
                  find(currOMS.requests(:,reqcol.time)>lsttime,1,'first');
                if ~isempty(lstreq)
                  currOMS.nrequests = lstreq-1;
                  l = size(currOMS.requests,1);
                  currOMS.requests(lstreq:l,:)=zeros(l-lstreq+1,rc_cnt);
                end
                %reset reports
                repcol = currOMS.OMSReports.cols;
                rp_cnt = currOMS.OMSReports.cols_count;
                lstrep = ...
                  find(currOMS.reports(:,repcol.time)>lsttime,1,'first');
                if ~isempty(lstrep)
                  currOMS.nreports = lstrep-1;
                  l = size(currOMS.reports,1);
                  currOMS.reports(lstrep:l,:)=zeros(l-lstrep+1,rp_cnt);
                end
                %reset orders
                lstord = ...
                  find(currOMS.orders(:,repcol.time)>lsttime,1,'first');
                if ~isempty(lstord)
                  currOMS.norders = lstord-1;
                  l = size(currOMS.orders,1);
                  l=l-lstord+1;
                  currOMS.orders(lstord:end,:)=zeros(l,rp_cnt);
                  currOMS.iocidx(lstord:end) = false(l,1);
                  currOMS.limitidx(lstord:end) = false(l,1);
                  currOMS.stopidx(lstord:end) = false(l,1);
                  currOMS.reqpendingidx(lstord:end) = false(l,1);
                  currOMS.reqcancelidx(lstord:end) = false(l,1);
                  currOMS.reportpendingidx(lstord:end) = false(l,1);
                  currOMS.activeidx(lstord:end) = false(l,1);
                  currOMS.stoptriggeridx(lstord:end) = false(l,1);
                end
                currOMS.UpdatePositionProfile();
              end
            end
          end
          %reset signals
          for s=1:length(this.Symbols)
            for sig = 1:length(this.Symbols(s).signals)
              this.Symbols(s).signals(sig).lastbar = lstb;
            end
          end
          %reset trades
          for s=1:length(this.Symbols)
            if ~isempty(this.Symbols(s).MDTrades)
              cols = this.Symbols(s).MDTrades.cols;
              cols_count = this.Symbols(s).MDTrades.cols_count;
              nt = this.Symbols(s).ntrades;
              tsize = size(this.Symbols(s).trades,1);
              firstid = ...
                find(this.Symbols(s).trades(1:nt,cols.time)>...
                this.startdate,1,'first');
              this.Symbols(s).ntrades = firstid-1;
              nt = this.Symbols(s).ntrades;
              this.Symbols(s).trades(nt+1:tsize,:) = zeros(tsize-nt,cols_count);
            end
          end
        end
      end
      function ResetBacktest(this)
        InitializeGUI(this,this.hObject,this.handles);
        if ~this.charting
          for s=1:length(this.Symbols)
            for sig = 1:length(this.Symbols(s).signals)
              if this.Symbols(s).signals(sig).backtest
                this.Symbols(s).signals(sig).init = false;
              end
            end
          end
        end
      end
    end
end