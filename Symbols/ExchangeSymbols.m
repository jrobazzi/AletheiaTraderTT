classdef ExchangeSymbols < handle
    %EXCHANGESYMBOLS Trade Symbols 
    %   ExchangeSymbols 
    properties (Access = private)
      inputs_initalized = false;
      outputs_initalized = false;
      TRADESIZE = 1000000;
	  TICK_QTD = 30000;
    end
    
    properties
      Main
      Instance
      MDQuotes
      MDPriceMarket
      MDTrades
      Positions

      isserie = false
      n
      symbol
      serie
      name
      seriedates
      seriesymbols
      serieroll
      
      ticksize
      tickvalue
      lotmin
      lasttrade
      liquidation
      brokerage
      fees
      
      %FILTERS
      filters
      %SIGNALS
      signals
      %RISKY POSITIONS
      positions
           
      % MARKET DATA
      ntrades = 0;
      trades
      bids
      asks
      bestbid = 0;
      bestask = 0;
    end
    
    methods
    %% CONSTRUCTOR
      function this = ExchangeSymbols(Main,instance,n)
        if nargin > 0
          this.Main = Main;
          this.Instance = instance;
          this.n = n;
          fnames = fieldnames(this.Instance.Attributes);
          for f=1:length(fnames)
            fname = fnames(f);
            if iscell(fname)
              fname = cell2mat(fname);
            end
            if strcmp(fname,'serie')
              this.isserie = true;
              this.serie = this.Instance.Attributes.serie;
              this.name = this.Instance.Attributes.name;
              h = mysql( 'open', this.Main.db.dbconfig.host, ...
              this.Main.db.dbconfig.user, this.Main.db.dbconfig.password );
              query = sprintf(['SELECT tradedate,symbol '...
                          'FROM %s.series ',...
                          'where serie = ''%s'' ',...
                          'and name = ''%s'' '],...
                          this.Main.db.dbconfig.schema,...
                          this.serie,...
                          this.name);
              [ this.seriedates, this.seriesymbols ] = mysql(query);
              mysql('close') 
              n=length(this.seriedates);
              this.serieroll = zeros(n,1);
              for d=2:length(this.seriedates)
                if ~strcmp(this.seriesymbols(d-1),this.seriesymbols(d))
                  this.serieroll(d) = 1;
                end
              end
            end
          end
          if this.isserie
            seriename = strcat(this.serie,'_');
            seriename = strcat(seriename,this.name);
            this.name = seriename;
          else
            this.symbol = this.Instance.Attributes.symbol;
            this.name = this.symbol;
            this.serie = this.symbol;
          end
          %init IOs
          InitMDQuotes(this);
          InitMDTrades(this);
          InitMDPriceMarket(this);
          InitSignals(this);
          InitPositions(this);
        end
      end
      function InitMDQuotes(this)
        this.MDQuotes = FileIO.empty;
        inst = this.Instance;
        inst.Attributes.symbol = this.symbol;
        if this.isserie
          inst.Attributes.serie = this.serie;
          inst.Attributes.name = this.name;
        end
        inst.Attributes.history = this.Main.history;
        this.MDQuotes(1) = FileIO(this.Main,inst); 
      end
      function InitMDTrades(this)
        this.MDTrades = FileIO.empty;
        inittrades = false;
        fnames = fieldnames(this.Instance);
        for f=1:length(fnames)
          if strcmp(fnames(f),'mdtrades')
            inittrades = true;
            break;
          end
        end
        if inittrades
          inst = this.Instance;
          inst.Attributes.table = 'mdtrades';
          inst.Attributes.symbol = this.symbol;
          if this.isserie
            inst.Attributes.serie = this.serie;
            inst.Attributes.name = this.name;
          end
          inst.Attributes.history = ...
            str2double(inst.mdtrades.Attributes.history);
          this.MDTrades(1) = FileIO(this.Main,inst); 
        end
      end
      function InitMDPriceMarket(this)
        this.MDPriceMarket = FileIO.empty;
        this.bids = [];
        this.asks = [];
        initmarket = false;
        fnames = fieldnames(this.Instance);
        for f=1:length(fnames)
          if strcmp(fnames(f),'mdpricemarket')
            initmarket = true;
            break;
          end
        end
        if initmarket
          inst = this.Instance;
          inst.Attributes.table = 'mdpricemarket';
          inst.Attributes.symbol = this.symbol;
          if this.isserie
            inst.Attributes.serie = this.serie;
            inst.Attributes.name = this.name;
          end
          inst.Attributes.history = 0;
          this.MDPriceMarket(1) = FileIO(this.Main,inst); 
          this.bids = zeros(this.TICK_QTD,1); % alterando a quantidade de ticks
          this.asks = zeros(this.TICK_QTD,1); %
        end
      end
      function InitSignals(this)
        this.signals = [];
        issignal = false;
        fnames = fieldnames(this.Instance);
        for f=1:length(fnames)
          if strcmp(fnames(f),'signals')
            issignal = true;
            break;
          end
        end
        if issignal
          for f=1:length(this.Instance.signals)
            sig = this.Instance.signals(f);
            if iscell(sig)
              sig = cell2mat(sig);
            end
            %init signals
            this.signals(f).backtest=...
              strcmp(sig.Attributes.backtest,'true');
            this.signals(f).signal=(sig.Attributes.signal);
            this.signals(f).function=...
              str2func(strcat('Signal_',sig.Attributes.signal));
            this.signals(f).init = false;
            this.signals(f).lastbar = 0;
            this.signals(f).sharpe=0;
            this.signals(f).maxdrawdown=0;
            %daily
            this.signals(f).dret=[];
            this.signals(f).dretunderwater=[];
            %intraday
            this.signals(f).gamma=[]; 
            this.signals(f).gammadir=[];
            this.signals(f).delta=[];
            this.signals(f).capacity=[];
            this.signals(f).rlog=[];
            this.signals(f).slippage=[];
            this.signals(f).cost=[];
            this.signals(f).rlogaccum=[];
            this.signals(f).gammaaccum=[];
            this.signals(f).costaccum=[];
            this.signals(f).slippageaccum=[];
            this.signals(f).rlognetaccum=[];
            this.signals(f).rlogaccummax=[];
            this.signals(f).rlogunderwater=[];
            %positions stats
            this.signals(f).positions.npos=0;
            this.signals(f).positions.opentime=zeros(5000,1);
            this.signals(f).positions.closetime=zeros(5000,1);
            this.signals(f).positions.delta=zeros(5000,1);
            this.signals(f).positions.equity=zeros(5000,1);
            this.signals(f).positions.long=zeros(5000,1);
            this.signals(f).positions.short=zeros(5000,1);
            this.signals(f).positions.points=zeros(5000,1);
            this.signals(f).positions.result=zeros(5000,1);
            this.signals(f).positions.return=zeros(5000,1);
          end
        end
      end
      function InitPositions(this)
        %init positions
        this.Positions = RiskPositions.empty;
        this.positions.contracts=[];
        this.positions.avgprice=[];
        this.positions.resultclosed=[];
        this.positions.delta=[];
        this.positions.gamma=[];
        this.positions.slippage=[];
        this.positions.alocation=[];
        this.positions.equity=[];
        this.positions.resultcurrent=[];
        this.positions.return=[];
        this.positions.returnaccum=[];
        this.positions.returnaccumadj=[];
        this.positions.returnaccumalloc=[];
        this.positions.returnaccumearly=[];
        this.positions.returnaccumlate=[];
      end
      
    %% MDTRADES
      function InitMDTradesHistory(this,tradedate)
        if ~isempty(this.MDTrades)
        currIO = this.MDTrades(1);
        currIO.InitHistory(tradedate);
        this.trades = currIO.buffer;
        this.ntrades = size(this.trades,1);
        end
      end
      function StartMDTrades(this)
        if ~isempty(this.MDTrades)
          nt = size(this.trades,1);
          newtrades = this.ntrades+this.TRADESIZE;
          if newtrades>nt
            this.trades(nt+1:newtrades,:) = ...
              zeros(newtrades-nt,this.MDTrades.cols_count);
          end
        end
      end
      function UpdateMDTrades(this)
        if ~isempty(this.MDTrades)
          nt = size(this.MDTrades(1).buffer,1);
          this.trades(this.ntrades+1:this.ntrades+nt,:)=...
            this.MDTrades(1).buffer;
          this.MDTrades(1).buffer = [];
          this.ntrades = this.ntrades+nt;
        end
      end
      
    %% MDPRICEMARKET
      function UpdateMDPriceMarket(this)
        if ~isempty(this.MDPriceMarket)
          if ~isempty(this.MDPriceMarket(1).buffer)
            buffer = this.MDPriceMarket(1).buffer;
            this.MDPriceMarket(1).buffer = [];
            cols = this.MDPriceMarket(1).cols;
            tags = this.MDPriceMarket(1).tags;
            tagid = this.MDPriceMarket(1).tagid;
            asksnapidx = buffer(:,cols.tag) == tagid(tags.askSNAP);
            askupidx = buffer(:,cols.tag) == tagid(tags.askUP);
            bidsnapidx = buffer(:,cols.tag) == tagid(tags.bidSNAP);
            bidupidx = buffer(:,cols.tag) == tagid(tags.bidUP);
            bestbididx = buffer(:,cols.tag) == tagid(tags.bestbid);
            bestaskidx = buffer(:,cols.tag) == tagid(tags.bestask);
            if any(asksnapidx)
              pidx = round(buffer(asksnapidx,cols.price)./this.ticksize);
              this.asks(pidx) = -buffer(asksnapidx,cols.value);
            end
            if any(askupidx)
              pidx = round(buffer(askupidx,cols.price)./this.ticksize);
              this.asks(pidx) = -buffer(askupidx,cols.value);
            end
            if any(bidsnapidx)
              pidx = round(buffer(bidsnapidx,cols.price)./this.ticksize);
              this.bids(pidx) = buffer(bidsnapidx,cols.value);
            end
            if any(bidupidx)
              pidx = round(buffer(bidupidx,cols.price)./this.ticksize);
              this.bids(pidx) = buffer(bidupidx,cols.value);
            end
            if any(bestbididx)
              id = find(bestbididx,1,'last');
              bb = buffer(id,:);
              pidx = round(bb(cols.price)/this.ticksize);
              if pidx>1
                this.bids(pidx+1:end) = 0;
                this.bids(pidx) = bb(cols.value);
                this.bestbid=bb(cols.price);
              end
            end
            if any(bestaskidx)
              id = find(bestaskidx,1,'last');
              ba = buffer(id,:);
              pidx = round(ba(cols.price)/this.ticksize);
              if pidx>1
                this.asks(1:pidx-1) = 0;
                this.asks(pidx) = -ba(cols.value);
                this.bestask=ba(cols.price);
              end
            end
          end
        end
      end
      
    %% SIGNAL GENERATION  
      function signal = InitSignalVariables(this,signal)
        quotes = this.Main.quotes;
        signal.positions.npos=0;
        poslen = 250000;
        signal.positions.opentime=zeros(poslen,1);
        signal.positions.closetime=zeros(poslen,1);
        signal.positions.delta=zeros(poslen,1);
        signal.positions.equity=zeros(poslen,1);
        signal.positions.long=zeros(poslen,1);
        signal.positions.short=zeros(poslen,1);
        signal.positions.points=zeros(poslen,1);
        signal.positions.result=zeros(poslen,1);
        signal.positions.return=zeros(poslen,1);
        
        signal.gamma=zeros(size(quotes.rlog(this.n,:)));
        signal.gammadir=zeros(size(quotes.rlog(this.n,:)));
        signal.delta=zeros(size(quotes.rlog(this.n,:)));
        signal.capacity=zeros(size(quotes.rlog(this.n,:)));
        signal.rlog=zeros(size(quotes.rlog(this.n,:)));
        signal.slippage=zeros(size(quotes.rlog(this.n,:)));
        signal.cost=zeros(size(quotes.rlog(this.n,:)));
        signal.rlogaccum=zeros(size(quotes.rlog(this.n,:)));
        signal.gammaaccum=zeros(size(quotes.rlog(this.n,:)));
        signal.slippageaccum=zeros(size(quotes.rlog(this.n,:)));
        signal.costaccum=zeros(size(quotes.rlog(this.n,:)));
        signal.rlognetaccum=zeros(size(quotes.rlog(this.n,:)));
        signal.rlogaccummax=zeros(size(quotes.rlog(this.n,:)));
        signal.rlogunderwater=zeros(size(quotes.rlog(this.n,:)));
        signal.lastbar = 2;
      end
      function signal = NewTradedateSignalVariables(this,signal)
        quotes = this.Main.quotes;
        nquotes = size(quotes.close,2);
        nsig = size(signal.gamma,2);
        if nquotes > nsig
          signal.gamma(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.gammadir(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.delta(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.capacity(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.rlog(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.slippage(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.cost(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.rlogaccum(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.slippageaccum(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.costaccum(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.rlognetaccum(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.rlogaccummax(nsig+1:nquotes)=zeros(nquotes-nsig,1);
          signal.rlogunderwater(nsig+1:nquotes)=zeros(nquotes-nsig,1);
        end
      end
      function CalculateSignals(this)
        for s=1:length(this.signals)
          this.signals(s)=...
            this.signals(s).function(this,this.signals(s));
        end
      end
     
    %% UTILS
      function priceout = RoundPrice(this,pricein)
        priceout = round(pricein./this.ticksize).*this.ticksize;
      end
      
    end
end