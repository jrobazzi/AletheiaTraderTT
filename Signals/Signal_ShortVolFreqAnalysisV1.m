function signal = Signal_ShortVolFreqAnalysis(symbol,signal)
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
  nfilt = size(symbol.filters.reversionavg,2);
  if nfilt<nquotes
    sizediff = nquotes-nfilt;
    symbol.filters.reversionavg(end+1:end+sizediff) = zeros(1,sizediff);
  end
  if ndays>=100 && size(symbol.filters.sigreversion,1)<ndays &&...
      quotes.openbar(n,end)~=0
    windowsample = 540*100;
    window = fb-windowsample:fb;
    [counts,centers]= hist(quotes.rlogintraday(n,window)...
      -symbol.filters.reversionavg(window),100);
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
      symbol.filters.reversionavg(t)=0;
    elseif quotes.volume(n,t)~=0
      symbol.filters.reversionavg(t)=...
        symbol.filters.reversionavg(t-1)*(1-taureversion)+...
        quotes.rlogintraday(n,t)*(taureversion);
    else
      symbol.filters.reversionavg(t)=symbol.filters.reversionavg(t-1);
    end
    symbol.filters.reversionupprpx(t) = quotes.close(n,ob)*...
      exp(symbol.filters.reversionavg(t)+...
          symbol.filters.sigreversion(ndays));
    symbol.filters.reversionlowrpx(t) = quotes.close(n,ob)*...
      exp(symbol.filters.reversionavg(t) -...
          symbol.filters.sigreversion(ndays));
    symbol.filters.reversionavgpx(t) = ...
      quotes.close(n,ob)*exp(symbol.filters.reversionavg(t));
    dist=(quotes.rlogintraday(n,t)-symbol.filters.reversionavg(t))/...
      symbol.filters.sigreversion(ndays);
    %-------------------------------------------------------------------
    %-----------------------------GAMMA---------------------------------
    if t-ob>10 && ndays>=100
      if quotes.rlogintraday(n,t) > symbol.filters.reversionavg(t)+...
          symbol.filters.sigreversion(ndays)
        signal.gamma(t) = -1 - signal.delta(t-1);
      elseif quotes.rlogintraday(n,t) < symbol.filters.reversionavg(t)-...
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
  ndays = 100;
  tauMA = [27000,10800,8100,5400,500,400,300,200,100,50,40,30,20,10,5];
  ts = 15;
  nfreq = length(tauMA);
  taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
  sigreversion = ones(length(quotes.tradedates),nfreq)*0.005;
  opttau = ones(length(quotes.tradedates),1)*length(taureversion);
  reversionavg = zeros(size(quotes.rlog(n,:),2),nfreq);
  reversionresid = zeros(size(quotes.rlog(n,:),2),nfreq);
  reversiondist = zeros(size(quotes.rlog(n,:),2),nfreq);
  upprbreakout = false(size(quotes.rlog(n,:),2),nfreq);
  lowrbreakout = false(size(quotes.rlog(n,:),2),nfreq);
  gamma = zeros(size(quotes.rlog(n,:),2),nfreq);
  gammaaccum = zeros(size(quotes.rlog(n,:),2),nfreq);
  breakevencost = zeros(size(quotes.rlog(n,:),2),nfreq);
  cost = zeros(size(quotes.rlog(n,:),2),nfreq);
  slip = zeros(size(quotes.rlog(n,:),2),nfreq);
  delta = zeros(size(quotes.rlog(n,:),2),nfreq);
  rlog = zeros(size(quotes.rlog(n,:),2),nfreq);
  rlogaccum = zeros(size(quotes.rlog(n,:),2),nfreq);
  rlognet = zeros(size(quotes.rlog(n,:),2),nfreq);
  
  %% TRADEDATES LOOP
  tdot = tic;
  figure(2)
  cla
  hold on
  figure(3)
  cla
  hold on
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
    if d>=ndays
      wfb=quotes.firstbar(d-ndays+1);
      window = wfb:fb-1;
      for nf=1:nfreq
        [counts,centers]=hist(reversionresid(window,nf),100);
        counts = counts/sum(counts);
        cumdistfunc = cumsum(counts);
        sigreversion(d,nf) = abs(centers(find(cumdistfunc>0.005,1,'first')));
        sigreversion(d,nf) = max(sigreversion(d,nf),...
          abs(centers(find(cumdistfunc>0.995,1,'first'))));
      end
      
      windowret = rlognet(fb-1,:)-rlognet(wfb,:);
      shrp = sharpe(cumsum(rlog(window,:)),0);
      if all(~isnan(shrp))
        %opttau(d) = find(shrp==max(shrp),1,'last');
      end
      opttau(d) = find(windowret==max(windowret),1,'last');
      figure(2)
      plot(taureversion,sigreversion(d,:))
      drawnow
      figure(3)
      plot(d,sigreversion(d,:),'k*');
      drawnow
      figure(4)
      plot(taureversion,windowret);
      figure(5)
      plot(window,rlognet(window,:));
      figure(7) 
      plot(1:d,taureversion(opttau(1:d)));
      %}
      figure(8)
      plot(taureversion,shrp);
      figure(9)
      plot(taureversion,cost(signal.lastbar-1,:),'b');
      hold on
      plot(taureversion,slip(signal.lastbar-1,:),'k');
      hold off
      figure(6)
      plot(taureversion,breakevencost(signal.lastbar-1,:),'b');
      drawnow
    end
    %}
    %---------------------------------------------------------------------
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      %-----------------------------FILTER---------------------------------
      if t>=fb && t<=ob
        reversionavg(t,:)=reversionavg(t-1,:);
      elseif quotes.volume(n,t)~=0
        reversionavg(t,:)=...
          reversionavg(t-1,:).*(1-taureversion)+...
          quotes.rlogaccum(n,t).*(taureversion);
          %quotes.rlogintraday(n,t).*(taureversion);
      else
        reversionavg(t,:)=reversionavg(t-1,:);
      end
      %reversionresid(t,:)=(quotes.rlogintraday(n,t)-reversionavg(t,:));
      reversionresid(t,:)=(quotes.rlogaccum(n,t)-reversionavg(t,:));
      reversiondist(t,:) = reversionresid(t,:)./sigreversion(d,:);
      upprbreakout(t,:) = ...
          quotes.rlogaccum(n,t) > reversionavg(t,:)+sigreversion(d,:);
      lowrbreakout(t,:) = ...
        quotes.rlogaccum(n,t) < reversionavg(t,:)-sigreversion(d,:);
      %-------------------------------------------------------------------
      %-----------------------------GAMMA---------------------------------
      if t-ob>10 && lb-t>40 && d>=ndays
        
        if any(upprbreakout(t,:))
          gamma(t,upprbreakout(t,:)) = -1 - delta(t-1,upprbreakout(t,:));
        end
        if any(lowrbreakout(t,:))
          gamma(t,lowrbreakout(t,:)) = 1 - delta(t-1,lowrbreakout(t,:));
        end
        longidx = delta(t-1,:)>0;
        exitidx = ...
          longidx & ~lowrbreakout(t,:) & abs(reversiondist(t,:))<0.9;
        if any(exitidx)
          gamma(t,exitidx) = ...
           min(delta(t-1,exitidx),max(0,-reversiondist(t,exitidx))) ...
           - delta(t-1,exitidx);
        end
        shortidx = delta(t-1,:)<0;
        exitidx = ...
          shortidx & ~upprbreakout(t,:) & abs(reversiondist(t,:))<0.9;
        if any(exitidx)
          gamma(t,exitidx) = ...
            max(delta(t-1,exitidx),min(0,-reversiondist(t,exitidx)))...
            - delta(t-1,exitidx);
        end
        %{
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
        %}
      else
        %gamma(t,:) = 0 - delta(t-1,:);
        %signal.gamma(t) = 0 - signal.delta(t-1);
      end
        
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
      
      gammaaccum(t,:) = gammaaccum(t-1,:) + abs(gamma(t,:));
      %cost(t,:) = cost(t-1,:) + abs(gamma(t,:)).*tob;
      %slip(t,:) = slip(t-1,:) + abs(gamma(t,:)).*slp;
      delta(t,:) = delta(t-1,:) + gamma(t,:);
      rlog(t,:) = quotes.rlog(n,t)*delta(t-1,:);
      rlogaccum(t,:) = rlogaccum(t-1,:)+rlog(t,:);
      rlognet(t,:) = rlogaccum(t,:)-cost(t,:)-slip(t,:);
      nzidx = gammaaccum(t,:)~=0;
      breakevencost(t,nzidx) = rlogaccum(t,nzidx)./gammaaccum(t,nzidx);
      breakevencost(t,:) = max(breakevencost(t,:),0);
      %{
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
      %}
    end
    end
    if d>=ndays
      figure(1)
      cla
      t=quotes.time(fb:lb);
      ax1 = subplot(2,1,1);
      plot(t,quotes.rlogaccum(fb:lb),'k')
      hold on
      plot(t,reversionavg(fb:lb,:),'g')
      hold off
      datetick('x')
      ax2= subplot(2,1,2);
      plot(t,delta(fb:lb,:))
      linkaxes([ax1 ax2],'x');
      drawnow
    end
  
    %}
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