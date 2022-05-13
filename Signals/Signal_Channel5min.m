function signal = Signal_Channel5min(symbol,signal)
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
  starttime = round((datenum(0,0,0,0,5,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  for d=1:length(quotes.tradedates)
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
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
          signal.gamma(t) = 1 - signal.delta(t-1);
        elseif minp<channeldn
          signal.gamma(t) = -1 - signal.delta(t-1);
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
    signal.lastbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
end

