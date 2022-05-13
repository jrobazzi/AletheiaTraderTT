function signal = Signal_LongFlyLimitSpread(symbol,signal)
  if ~signal.init
    signal=InitSignal(symbol,signal);
    signal.init = true;
  end
  quotes = symbol.Main.quotes;
  n = symbol.n;
  fb=quotes.firstbar(end);
  ob=quotes.openbar(n,end);
  lb=quotes.lastbar(n,end);
  nquotes = size(quotes.time,2);
  nsig = size(signal.gamma,2);
  if nsig<nquotes
    signal = NewTradedateSignalVariables(symbol,signal);
  end
  d = length(quotes.tradedates);
  mindeltaerror = 0.05;
  init =false;
  if length(symbol.filters.deltarefinit)<d
    init = true;
  else
    if ~symbol.filters.deltarefinit(d)
      init = true;
    end
  end
  %-----------------------------FILTER INIT-------------------------------
  if ob~=0 && init && d>=100
      openp = symbol.Main.quotes.close(n,ob);
      px = [1:20000].*symbol.ticksize;
      rlog = log(px/openp);
      s = exp(rlog);
      deltaref = zeros(size(rlog));
      fstob = quotes.openbar(n,d-99);
      window = fstob:length(quotes.rlogintraday(n,:));
      [mu,sig]=normfit(quotes.rlogintraday(n,window));
      [atmcall,atmput] = blsprice(s,1,0,1,sig);
      [itmcall,otmput] = blsprice(s,1+4*sig,0,1,sig);
      [otmcall,itmput] = blsprice(s,1-4*sig,0,1,sig);
      shortfly = itmcall-2.*atmcall+otmcall;
      deltaref = [diff(shortfly),0];
      deltaref = deltaref./max(deltaref);
      symbol.filters.deltaref = deltaref;
      symbol.filters.deltarefinit(d) = true;
  elseif length(symbol.filters.deltarefinit)<d
    symbol.filters.deltaref = zeros(size([1:20000]));
  end
  %-----------------------------------------------------------------------
  closepositionid = ob + round((0.333333333333333-quotes.dt)/quotes.dt);
  %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------GAMMA---------------------------------
      lstp = quotes.close(n,t);
      if d>=100 && t>ob+4 && t<=closepositionid
        rlogid = round(lstp/symbol.ticksize);
        dref = symbol.filters.deltaref(rlogid);
        derr = dref-signal.delta(t-1);
        if abs(derr)>=mindeltaerror
          signal.gamma(t) = derr;
        end
      else
        signal.gamma(t) = 0 - signal.delta(t-1);
      end
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
      if signal.delta(t-1)~=0
        gammadir = signal.delta(t-1)*signal.gamma(t);
        if  gammadir > 0
          signal.gammadir(t) = 1;
        elseif gammadir < 0
          signal.gammadir(t) = -1;
        end
      elseif signal.gamma(t)~=0
        signal.gammadir(t) = 1;
      end
      signal.delta(t) = signal.delta(t-1) + signal.gamma(t);
      signal.rlog(t) = quotes.rlog(n,t)*signal.delta(t-1);
      signal.rlogaccum(t) = signal.rlogaccum(t-1)+signal.rlog(t);
      signal.rlogaccummax(t) = ...
        max(signal.rlogaccum(t),signal.rlogaccummax(t-1));
      signal.rlogunderwater(t)=signal.rlogaccum(t)-signal.rlogaccummax(t);
      %------------------------------------------------------------------
      signal.lastbar = t;
    end
    

end
function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  symbol.filters.deltarefinit = false(size(quotes.tradedates));
  mindeltaerror = 0.05;
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(symbol.n,d);
    lb=quotes.lastbar(symbol.n,d);
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %-----------------------------HISTORY---------------------------------
    if d>=100
      fstob = quotes.openbar(n,d-99);
      window = fstob:ob;
      lastp = quotes.close(n,ob);
      px = [1:20000].*symbol.ticksize;
      s = px./lastp;
      deltaref = zeros(size(s));
      [mu,sig]=normfit(quotes.rlogintraday(n,window));
      [atmcall,atmput] = blsprice(s,1,0,1,sig);
      [itmcall,otmput] = blsprice(s,1+4*sig,0,1,sig);
      [otmcall,itmput] = blsprice(s,1-4*sig,0,1,sig);
      shortfly = itmcall-2.*atmcall+otmcall;
      deltaref = [diff(shortfly),0];
      deltaref = deltaref./max(abs(deltaref));
    end
    %---------------------------------------------------------------------
    closepositionid = ob + round((0.333333333333333-quotes.dt)/quotes.dt);
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------GAMMA---------------------------------
      lstp = quotes.close(n,t);
      if d>=100 && t>ob+4 && t<=closepositionid
        rlogid = round(lstp/symbol.ticksize);
        dref = deltaref(rlogid);
        derr = dref-signal.delta(t-1);
        if abs(derr)>=mindeltaerror
          signal.gamma(t) = derr;
        end
      else
        signal.gamma(t) = 0 - signal.delta(t-1);
      end
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
      if signal.delta(t-1)~=0
        gammadir = signal.delta(t-1)*signal.gamma(t);
        if  gammadir > 0
          signal.gammadir(t) = 1;
        elseif gammadir < 0
          signal.gammadir(t) = -1;
        end
      elseif signal.gamma(t)~=0
        signal.gammadir(t) = 1;
      end
      signal.delta(t) = signal.delta(t-1) + signal.gamma(t);
      signal.rlog(t) = quotes.rlog(n,t)*signal.delta(t-1);
      signal.rlogaccum(t) = signal.rlogaccum(t-1)+signal.rlog(t);
      signal.rlogaccummax(t) = ...
        max(signal.rlogaccum(t),signal.rlogaccummax(t-1));
      signal.rlogunderwater(t)=signal.rlogaccum(t)-signal.rlogaccummax(t);
      %------------------------------------------------------------------
    end
    signal.lastbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
end
