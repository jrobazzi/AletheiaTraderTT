function signal = Signal_ChannelSizing(symbol,signal)
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
  tdot = tic;
  %% TRADEDATES LOOP
  voltermstruct=[];
  impProb=[];
  starttime = round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  figure(1)
  cla
  
  for d=1:length(quotes.tradedates)
    currdate = quotes.tradedates(d);
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %% ------------------------IMPLYIED VOL --------------------------------
  %INTEREST RATES 
  di1idx = strcmp(quotes.daily(d).s_market,'DI1');
  di1PU = quotes.daily(d).d_m2m(di1idx);
  di1Strikedate = quotes.daily(d).t_strikedate(di1idx);
  di1YieldDays = quotes.daily(d).d_yieldDays(di1idx);
  [di1Strikedate, didx] = sort(di1Strikedate);
  di1PU = di1PU(didx);
  di1YieldDays = di1YieldDays(didx);
  di1Rate = (100000./di1PU).^(252./di1YieldDays)-1;
  di1Rate = di1Rate.*100;
  di1Days = 1:max(di1YieldDays);
  di1Rate_ = spline(di1YieldDays,di1Rate,di1Days);
  di1hist(d,1) = currdate;
  di1hist(d,2) = di1Rate_(1);
  %USDBRL FUTURES
  dolidx = strcmp(quotes.daily(d).s_market,'DOL') & ...
    strcmp(quotes.daily(d).s_contractType,'FUT');
  dolM2m = quotes.daily(d).d_m2m(dolidx);
  dolStrikedate = quotes.daily(d).t_strikedate(dolidx);
  dolYieldDays = quotes.daily(d).d_yieldDays(dolidx);
  [dolStrikedate, didx] = sort(dolStrikedate);
  dolM2m = dolM2m(didx);
  dolFRA = diff(dolM2m)./dolM2m(1:end-1);
  dolhist(d,1) = currdate;
  dolhist(d,2) = dolM2m(1);

  dolYieldDays = dolYieldDays(didx);
  dolYieldDays(dolYieldDays==0)=1;
  %COUPON
  ddiidx = strcmp(quotes.daily(d).s_market,'DDI');
  ddiStrikedate = quotes.daily(d).t_strikedate(ddiidx);
  ddiYieldDays = quotes.daily(d).d_yieldDays(ddiidx);
  ddiM2m = quotes.daily(d).d_m2m(ddiidx);
  [ddiStrikedate, didx] = sort(ddiStrikedate);
  ddiM2m = ddiM2m(didx);
  ddiYieldDays = ddiYieldDays(didx);
  ddiRate = (100000./ddiM2m).^(360./ddiYieldDays)-1;
  ddiRate = ddiRate.*100;
  try
  %dolRate = di1Rate_(dolYieldDays)';
  %dolPV = dolM2m./((1+dolRate./100).^(dolYieldDays./252));
  dolRate=100.*...
    ((dolM2m./dolM2m(1)).^(360./(dolYieldDays-dolYieldDays(1)))-1);
  catch
    disp('err');
  end

  figure(102)    
  plot(currdate+di1YieldDays,di1Rate,'kx');
  hold on
  plot(di1hist(:,1),di1hist(:,2));
  plot(currdate+di1Days,di1Rate_,'r');
  plot(currdate+dolYieldDays,dolRate,'b');
  if length(di1hist(:,2))>20
  [dummy, di1avg] = movavg(di1hist(:,2),1,20);
  plot(di1hist(:,1),di1avg);
  end
  %plot(currdate+ddiYieldDays,ddiRate,'ro');
  datetick('x');
  hold off


  strikedates = unique(quotes.deltas(d).t_strikedate);
  for i=1:length(strikedates)
    if length(quotes.daily)>=d

      dolidx = strcmp(quotes.daily(d).s_market,'DOL');
      Tidx = dolidx & quotes.daily(d).t_strikedate==strikedates(i);
      if any(Tidx)
        T = quotes.daily(d).d_yieldDays(Tidx);
        T = T(T~=0);
        if ~isempty(T)
        T=T(1);
        di1T = di1Rate_(T);
        di1R = log(1+(di1T/100));
        sdidx = quotes.deltas(d).t_strikedate == strikedates(i);
        callidx = sdidx & strcmp(quotes.deltas(d).s_contractType,'C');
        cdeltas = quotes.deltas(d).d_delta(sdidx & callidx);
        cimpVol = quotes.deltas(d).d_impVol(sdidx & callidx);
        cstrikeprice = quotes.deltas(d).d_strikeprice(sdidx & callidx);
        cdeltas = -cdeltas+1;

        putidx = sdidx & strcmp(quotes.deltas(d).s_contractType,'V');
        pdeltas = quotes.deltas(d).d_delta(sdidx & putidx);
        pimpVol = quotes.deltas(d).d_impVol(sdidx & putidx);
        pstrikeprice = quotes.deltas(d).d_strikeprice(sdidx & putidx);
        if any(pdeltas<0)
          pdeltas = -pdeltas-1;
        else
          pdeltas = pdeltas-1;
        end

        cNd1 = cdeltas./exp(-di1R*T/252);
        pNd1 = (pdeltas./exp(-di1R*T/252))+1;

        if length(cdeltas)>=2 && length(pdeltas)>=2

          delta = 0:0.01:0.99;
          [C,ia,ic] = unique(cdeltas);
          cdeltas=cdeltas(ia);
          cimpVol=cimpVol(ia);
          cstrikeprice=cstrikeprice(ia);
          cNd1 = cNd1(ia);
          cimpVol_ = spline(cdeltas,cimpVol,delta);

          [C,ia,ic] = unique(pdeltas);
          pdeltas=pdeltas(ia);
          pimpVol=pimpVol(ia);
          pstrikeprice=pstrikeprice(ia);
          pNd1 = pNd1(ia);
          pimpVol_ = spline(pdeltas,pimpVol,-delta);

          catm = cimpVol_(51);
          patm = pimpVol_(51);
          if catm>0 && catm<100 && patm>0 && patm<100
            impVolAtm = (catm+patm)/2;
            voltermstruct{d}(i,:) = [T,impVolAtm];
          else
            voltermstruct{d}(i,:) = [nan,nan];
          end
          %{
          distr0 = [mean(cstrikeprice),mean(cstrikeprice)*.01];
          fun = @(distr)FitOptionsDelta(distr,cstrikeprice,cNd1);
          options = optimset('Display','off');
          [x,fval,exitflag,output] = fminsearch(fun,distr0,options);
          impProb{d}(i,1) = T;
          impProb{d}(i,2) = x(1);
          impProb{d}(i,3) = x(2);
          %}
          %if currdate >= 736627
          if currdate >= 736627
            figure(1)
            plot(cdeltas,cimpVol,'bx');
            hold on
            plot(pdeltas+1,pimpVol,'rx');
            plot(delta,cimpVol_,'c');
            plot(-delta+1,pimpVol_,'m');
            hold off
            figure(2)
            plot(cstrikeprice,cimpVol,'bx');
            hold on
            plot(pstrikeprice,pimpVol,'ro');
            hold off
            figure(3)
            plot(cstrikeprice,cdeltas,'bx');
            hold on
            plot(pstrikeprice,pdeltas,'rx');
            hold off
            figure(4)
            plot(cstrikeprice,cNd1,'bo');
            hold on
            plot(pstrikeprice,pNd1,'ro');
            hold off
            drawnow
          end
        end
        end
      end
    end
  end
  if length(voltermstruct)>=d
    temp = quotes.deltas(d).s_tradedate(1);
    if temp>100
      Ts = 0:120;
      volatm(d,1) = temp;
      nzidx = voltermstruct{d}(:,1)==0;
      voltermstruct{d}(nzidx,:)=[];
      nzidx = voltermstruct{d}(:,2)==0;
      voltermstruct{d}(nzidx,:)=[];
      [C,ia,ic] = unique(voltermstruct{d}(:,1));
      voltermstruct{d}(:,1) = voltermstruct{d}(ia,1);
      voltermstruct{d}(:,2) = voltermstruct{d}(ia,2);
      voltermstruct_{d} = ...
        spline(voltermstruct{d}(:,1),voltermstruct{d}(:,2),Ts);
      volatm(d,2) = voltermstruct_{d}(20);

      figure(101)
      plot(volatm(:,1),volatm(:,2));
      hold on
      plot(volatm(d,1)+Ts-20,voltermstruct_{d},'k');
      plot(volatm(d,1)+voltermstruct{d}(:,1),voltermstruct{d}(:,2),'rx');
      hold off
      datetick('x')

      figure(103)    
      plot(currdate+dolYieldDays,dolM2m,'kx');
      hold on
      plot(dolhist(:,1),dolhist(:,2));
      if length(dolhist(:,2))>20
      [dummy, dolavg] = movavg(dolhist(:,2),1,20);
      plot(dolhist(:,1),dolavg);
      end
      %{
      vidx = impProb{d}(:,1)~=0;
      plot(currdate+impProb{d}(vidx,1),impProb{d}(vidx,2));
      plot(currdate+impProb{d}(vidx,1),impProb{d}(vidx,2)+impProb{d}(vidx,3));
      plot(currdate+impProb{d}(vidx,1),impProb{d}(vidx,2)-impProb{d}(vidx,3));
      %}
      hold off
      datetick('x');

      if length(volatm(:,2))>10
      figure(110)
      autocorr(diff(volatm(:,2)),length(volatm(:,2))-2)
      end
      if length(volatm(:,2))>100
      figure(111)
      autocorr(diff(volatm(:,2)),99)
      figure(122)
      autocorr(diff(dolhist(:,2)),99)
      figure(123)
      autocorr(diff(di1hist(:,2)),99)
      figure(124)
      crosscorr(diff(dolhist(:,2)).^2,diff(volatm(:,2)))
      end

      obs = quotes.openbar(1:d);
      lbs = quotes.lastbar(1:d);
      range = quotes.rlogintraday(lbs)-quotes.rlogintraday(obs);
      if length(range)>100
        figure(129)
        autocorr(abs(range(end-100:end)),99);
      end
      %{
      if length(range)>100
        
      mdl = arima(1,0,1);
      mdl = estimate(mdl,abs(range)');
      [frange(d),frangee(d)]=forecast(mdl,1);
      figure(130)
      plot(abs(range));
      hold on
      plot(frange);
      plot(frange+frangee);
      hold off
      else
        frange(d)=0;frangee(d)=0;
      end
      %}
      drawnow
      %pause(0.1)
    end
  else
    volatm(d,:) = volatm(d-1,:);
  end
    %{
    %---------------------------------------------------------------------
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    
    if ob>0 && d>1
      if volatm(d,2)<volatm(d-1,2)
        deltaref = 1;
      else
        deltaref=1;
      end
      finalchannelid = ob + starttime;
      closepositionid = ob + stoptime;
      channelup = [];
      channeldn = [];
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        lstp = quotes.close(n,t);
        maxp = quotes.max(n,t);
        minp = quotes.min(n,t);
        %-----------------------------GAMMA---------------------------------
        if t>=ob && t<finalchannelid 
          if isempty(channelup)
            channelup = maxp;
          elseif maxp>channelup
            channelup = maxp;
          end
          if isempty(channeldn)
            channeldn = minp;
          elseif minp<channeldn
            channeldn = minp;
          end
          channelmid= (channelup+channeldn)/2;
        elseif t>=finalchannelid && t<=closepositionid
          if maxp>channelup
            signal.gamma(t) = deltaref - signal.delta(t-1);
          elseif minp<channeldn
            signal.gamma(t) = -deltaref - signal.delta(t-1);
          elseif signal.delta(t-1)>0 && minp<=channelmid 
            signal.gamma(t) = 0 - signal.delta(t-1);
          elseif signal.delta(t-1)<0 && maxp>=channelmid
            signal.gamma(t) = 0 - signal.delta(t-1);
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
    %}
  end
  
  %}
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
end

function InitDaily(symbol,signal)
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  tdot = tic;
  %% TRADEDATES LOOP
  voltermstruct=[];
  impProb=[];
  starttime = round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  figure(1)
  cla
  

end
function cost = FitOptionsDelta(distr,strikes,delta)
  mu = distr(1);
  sig = distr(2);
  prob = normcdf(strikes,mu,sig);
  cost = sum((prob-delta).^2);
  %{
  figure(1)
  cla
  hold on
  plot(strikes,prob,'k*')
  plot(strikes,delta,'rx')
  drawnow
  %}
end