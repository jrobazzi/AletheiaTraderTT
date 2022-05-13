function signal = Signal_Filters(symbol,signal)
  quotes = symbol.Main.quotes;
  n = symbol.n;
  fb=quotes.firstbar(end);
  ob=quotes.openbar(n,end);
  lb=quotes.lastbar(n,end);
  if ob>0
  if ~signal.init
    signal=InitSignal(symbol,signal);
    signal.init = true;
  end
  
  if fb~=0 && ob~=0 && lb~=0
    nquotes = size(quotes.time,2);
    nsig = size(signal.gamma,2);
    if nsig<nquotes
      signal = NewTradedateSignalVariables(symbol,signal);
    end
    %-----------------------------FILTER INIT------------------------------- 
    tauMA = [20 60 120 270 540 720 1080];
    ts=15;
    taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
    %taureversion = 0.02;
    ndays = size(quotes.tradedates,2);
    nfilt = size(symbol.filters.reversionavgpx,1);
    if nfilt<nquotes
      sizediff = nquotes-nfilt;
      symbol.filters.reversionavgpx(end+1:end+sizediff) = zeros(1,sizediff);
      symbol.filters.reversionupprpx(end+1:end+sizediff) = zeros(1,sizediff);
      symbol.filters.reversionlowrpx(end+1:end+sizediff) = zeros(1,sizediff);
      symbol.filters.resid(end+1:end+sizediff,:) = ...
        zeros(sizediff,size(symbol.filters.resid,2));
      symbol.filters.avg(end+1:end+sizediff,:) = ...
        zeros(sizediff,size(symbol.filters.avg,2));
    end
    %----------------------------------------------------------------------- 
    for t=signal.lastbar+1:lb
      %-----------------------------FILTER---------------------------------  
      if quotes.volume(n,t)~=0
        symbol.filters.avg(t,:)=...
              symbol.filters.avg(t-1,:).*(1-taureversion)+...
              quotes.close(n,t).*(taureversion);
        symbol.filters.reversionavgpx(t)=symbol.filters.avg(t-1,end);
      else
        symbol.filters.avg(t,:)=symbol.filters.avg(t-1,:);
        symbol.filters.reversionavgpx(t)=symbol.filters.reversionavgpx(t-1);
      end
      symbol.filters.reversionupprpx(t) = ...
        symbol.filters.reversionavgpx(t,end)*(1+4*symbol.filters.sig(end,end));
      symbol.filters.reversionlowrpx(t) = ...
        symbol.filters.reversionavgpx(t,end)*(1-4*symbol.filters.sig(end,end));
      avgp=symbol.filters.reversionavgpx(t);
      symbol.filters.resid(t,end) = (quotes.close(n,t)-avgp)./avgp;
      %----------------------------------------------------------------------
      signal.lastbar = t;
    end
  end
  end
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  tauMA = [20 60 120 270 540 720 1080];
  bandDays = 30;
  ts = 15;
  nfreq = length(tauMA);
  taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
  %taureversion = 0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.007;
  reversionupprpx = zeros(size(quotes.rlog(n,:)));
  reversionlowrpx = zeros(size(quotes.rlog(n,:)));
  reversionavgpx = zeros(size(quotes.rlog(n,:),2),nfreq);
  reversionresid = zeros(size(quotes.rlog(n,:),2),nfreq);
  reversionresidUp = zeros(length(quotes.tradedates),nfreq);
  reversionresidDn = zeros(length(quotes.tradedates),nfreq);
  reversionupprpx(1) = quotes.close(n,1)*exp(sigreversion(1));
  reversionlowrpx(1) = quotes.close(n,1)*exp(-sigreversion(1));
  reversionavgpx(1,:) = quotes.close(n,1);
  sig = zeros(length(quotes.tradedates),nfreq);
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if fb~=0 && ob~=0 && lb~=0
      %remove roll return
      rollpoints = 0;
      if symbol.isserie
        currdate = quotes.tradedates(d);
        currdateidx = currdate == symbol.seriedates;
        if any(currdateidx)
          if symbol.serieroll(currdateidx)
            if ob>1
              rollpoints = quotes.close(n,ob)-quotes.close(n,ob-1);
            else
              rollpoints = 0;
            end
          end
        end
      end
      %
      if d>1
        h = 1/2;
        %figure(100);cla;
        for m = 1:nfreq
          lfb = fb-(tauMA(m)*4*30);
          if lfb<1
            lfb=1;
          end
          sig(d,m) = std(reversionresid(lfb:fb-1,m));
          if m==1
          %figure(1000+m);histfit(reversionresid(lfb:fb-1,m));
          %xlabel('Residual');ylabel('Frequency');title('PDF');
          end
          a(m) = sig(d,m)/(tauMA(m)^h);
          %figure(100);hold on; loglog(log(tauMA),log(a(m).*(tauMA.^h)));
        end
        %figure(100);hold on;
        %xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
        %loglog(log(tauMA),log(sig(d,:)),'k*');
        %loglog(log(tauMA),log(mean(a).*(tauMA.^h)),'k','LineWidth',1.5');
        %hold off;
        %drawnow;
      end
      %}
      if toc(tdot)>1
        tdot=tic;
        fprintf('.');
      end
      if d>bandDays+1
        bandinit = quotes.openbar(n,d-bandDays);
        if d>1
          reversionresidUp(d,:) = max(reversionresid(bandinit:t,:));
          reversionresidDn(d,:) = min(reversionresid(bandinit:t,:));
        else
          reversionresidUp(1,:) = 0.01;
          reversionresidDn(1,:) = -0.01;
        end
      else
        t=signal.lastbar;
        bandinit = quotes.openbar(n,1);
        reversionresidUp(d,:) = max(reversionresid(1:t,:));
        reversionresidDn(d,:) = min(reversionresid(1:t,:));
      end
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        %---------------------------FILTER-------------------------------
        if t==ob
          reversionavgpx(t,:)=rollpoints+...
            reversionavgpx(t-1,:).*(1-taureversion)+...
            quotes.close(n,t).*(taureversion);
        elseif quotes.volume(n,t)~=0
          reversionavgpx(t,:)=...
            reversionavgpx(t-1,:).*(1-taureversion)+...
            quotes.close(n,t).*(taureversion);
        else
          reversionavgpx(t,:)=reversionavgpx(t-1,:);
        end
        reversionupprpx(t) = reversionavgpx(t,end)*(1+4*sig(d,end));
        reversionlowrpx(t) = reversionavgpx(t,end)*(1-4*sig(d,end));
        %reversionresid(t,:) = (quotes.close(n,t)-reversionavgpx(t,:))...
        %  ./reversionavgpx(t,:);
        reversionresid(t,:) = (quotes.close(n,t)-reversionavgpx(t,:))...
          ./reversionavgpx(t,:);
        %-----------------------------------------------------------------
      end
      signal.lastbar = lb;
    end
  end
  if d>1
    h = 1/1.7;
    figure(100);cla;
    for m = 1:nfreq
      lfb = fb-(tauMA(m)*4*30);
      if lfb<1
        lfb=1;
      end
      sig(d,m) = std(reversionresid(lfb:fb-1,m));
      if m==1
      figure(1000+m);histfit(reversionresid(lfb:fb-1,m));
      xlabel('Residual');ylabel('Frequency');title('PDF');
      end
      a = sig(d,m)/(tauMA(m)^h);
      figure(100);hold on; loglog(tauMA,a.*(tauMA.^h));
    end
    figure(100);hold on;
    xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
    loglog(tauMA,sig(d,:),'k*');
    hold off;
    drawnow;
  end
  %{
  if d>1
    h = 1/1.7;
    %figure(100);cla;
    for m = 1:nfreq
      lfb = fb-(tauMA(m)*4*30);
      if lfb<1
        lfb=1;
      end
      sigPeriod(m) = std(reversionresid(1:signal.lastbar,m));
      if m==1
      figure(1000+m);histfit(reversionresid(1:signal.lastbar,m));
      xlabel('Residual');ylabel('Frequency');title('PDF');
      end
      a = sigPeriod(m)/(tauMA(m)^h);
      figure(100);hold on; plot(tauMA,a.*(tauMA.^h));
    end
    figure(100);hold on;
    xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
    plot(tauMA,sigPeriod(:),'k*');
    hold off;
    drawnow;
  end
  %}
  figure(500)
  plot(reversionresidUp(1:end,end));hold on
  plot(reversionresidDn(1:end,end));hold off
  figure(501)
  hist(reversionresidUp(1:end,end),30);hold on
  hist(reversionresidDn(1:end,end),30);hold off
  figure(502)
  ntd = length(quotes.tradedates);
  plot(1:ntd,sig(1:ntd,:));
  xlabel('Days');ylabel('Std Dev');title('Std Dev x Days');
  drawnow;
  %}
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
  %FILTERS
%  symbol.filters.reversionavg = reversionavg;
  symbol.filters.tau = tauMA;
  symbol.filters.sig = sig;
  symbol.filters.avg = reversionavgpx;
  symbol.filters.resid = reversionresid;
  symbol.filters.residUp = reversionresidUp;
  symbol.filters.residDn = reversionresidDn;
  symbol.filters.sigreversion = sigreversion;
  symbol.filters.reversionupprpx = reversionupprpx;
  symbol.filters.reversionlowrpx = reversionlowrpx;
  symbol.filters.reversionavgpx = reversionavgpx(:,end);
end

