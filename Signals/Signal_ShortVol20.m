function signal = Signal_ShortVol20(symbol,signal)
  if ~signal.init
    signal=InitSignal(symbol,signal);
    signal.init = true;
  end
  quotes = symbol.Main.quotes;
  n=symbol.n;
  d=length(quotes.tradedates);
  fb=quotes.firstbar(d);
  lb=quotes.lastbar(symbol.n,d);
  ob=quotes.openbar(symbol.n,d);
  
  %}
end
function signal = InitSignal(symbol,signal)
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal.delta=zeros(size(quotes.rlog(n,:)));
  signal.rlog=zeros(size(quotes.rlog(n,:)));
  signal.rlogaccum=zeros(size(quotes.rlog(n,:)));
  signal.lastbar = 1;
  taureversion = 0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.005;
  signal.lastbar=1;
  reversionavg=zeros(size(quotes.rlog(n,:)));
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(symbol.n,d);
    lb=quotes.lastbar(symbol.n,d);
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    if d>=20
      windowsample = 540*20;
      window = fb-windowsample:fb;
      [counts,centers]=...
        hist(quotes.rlogintraday(n,window)-reversionavg(window),100);
      counts = counts/sum(counts);
      cumdistfunc = cumsum(counts);
      sigreversion(d) = abs(centers(find(cumdistfunc>0.005,1,'first')));
      sigreversion(d) = max(sigreversion(d),...
        abs(centers(find(cumdistfunc>0.995,1,'first'))));
    end
    for t=signal.lastbar:lb
      if t>1
        signal.rlog(t) = quotes.rlog(n,t)*signal.delta(t-1);
        signal.rlogaccum(t) = signal.rlogaccum(t-1)+signal.rlog(t);
        lstp = quotes.close(symbol.n,t);
        maxp = quotes.max(symbol.n,t);
        minp = quotes.min(symbol.n,t);
        if fb>1
          closeret = log(lstp/quotes.close(symbol.n,fb-1));
        else
          closeret = log(lstp/quotes.close(symbol.n,fb));
        end
        if t==ob
          reversionavg(t)=0;
        elseif quotes.volume(n,t)~=0
          reversionavg(t)=...
            reversionavg(t-1)*(1-taureversion)+...
            quotes.rlogintraday(n,t)*(taureversion);
        else
          reversionavg(t)=reversionavg(t-1);
        end
        if d>=100
        %delta active management
        if (signal.delta(t-1)>0 && ...
            quotes.rlogintraday(n,t)<=reversionavg(t)) ||...
            (signal.delta(t-1)<0 && ...
            quotes.rlogintraday(n,t)>=reversionavg(t))
          signal.delta(t) = 0;
        elseif quotes.rlogintraday(n,t) > reversionavg(t)+sigreversion(d)
          signal.delta(t) = -1;
        elseif quotes.rlogintraday(n,t) < reversionavg(t)-sigreversion(d)
          signal.delta(t) = 1;
        else
          signal.delta(t) = signal.delta(t-1);
        end
        end
      end
      signal.lastbar = t;
    end
  end
  symbol.filters.reversionavg20 = reversionavg;
  symbol.filters.sigreversion20 = sigreversion;
end
