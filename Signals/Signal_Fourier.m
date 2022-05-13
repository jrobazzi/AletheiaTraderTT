function signal = Signal_Fourier(symbol,signal)
  if ~signal.init
    signal=InitSignal(symbol,signal);
    signal.init = true;
  end
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  ndays = 100;
  tauMA = [500,400,300,200,100,50,40,30,20,10,5];
  ts = 15;
  nfreq = length(tauMA);
  taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
  MA = zeros(size(quotes.rlog(n,:),2),nfreq);
  MA(1,:)=quotes.close(n,1);
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
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        %-----------------------------FILTER---------------------------------
        if t>=fb && t<=ob
          MA(t,:)=quotes.close(n,t);
        elseif quotes.volume(t)~=0
          MA(t,:) = MA(t-1,:).*(1-taureversion)+...
            quotes.close(n,t).*(taureversion);
        else
          MA(t,:) = MA(t-1,:);
        end
        %-------------------------------------------------------------------
      end
      figure(1)
      plot(quotes.bestbid(n,fb:lb))
      hold on
      plot(MA(fb:lb,:))
      hold off
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
  symbol.filters.sigreversion = sigreversion;
  symbol.filters.reversionavg = reversionavg;
end

%{
function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  taureversion = 0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.005;
  reversionavg = zeros(size(quotes.rlog(n,:)));
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
        hist(quotes.rlogintraday(n,window)-reversionavg(window),100);
      counts = counts/sum(counts);
      cumdistfunc = cumsum(counts);
      sigreversion(d) = abs(centers(find(cumdistfunc>0.005,1,'first')));
      sigreversion(d) = max(sigreversion(d),...
        abs(centers(find(cumdistfunc>0.995,1,'first'))));
    end
    %---------------------------------------------------------------------
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------FILTER---------------------------------
      if t==ob
        reversionavg(t)=0;
      elseif quotes.volume(n,t)~=0
        reversionavg(t)=...
          reversionavg(t-1)*(1-taureversion)+...
          quotes.rlogintraday(n,t)*(taureversion);
      else
        reversionavg(t)=reversionavg(t-1);
      end
      dist=(quotes.rlogintraday(n,t)-reversionavg(t))/sigreversion(d);
      %-------------------------------------------------------------------
      %-----------------------------GAMMA---------------------------------
      if t-ob>10 && lb-t>40 && d>=100
        if quotes.rlogintraday(n,t) > reversionavg(t)+sigreversion(d)
          signal.gamma(t) = -1 - signal.delta(t-1);
        elseif quotes.rlogintraday(n,t) < reversionavg(t)-sigreversion(d)
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
  symbol.filters.sigreversion = sigreversion;
  symbol.filters.reversionavg = reversionavg;
end
%}