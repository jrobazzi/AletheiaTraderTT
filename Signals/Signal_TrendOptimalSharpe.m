function signal = Signal_TrendOptimalSharpe(symbol,signal)
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
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  tautrendmax = 0.000001;
  tautrendmin = 0.0000000001;
  fun = @(tautrend)...
    OptmizeSharpe(symbol,1,length(quotes.tradedates),tautrend);
  options = optimset('Display','iter','TolX',10^-9);
  [x,fval,exitflag,output] = fminbnd(fun,tautrendmin,tautrendmax,options)
  output.message
  %[x,fval,exitflag,output] = fmincon(fun,tautrend0,-1,0)
  %}
  %{
  tautrend = 0.02;
  sigtrend = ones(length(quotes.tradedates),1)*0.005;
  trendavg = zeros(size(quotes.rlog(n,:)));
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %-----------------------------HISTORY---------------------------------
    if d>=100
      windowsample = 540*100;
      window = fb-windowsample:fb;
      [counts,centers]=...
        hist(quotes.rlogintraday(n,window)-trendavg(window),100);
      counts = counts/sum(counts);
      cumdistfunc = cumsum(counts);
      sigtrend(d) = abs(centers(find(cumdistfunc>0.005,1,'first')));
      sigtrend(d) = max(sigtrend(d),...
        abs(centers(find(cumdistfunc>0.995,1,'first'))));
    end
    %---------------------------------------------------------------------
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------FILTER---------------------------------
      if t==ob
        trendavg(t)=0;
      elseif quotes.volume(n,t)~=0
        trendavg(t)=...
          trendavg(t-1)*(1-tautrend)+...
          quotes.rlogintraday(n,t)*(tautrend);
      else
        trendavg(t)=trendavg(t-1);
      end
      dist=(quotes.rlogintraday(n,t)-trendavg(t))/sigtrend(d);
      %-------------------------------------------------------------------
      %-----------------------------GAMMA---------------------------------
      if lb-t>40 && d>=100
        if quotes.rlogintraday(n,t) > trendavg(t)+sigtrend(d)
          signal.gamma(t) = -1 - signal.delta(t-1);
        elseif quotes.rlogintraday(n,t) < trendavg(t)-sigtrend(d)
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
    signal.lastbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
  %}
end

function cost = OptmizeSharpe(symbol,firstdate,enddate,tautrend)
  %INIT VARIABLES
  
  quotes = symbol.Main.quotes;
  n = symbol.n;
  sys = tf(tautrend,[1 tautrend]);
  sysd = c2d(sys,15,'tustin');
  set(sysd,'variable','z^-1');
  b = cell2mat(sysd.num);
  a = cell2mat(sysd.den);
  trend = filter(b,a,quotes.rlogaccum(n,:),quotes.rlogaccum(n,1));
  resid = (quotes.rlogaccum(n,:)-trend);
  [mu,sig] = normfit(resid);
  
  k = resid./(1*sig);
  k(k>1) = 1;
  k(k<-1) = -1;
  k(resid>0)=1;
  k(resid<0)=-1;
  logret = quotes.rlog(n,:).*[0,k(1:end-1)];
  logretaccum = cumsum(logret);
  mu_ = mean(logret);
  muret = ([1:length(logret)].*mu_);
  sigret = logretaccum-muret;
  [dummy,sig_] = normfit(sigret);
  refcost = mu_/sig_;
  cost = 1/refcost;
  if cost<0
    cost=-cost;
  end
  %cost = abs(0.025 - sig);
  
  fprintf('cost:%f,tau:%f\n',cost,tautrend);
  figure(1)
  t = quotes.time;
  plot(t,trend)
  hold on
  plot(t,trend+2*sig);
  plot(t,trend-2*sig);
  plot(t,quotes.rlogaccum(n,:));
  plot(t,logretaccum);
  plot(t,muret);
  hold off
  datetick('x')
  figure(2)
  hist(resid,20);
  figure(3)
  hist(sigret)
  figure(4)
  hist(k,20)
 	drawnow
end

%{
function cost = OptmizeSharpe(symbol,firstdate,enddate,tautrend)
  %INIT VARIABLES
  %tautrend
  quotes = symbol.Main.quotes;
  n = symbol.n;
  
 	fb=quotes.firstbar(firstdate);
  trendavg = zeros(size(quotes.rlog(n,:)));
  trendavg(fb) = quotes.rlogaccum(n,fb);
  
  lstbar=2;
  gamma = zeros(size(quotes.rlog(n,:)));
  gammadir = zeros(size(quotes.rlog(n,:)));
  delta = zeros(size(quotes.rlog(n,:)));
  rlog = zeros(size(quotes.rlog(n,:)));
  rlogaccum = zeros(size(quotes.rlog(n,:)));
  rlogaccummax = zeros(size(quotes.rlog(n,:)));
  rlogunderwater = zeros(size(quotes.rlog(n,:)));
  
  qfirstbar = quotes.firstbar;
  qopenbar = quotes.openbar;
  qlastbar = quotes.lastbar;
  qrlogaccum = quotes.rlogaccum(n,:);
  qrlog = quotes.rlog(n,:);
  %% TRADEDATES LOOP
  for d=firstdate:enddate
    fb=qfirstbar(d);
    ob=qopenbar(n,d);
    lb=qlastbar(n,d);
    %% INTRADAY LOOP
    for t=lstbar:lb
      %-----------------------------FILTER---------------------------------
      trendavg(t)= ...
        trendavg(t-1)*(1-tautrend)+qrlogaccum(t)*(tautrend);
      %-------------------------------------------------------------------
      %-----------------------------GAMMA---------------------------------
      if qrlogaccum(t) > trendavg(t)
        gamma(t) = 1 - delta(t-1);
      elseif qrlogaccum(t) < trendavg(t)
        gamma(t) = -1 - delta(t-1);
      end
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
      if delta(t-1)~=0
        tempgammadir = delta(t-1)*gamma(t);
        if  tempgammadir > 0
          gammadir(t) = 1;
        elseif tempgammadir < 0
          gammadir(t) = -1;
        end
      elseif gamma(t)~=0
        gammadir(t) = 1;
      end
      delta(t) = delta(t-1) + gamma(t);
      rlog(t) = qrlog(t)*delta(t-1);
      rlogaccum(t) = rlogaccum(t-1)+rlog(t);
      rlogaccummax(t) = ...
        max(rlogaccum(t),rlogaccummax(t-1));
      rlogunderwater(t)=rlogaccum(t)-rlogaccummax(t);
      %------------------------------------------------------------------
    end
    lstbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  dret = exp(rlogaccum(lbs)-rlogaccum(fbs))-1;
  dretunderwater = exp(rlogunderwater(lbs))-1;
  shrp = sharpe(exp(rlogaccum)-1,0);
  maxdrawdown = min(exp(rlogunderwater)-1);
  %{
  if shrp>0
    cost = 1/shrp;
  else
    cost = abs(shrp);
  end
  %}
  [mu,sig] = normfit(qrlogaccum-trendavg);
  figure(2)
  hist(qrlogaccum-trendavg);
  cost = 0.1-sig;
  figure(1)
  plot(qrlogaccum)
  hold on
  plot(trendavg)
  plot(rlogaccum)
  plot(trendavg+sig)
  plot(trendavg-sig)
  hold off
  pause(0.001);
end
%}