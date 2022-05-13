function signal = Signal_Filters(symbol,signal)
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
  %}
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  tauMA = [540*10];
  ts = 15;
  nfreq = length(tauMA);
  taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
  %taureversion = 0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.007;
  reversionupprpx = zeros(size(quotes.rlog(n,:)));
  reversionlowrpx = zeros(size(quotes.rlog(n,:)));
  reversionresid = zeros(size(quotes.rlog(n,:)));
  reversionavgpx = zeros(size(quotes.rlog(n,:)));
  reversionupprpx(1) = quotes.close(n,1)*exp(sigreversion(1));
  reversionlowrpx(1) = quotes.close(n,1)*exp(-sigreversion(1));
  reversionavgpx(1) = quotes.close(n,1);
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    %remove roll return
    rollpoints = 0;
    if symbol.isserie
      currdate = quotes.tradedates(d);
      currdateidx = currdate == symbol.seriedates;
      if any(currdateidx)
        if symbol.serieroll(currdateidx)
          rollpoints = quotes.close(n,ob)-quotes.close(n,ob-1);
        end
      end
    end
    if ob~=0
      if toc(tdot)>1
        tdot=tic;
        fprintf('.');
      end
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        %---------------------------FILTER-------------------------------
        if t==ob
          reversionavgpx(t)=rollpoints+...
            reversionavgpx(t-1)*(1-taureversion)+...
            quotes.close(n,t)*(taureversion);
        elseif quotes.volume(n,t)~=0
          reversionavgpx(t)=...
            reversionavgpx(t-1)*(1-taureversion)+...
            quotes.close(n,t)*(taureversion);
        else
          reversionavgpx(t)=reversionavgpx(t-1);
        end
        reversionupprpx(t) = reversionavgpx(t)*1.01;
        reversionlowrpx(t) = reversionavgpx(t)*0.99;
        reversionresid(t) = (quotes.close(n,t)-reversionavgpx(t))...
          /reversionavgpx(t);
        %-----------------------------------------------------------------
      end
    end
    signal.lastbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
  %FILTERS
%  symbol.filters.reversionavg = reversionavg;
  symbol.filters.sigreversion = sigreversion;
  symbol.filters.reversionupprpx = reversionupprpx;
  symbol.filters.reversionlowrpx = reversionlowrpx;
  symbol.filters.reversionavgpx = reversionavgpx;
end

