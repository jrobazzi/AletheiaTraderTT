function signal = Signal_ShortVolFreqAnalysisFmin(symbol,signal)
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
  %-----------------------------FILTER INIT------------------------------- 
  taureversion = 0.02;
  ndays = size(quotes.tradedates,2);
  nfilt = size(symbol.filters.dynreversionavg,2);
  if nfilt<nquotes
    sizediff = nquotes-nfilt;
    symbol.filters.dyndynreversionavg(end+1:end+sizediff) = zeros(1,sizediff);
  end
  if ndays>=100 && size(symbol.filters.sigreversion,1)<ndays &&...
      quotes.openbar(n,end)~=0
    windowsample = 540*100;
    window = fb-windowsample:fb;
    [counts,centers]= hist(quotes.rlogintraday(n,window)...
      -symbol.filters.dyndynreversionavg(window),100);
    counts = counts/sum(counts);
    cumdistfunc = cumsum(counts);
    symbol.filters.sigreversion(ndays) =...
      abs(centers(find(cumdistfunc>0.005,1,'first')));
    symbol.filters.sigreversion(ndays) = ...
      max(symbol.filters.sigreversion(ndays),...
      abs(centers(find(cumdistfunc>0.995,1,'first'))));
  end
  
  %----------------------------------------------------------------------- 
  for t=signal.lastbar+1:lb
    %-----------------------------FILTER---------------------------------  
    if t==ob
      symbol.filters.dyndynreversionavg(t)=0;
    elseif quotes.volume(n,t)~=0
      symbol.filters.dyndynreversionavg(t)=...
        symbol.filters.dyndynreversionavg(t-1)*(1-taureversion)+...
        quotes.rlogintraday(n,t)*(taureversion);
    else
      symbol.filters.dynreversionavg(t)=symbol.filters.dynreversionavg(t-1);
    end
    symbol.filters.reversionupprpx(t) = quotes.close(n,ob)*...
      exp(symbol.filters.dynreversionavg(t)+...
          symbol.filters.sigreversion(ndays));
    symbol.filters.reversionlowrpx(t) = quotes.close(n,ob)*...
      exp(symbol.filters.dynreversionavg(t) -...
          symbol.filters.sigreversion(ndays));
    symbol.filters.dynreversionavgpx(t) = ...
      quotes.close(n,ob)*exp(symbol.filters.dynreversionavg(t));
    dist=(quotes.rlogintraday(n,t)-symbol.filters.dynreversionavg(t))/...
      symbol.filters.sigreversion(ndays);
    %-------------------------------------------------------------------
    %-----------------------------GAMMA---------------------------------
    if t-ob>10 && ndays>=100
      if quotes.rlogintraday(n,t) > symbol.filters.dynreversionavg(t)+...
          symbol.filters.sigreversion(ndays)
        signal.gamma(t) = -1 - signal.delta(t-1);
      elseif quotes.rlogintraday(n,t) < symbol.filters.dynreversionavg(t)-...
          symbol.filters.sigreversion(ndays)
        signal.gamma(t) = 1 - signal.delta(t-1);
      elseif signal.delta(t-1)>0
        if dist>0
          signal.gamma(t) = 0 - signal.delta(t-1);
        elseif abs(dist)<0.9
            deltaref = min(signal.delta(t-1),abs(dist));
            signal.gamma(t) = deltaref - signal.delta(t-1);
        end
      elseif signal.delta(t-1)<0
        if dist<0
          signal.gamma(t) = 0 - signal.delta(t-1);
        elseif abs(dist)<0.9
            deltaref = max(signal.delta(t-1),-abs(dist));
            signal.gamma(t) = deltaref - signal.delta(t-1);
        end
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
  %}
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  taureversion = ones(length(quotes.tradedates),1)*0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.005;
  sigreversion_ = ones(length(quotes.tradedates),1)*0.005;
  dynreversionavg = zeros(size(quotes.rlog(n,:)));
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if ob>0
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %-----------------------------HISTORY---------------------------------
    if d>=100
      windowsample = 540*100;
      window = fb-windowsample:fb;
      [counts,centers]=...
        hist(quotes.rlogintraday(n,window)-dynreversionavg(window),100);
      counts = counts/sum(counts);
      cumdistfunc = cumsum(counts);
      sigreversion(d) = abs(centers(find(cumdistfunc>0.005,1,'first')));
      sigreversion(d) = max(sigreversion(d),...
        abs(centers(find(cumdistfunc>0.995,1,'first'))));
      
      tautrendmax = 0.1;
      tautrendmin = 0.001;
      sigtarget = log((quotes.close(n,fb)+10)/quotes.close(n,fb));
      fun = @(tau)FrequencySyntonization(symbol,d,100,sigtarget,tau);
      options = optimset('Display','off','TolX',10^-8);
      [taureversion(d),fval,exitflag,output] =...
        fminbnd(fun,tautrendmin,tautrendmax,options);
      sigreversion(d) = symbol.filters.tunedsig;
      
      tauMA = -((2*pi*15^2)/3600).*(1./log(1-taureversion(1:d)));
      figure(1)
      plot(tauMA)
      figure(2)
      plot(sigreversion(1:d))
      drawnow
    end
    %---------------------------------------------------------------------
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------FILTER---------------------------------
      if t==ob
        dynreversionavg(t)=0;
      elseif quotes.volume(n,t)~=0
        dynreversionavg(t)=...
          dynreversionavg(t-1)*(1-taureversion(d))+...
          quotes.rlogintraday(n,t)*(taureversion(d));
      else
        dynreversionavg(t)=dynreversionavg(t-1);
      end
      dist=(quotes.rlogintraday(n,t)-dynreversionavg(t))/sigreversion(d);
      %-------------------------------------------------------------------
      %-----------------------------GAMMA---------------------------------
      if t-ob>10 && lb-t>40 && d>=100
        if quotes.rlogintraday(n,t) > dynreversionavg(t)+sigreversion(d)
          signal.gamma(t) = -1 - signal.delta(t-1);
        elseif quotes.rlogintraday(n,t) < dynreversionavg(t)-sigreversion(d)
          signal.gamma(t) = 1 - signal.delta(t-1);
        elseif signal.delta(t-1)>0
          if dist>0
            signal.gamma(t) = 0 - signal.delta(t-1);
          else
            if abs(dist)<0.9
              deltaref = min(signal.delta(t-1),abs(dist));
              signal.gamma(t) = deltaref - signal.delta(t-1);
            end
          end
        elseif signal.delta(t-1)<0
          if dist<0
            signal.gamma(t) = 0 - signal.delta(t-1);
          else
            if abs(dist)<0.9
              deltaref = max(signal.delta(t-1),-abs(dist));
              signal.gamma(t) = deltaref - signal.delta(t-1);
            end
          end
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
  %symbol.filters.sigreversion = sigreversion;
  symbol.filters.dynreversionavg = dynreversionavg;
end

function cost = FrequencySyntonization(symbol,d,ndays,sigt,tau)
  quotes = symbol.Main.quotes;
  n = symbol.n;
  lb = quotes.lastbar(n,d-1);
  fb = quotes.lastbar(n,d-ndays+1);
  filt = zeros(size(quotes.rlogaccum(n,:)));
  filt(fb)=quotes.rlogaccum(n,fb);
  for t=fb+1:lb
    filt(t) = filt(t-1)*(1-tau) + quotes.rlogaccum(n,t)*tau;
  end
  resid = quotes.rlogaccum(n,fb:lb) - filt(fb:lb);
  [counts,centers]= hist(resid,100);
  counts = counts/sum(counts);
  cumdistfunc = cumsum(counts);
  sig = abs(centers(find(cumdistfunc>0.005,1,'first')));
  sig = max(sig,abs(centers(find(cumdistfunc>0.995,1,'first'))));
  cost = abs(sigt-sig);
  symbol.filters.tunedsig = sig;
end