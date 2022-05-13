classdef CIntraday < handle
  %CINTRADAY Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    host = 'BDKPTL03';
    nbars = 2000;
    period,pid,histdays,tradedates,ts
    intraday
  end
  
  methods
    function this = CIntraday()
      %select number of symbols
      query = 'select max(i_id) from dbconfig.symbols;';
      h = mysql( 'open', this.host,'traders', 'kapitalo' );
      nsymbols = mysql(query);
      mysql('close')
      %load tradedates
      query = 'select t_tradedate from dbconfig.tradedates;';
      h = mysql( 'open', this.host,'traders', 'kapitalo' );
      this.tradedates = mysql(query);
      mysql('close')
      %init periods
      this.intraday = cell(6,nsymbols);
      this.period(1)=1;
      this.period(2)=15;
      this.period(3)=60;
      this.period(4)=300;
      this.period(5)=1800;
      this.period(6)=3600;
      this.pid(1)=1;
      this.pid(15)=2;
      this.pid(60)=3;
      this.pid(300)=4;
      this.pid(1800)=5;
      this.pid(3600)=6;
      this.histdays = ceil(this.nbars./(32400./this.period));
      this.histdays(1)=0;
      this.Initialize();
    end
    
    function Initialize(this)
      for p=1:length(this.period)
        tic
        clear id;
        cp = this.period(p);
        cdate = find(this.tradedates>=fix(now),1,'first');
        idate = this.tradedates(cdate-this.histdays(p));
        query = sprintf(['select s.i_id,i.t_ts,i.p_time,i.d_open,i.d_close,',...
          'i.d_max,i.d_min,i.d_trades,i.d_volume,',...
          'i.d_avg,i.d_buyQty,i.d_buyAvg,i.d_sellQty,i.d_sellAvg ',...
          'from dbconfig.symbols s, dbmarketdata.intraday i ',...
          'where s.s_symbol=i.p_symbol ',...
          'and s.s_exchange=i.p_exchange ',...
          'and i.p_period=%i ',...
          'and i.p_tradedate>=''%s'' ',...
          'and s.x_logtrades=1 ',...
          'order by i.p_time;'],cp,datestr(idate,'yyyy-mm-dd hh:MM:ss'));
        h = mysql( 'open', this.host,'traders', 'kapitalo' );
        [symbolid,newts,id(:,1),id(:,2),id(:,3),id(:,4),id(:,5),id(:,6),id(:,7),...
          id(:,8),id(:,9),id(:,10),id(:,11),id(:,12)] = mysql(query);
        mysql('close')
        this.ts = max(newts);
        [C,IA,IC] = unique(symbolid);
        for i=1:length(C)
          this.intraday{p,C(i)} = nan(this.nbars,12);
          ids = find(IC==i);
          if length(ids)>this.nbars
            ids = ids(end-this.nbars+1:end);
          end
          nids = length(ids);
          this.intraday{p,C(i)}(end-nids+1:end,:) = id(ids,:); 
        end
        toc
      end
    end
    
    function Update(this)
      query = sprintf(['select s.i_id,i.t_ts,i.p_period,i.p_time,',...
        'i.d_open,i.d_close,i.d_max,i.d_min,i.d_trades,i.d_volume,',...
        'i.d_avg,i.d_buyQty,i.d_buyAvg,i.d_sellQty,i.d_sellAvg ',...
        'from dbconfig.symbols s, dbmarketdata.intraday i ',...
        'where s.s_symbol=i.p_symbol ',...
        'and s.s_exchange=i.p_exchange ',...
        'and i.p_period<>86400 ',...
        'and i.t_ts>=''%s'' ',...
        'and s.x_logtrades=1;'],datestr(this.ts,'yyyy-mm-dd hh:MM.ss'));
      [symbolid,newts,newp,id(:,1),id(:,2),id(:,3),id(:,4),id(:,5),id(:,6),...
        id(:,7),id(:,8),id(:,9),id(:,10),id(:,11),id(:,12)]=mysql(query);
      this.ts = max(this.ts,max(newts));
      for i=1:length(symbolid)
        cpid = this.pid(newp(i));
        if isempty(this.intraday{cpid,symbolid(i)})
          this.intraday{cpid,symbolid(i)} = nan(this.nbars,12);
        end
        if this.intraday{cpid,symbolid(i)}(end,1) == id(i,1)
          this.intraday{cpid,symbolid(i)}(end,:) = id(i,:);
        elseif this.intraday{cpid,symbolid(i)}(end,1) < id(i,1)
          this.intraday{cpid,symbolid(i)}(1:end-1,:) = ...
            this.intraday{cpid,symbolid(i)}(2:end,:);
          this.intraday{cpid,symbolid(i)}(end,:) = id(i,:);
        end
      end
    end
    
  end
  
end

