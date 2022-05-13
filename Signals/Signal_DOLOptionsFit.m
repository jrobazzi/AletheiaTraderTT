function signal = Signal_DOLOptionsFit(symbol,signal)
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
  
  starttime = round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  voltermstruct = [];
    figure(3)
    cla
    hold on
    figure(2)
    cla
    hold on
  for d=1:length(quotes.daily)
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    figure(1)
    cla
    hold on
    dolidx = strcmp(quotes.daily(d).s_market,'DOL');
    maxfut = max(quotes.daily(d).d_futSeq(dolidx));
    for fut=1:maxfut
      ffidx = (quotes.daily(d).d_futSeq == fut) & dolidx;
      price = quotes.daily(d).d_m2m(ffidx);
      strikedate = quotes.daily(d).t_strikedate(ffidx);
      sdidx = quotes.daily(d).t_strikedate == strikedate;

      callidx = sdidx & strcmp(quotes.daily(d).s_contractType,'C') & dolidx;
      cstrikes = quotes.daily(d).d_strikeprice(callidx);
      cstrikedate = quotes.daily(d).d_yieldDays(callidx);
      cprice = quotes.daily(d).d_m2m(callidx);
      coint = quotes.daily(d).d_openInterest(callidx);

      putidx = sdidx & strcmp(quotes.daily(d).s_contractType,'V') & dolidx;
      pstrikes = quotes.daily(d).d_strikeprice(putidx);
      pstrikedate = quotes.daily(d).d_yieldDays(putidx);
      pprice = quotes.daily(d).d_m2m(putidx);
      point = quotes.daily(d).d_openInterest(putidx);

      di1idx = strcmp(quotes.daily(d).s_market,'DI1');
      di1Rate = quotes.daily(d).d_m2m(di1idx);
      di1Strikedate = quotes.daily(d).t_strikedate(di1idx);
      di1YieldDays = quotes.daily(d).d_yieldDays(di1idx);
      [di1Strikedate, didx] = sort(di1Strikedate);
      di1Rate = di1Rate(didx);
      di1YieldDays = di1YieldDays(didx);
      di1sdid = find(di1Strikedate>=strikedate,1,'first');
      ir = di1Rate(di1sdid);
      figure(101)
      plot(di1YieldDays,di1Rate,'kx');
      %datetick('x');
      drawnow
      
      %{
      fprintf('DOL:%s;DI1:%s\n',...
        datestr(strikedate,'yyyy-mm-dd'),...
        datestr(di1Strikedate(di1sdid),'yyyy-mm-dd'));
      
      clear cvol pvol cdelta pdelta cgamma pgamma cvidx pvidx
      cvidx =[];
      if any(callidx)
        cvol = blsimpv(price, cstrikes, ir,...
            cstrikedate/252, cprice, [], 0, [], {'call'}); 
        cvidx = ~isnan(cvol);
        if sum(cvidx)>2
          cdelta = blsdelta(price,cstrikes(cvidx),ir,...
            cstrikedate(cvidx)./252,cvol(cvidx));
          cgamma = blsgamma(price,cstrikes(cvidx),ir,...
            cstrikedate(cvidx)./252,cvol(cvidx));
          distr0 = [0,1];
          fun = @(distr)...
            FitOptionsDelta(distr,log(cstrikes(cvidx)./price),cdelta);
          options = optimset('Display','off');
          [x,fval,exitflag,output] = fminsearch(fun,distr0,options);
          voltermstruct(d).cmu(fut) = x(1);
          voltermstruct(d).csig(fut) = x(2);
          voltermstruct(d).strikedate(fut) = strikedate;
          voltermstruct(d).cT(fut) = cstrikedate(1);
          voltermstruct(d).cdelta{fut} = cdelta;
          voltermstruct(d).cgamma{fut} = cgamma;
          voltermstruct(d).cvol{fut} = cvol(cvidx);
          atmid = find(cdelta<=0.5,1,'first');
          voltermstruct(d).cvolatm(fut) = voltermstruct(d).cvol{fut}(atmid);
        end
      else
        break;
      end
      pvidx =[];
      if any(putidx)
        pvol = ...
            blsimpv(price, pstrikes, ir,...
            pstrikedate./252, pprice, [], 0, [], {'put'});
        pvidx = ~isnan(pvol);
        if sum(pvidx)>2
          pdelta = blsdelta(price,pstrikes(pvidx),ir,...
            pstrikedate(pvidx)./252,pvol(pvidx));
          pgamma = blsgamma(price,pstrikes(pvidx),ir,...
            pstrikedate(pvidx)./252,pvol(pvidx));
          
          distr0 = [0,1];
          fun = @(distr)...
            FitOptionsDelta(distr,log(pstrikes(pvidx)./price),pdelta);
          options = optimset('Display','off');
          [x,fval,exitflag,output] = fminsearch(fun,distr0,options);
          voltermstruct(d).pmu(fut) = x(1);
          voltermstruct(d).psig(fut) = x(2);
          voltermstruct(d).strikedate(fut) = strikedate;
          voltermstruct(d).pT(fut) = cstrikedate(1);
          voltermstruct(d).pdelta{fut} = pdelta;
          voltermstruct(d).pgamma{fut} = pgamma;
          voltermstruct(d).pvol{fut} = pvol(pvidx);
          atmid = find(pdelta>=0.5,1,'last');
          voltermstruct(d).pvolatm(fut) = voltermstruct(d).pvol{fut}(atmid);
        end
      end
      %}
    end
      %{
    figure(2)
    hold on
    vidx = voltermstruct(d).strikedate ~= 0;
    plot(voltermstruct(d).cT,voltermstruct(d).cvolatm,'b*');
    plot(voltermstruct(d).pT,voltermstruct(d).pvolatm,'r*');
    %datetick('x')
    hold off
    figure(3)
    hold on
    vidx = voltermstruct(d).strikedate ~= 0;
    plot(voltermstruct(d).cT,voltermstruct(d).csig,'b*');
    plot(voltermstruct(d).pT,voltermstruct(d).psig,'r*');
    %datetick('x')
    hold off
    drawnow
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

function cost = FitOptionsDelta(distr,strikes,delta)
  mu = distr(1);
  sig = distr(2);
  prob = -normcdf(strikes,mu,sig)+1;
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

%{
function cost = FitOptionsDelta(distr,cstrikes,cdelta,pstrikes,pdelta)
  mu = distr(1);
  sig = distr(2);
  cprob = -normcdf(cstrikes,mu,sig)+1;
  pprob = -normcdf(pstrikes,mu,sig)+1;
  cost = sum((cprob-cdelta).^2) + sum((pprob-pdelta).^2);
  
  figure(1)
  cla
  hold on
  plot(cstrikes,cprob,'b*')
  plot(pstrikes,pprob,'r*')
  plot(cstrikes,cdelta,'cx')
  plot(pstrikes,pdelta,'mx')
  drawnow
  
end
%}
