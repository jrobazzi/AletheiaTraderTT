function signal = Signal_ChannelGamma30TWAP(symbol,signal)
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
  starttime = round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  if ob>0
    finalchannelid = ob + starttime;
    closepositionid = ob + stoptime;
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      if t>1
      lstp = quotes.close(n,t);
      maxp = quotes.max(n,t);
      minp = quotes.min(n,t);
      %-----------------------------GAMMA---------------------------------
      if t>=finalchannelid && t<=closepositionid
        channelup=max(quotes.max(n,ob:finalchannelid));
        channeldn=min(quotes.min(n,ob:finalchannelid));
        channelmid= (channelup+channeldn)/2;
        channelmid= round(channelmid/symbol.ticksize)*symbol.ticksize;
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
      %rate limiter
      if signal.gamma(t)>0.1
        signal.gamma(t)=0.1;
      elseif signal.gamma(t)<-0.1
        signal.gamma(t)=-0.1;
      end
      signal.slippage(t) = ...
        -abs(log((lstp+symbol.ticksize)/lstp)*signal.gamma(t));
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
      if abs(signal.gamma(t))<0.01
        signal.gamma(t) = 0;
      end
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
      if signal.gammadir(t)==1
        volume = (quotes.buyvolume(n,t)+quotes.sellvolume(n,t))/2;
        signal.capacity(t) = volume/abs(signal.gamma(t));
      end
      signal.rlog(t) = ...
        quotes.rlog(n,t)*signal.delta(t-1)+signal.slippage(t);
      %cost/slippage
      q = symbol.tickvalue/symbol.ticksize;  
      tob = (symbol.brokerage+symbol.fees)/(quotes.close(n,fb)*q);
      signal.cost(t) = abs(signal.gamma(t))*tob;
      signal.rlogaccum(t) = signal.rlogaccum(t-1)+signal.rlog(t);
      signal.gammaaccum(t) = signal.gammaaccum(t-1)+abs(signal.gamma(t));
      signal.costaccum(t) = signal.costaccum(t-1)+signal.cost(t);
      signal.slippageaccum(t) = signal.slippageaccum(t-1)+...
        signal.slippage(t);
      signal.rlognetaccum(t) = signal.rlogaccum(t)-signal.costaccum(t);
      signal.rlogaccummax(t) =...
        max(signal.rlognetaccum(t),signal.rlogaccummax(t-1));
      signal.rlogunderwater(t)=signal.rlognetaccum(t)-...
        signal.rlogaccummax(t);
      %------------------------------------------------------------------
      end
    end
  end
  signal.lastbar = lb;
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  tdot = tic;
  gammachannel=0.3;
  %% TRADEDATES LOOP
  starttime = round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
  stoptime = round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  finaltime = round((datenum(0,0,0,8,50,0)-quotes.dt)/quotes.dt);
  for d=1:length(quotes.tradedates)
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if ob>0
      finalchannelid = ob + starttime;
      closepositionid = ob + stoptime;
      finalpositionid = ob + finaltime;
      channelup = [];
      channeldn = [];
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        lstp = quotes.close(n,t);
        maxp = quotes.max(n,t);
        minp = quotes.min(n,t);
        fadePos = (finalpositionid-t)/(finalpositionid-closepositionid);
        fadePos = min(fadePos,1);
        fadePos = max(fadePos,0);
        %-----------------------------GAMMA---------------------------------
        if t>=finalchannelid && t<=closepositionid && t<lb
          channelup=max(quotes.max(n,ob:finalchannelid));
          channeldn=min(quotes.min(n,ob:finalchannelid));
          channelmid= (channelup+channeldn)/2;
          channelmid= round(channelmid/symbol.ticksize)*symbol.ticksize;
          if maxp>channelup
            signal.gamma(t) = 1*fadePos - signal.delta(t-1);
          elseif minp<channeldn
            signal.gamma(t) = -1*fadePos - signal.delta(t-1);
          elseif signal.delta(t-1)>0 && minp<=channelmid 
            signal.gamma(t) = 0*fadePos - signal.delta(t-1);
          elseif signal.delta(t-1)<0 && maxp>=channelmid
            signal.gamma(t) = 0*fadePos - signal.delta(t-1);
          end
        else
          signal.gamma(t) = 0 - signal.delta(t-1);
        end
        %rate limiter
        if signal.gamma(t)>gammachannel
          signal.gamma(t)=gammachannel;
        elseif signal.gamma(t)<-gammachannel
          signal.gamma(t)=-gammachannel;
        end
        %------------------------------------------------------------------
        %% --------------------------INTEGRATORS---------------------------
        %minimum gamma
        if abs(signal.gamma(t))<0.005
          signal.gamma(t) = 0;
          signal.slippage(t) = 0;
        end
        %execution
        if t<length(quotes.time) && signal.gamma(t)~=0
          if quotes.volume(t+1)==0
            signal.gamma(t) = 0;
            signal.slippage(t) = 0;
          elseif signal.gamma(t)>0 && quotes.close(t)<quotes.min(t+1)
            signal.gamma(t) = 0;
            signal.slippage(t) = 0;
          elseif signal.gamma(t)<0 && quotes.close(t)>quotes.max(t+1)
            signal.gamma(t) = 0;
            signal.slippage(t) = 0;
          end
        end
        %delta 
        signal.delta(t) = signal.delta(t-1) + signal.gamma(t);
        %gammadir
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
        %rlog
        signal.rlog(t) = ...
          quotes.rlog(n,t)*signal.delta(t-1)+signal.slippage(t);
        %capacity
        if signal.gammadir(t)==1
          volume = (quotes.buyvolume(n,t)+quotes.sellvolume(n,t))/2;
          signal.capacity(t) = volume/abs(signal.gamma(t));
        end
        %cost/slippage
        q = symbol.tickvalue/symbol.ticksize;  
        tob = (symbol.brokerage+symbol.fees)/(quotes.close(n,fb)*q);
        signal.cost(t) = abs(signal.gamma(t))*tob;
        %positions
        if signal.gamma(t)~=0
          if signal.positions.npos==0
            %first position
            signal.positions.npos=signal.positions.npos+1;
            npos = signal.positions.npos;
            if signal.gamma(t)>0
              signal.positions.long(npos) = ...
                signal.gamma(t)*quotes.close(n,t)*q;
            elseif signal.gamma(t)<0
              signal.positions.short(npos) = ...
                signal.gamma(t)*quotes.close(n,t)*q;
            end
            signal.positions.delta(npos) = signal.delta(t);
            signal.positions.equity(npos) = ...
              signal.positions.long(npos)+signal.positions.short(npos);
          else %if not first position

            if signal.delta(t)==0
              %position closed
              npos = signal.positions.npos;
              if signal.gamma(t)>0
                signal.positions.long(npos)=signal.positions.long(npos)+ ...
                  signal.gamma(t)*quotes.close(n,t)*q;
              elseif signal.gamma(t)<0
                signal.positions.short(npos)=signal.positions.short(npos)+ ...
                  signal.gamma(t)*quotes.close(n,t)*q;
              end
              signal.positions.result(npos)=...
                -(signal.positions.long(npos)+signal.positions.short(npos));
              signal.positions.return(npos)= ...
                signal.positions.result(npos)/abs(signal.positions.equity(npos));
              signal.positions.points(npos)=signal.positions.result(npos)/q;

            elseif signal.delta(t)>0
              if signal.delta(t-1)>0
                %position increased
                npos = signal.positions.npos;
                if signal.gamma(t)>0
                  signal.positions.long(npos)=signal.positions.long(npos)+ ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos)=signal.positions.short(npos)+ ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                end
                signal.positions.delta(npos) = ...
                  max(signal.positions.delta(npos),signal.delta(t));
                signal.positions.equity(npos) = ...
                  max(signal.positions.equity(npos),...
                  signal.positions.long(npos)+signal.positions.short(npos));
              elseif signal.delta(t-1)<0
                %position reversion
                npos = signal.positions.npos;
                lastpos = signal.delta(t-1);
                if signal.gamma(t)>0
                  signal.positions.long(npos)=signal.positions.long(npos)+ ...
                    -lastpos*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos)=signal.positions.short(npos)+ ...
                    -lastpos*quotes.close(n,t)*q;
                end
                signal.positions.result(npos)=...
                  -(signal.positions.long(npos)+signal.positions.short(npos));
                signal.positions.return(npos)= ...
                  signal.positions.result(npos)/abs(signal.positions.equity(npos));
                signal.positions.points(npos)=signal.positions.result(npos)/q;
                %new position
                signal.positions.npos=signal.positions.npos+1;
                npos = signal.positions.npos;
                signal.positions.delta(npos) = signal.delta(t);
                signal.positions.equity(npos) =...
                  signal.delta(t)*quotes.close(n,t)*q;
                if signal.positions.equity(npos)>0
                  signal.positions.long(npos)=signal.positions.equity(npos);
                elseif signal.positions.equity(npos)<0
                  signal.positions.short(npos)=signal.positions.equity(npos);
                end
              else %if delta(t-1)==0
                %new position
                signal.positions.npos=signal.positions.npos+1;
                npos = signal.positions.npos;
                if signal.gamma(t)>0
                  signal.positions.long(npos) = ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos) = ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                end
                signal.positions.delta(npos) = signal.delta(t);
                signal.positions.equity(npos) = ...
                  signal.positions.long(npos)+signal.positions.short(npos);
              end
            elseif signal.delta(t)<0
              if signal.delta(t-1)<0
                %position increased
                npos = signal.positions.npos;
                if signal.gamma(t)>0
                  signal.positions.long(npos)=signal.positions.long(npos)+ ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos)=signal.positions.short(npos)+ ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                end
                signal.positions.delta(npos) = ...
                  min(signal.positions.delta(npos),signal.delta(t));
                signal.positions.equity(npos) = ...
                  min(signal.positions.equity(npos),...
                  signal.positions.long(npos)+signal.positions.short(npos));
              elseif signal.delta(t-1)>0
                %position reversion
                npos = signal.positions.npos;
                lastpos = signal.delta(t-1);
                if signal.gamma(t)>0
                  signal.positions.long(npos)=signal.positions.long(npos)+ ...
                    -lastpos*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos)=signal.positions.short(npos)+ ...
                    -lastpos*quotes.close(n,t)*q;
                end
                signal.positions.result(npos)=...
                  -(signal.positions.long(npos)+signal.positions.short(npos));
                signal.positions.return(npos)= ...
                  signal.positions.result(npos)/abs(signal.positions.equity(npos));
                signal.positions.points(npos)=signal.positions.result(npos)/q;
                %new position
                signal.positions.npos=signal.positions.npos+1;
                npos = signal.positions.npos;
                signal.positions.delta(npos) = signal.delta(t);
                signal.positions.equity(npos) =...
                  signal.delta(t)*quotes.close(n,t)*q;
                if signal.positions.equity(npos)>0
                  signal.positions.long(npos)=signal.positions.equity(npos);
                elseif signal.positions.equity(npos)<0
                  signal.positions.short(npos)=signal.positions.equity(npos);
                end
              else %if delta(t-1)==0
                %new position
                signal.positions.npos=signal.positions.npos+1;
                npos = signal.positions.npos;
                if signal.gamma(t)>0
                  signal.positions.long(npos) = ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                elseif signal.gamma(t)<0
                  signal.positions.short(npos) = ...
                    signal.gamma(t)*quotes.close(n,t)*q;
                end
                signal.positions.delta(npos) = signal.delta(t);
                signal.positions.equity(npos) = ...
                  signal.positions.long(npos)+signal.positions.short(npos);
              end
            end
          end
        end
        %integrators
        signal.rlogaccum(t) = signal.rlogaccum(t-1)+signal.rlog(t);
        signal.gammaaccum(t) = signal.gammaaccum(t-1)+abs(signal.gamma(t));
        signal.costaccum(t) = signal.costaccum(t-1)+signal.cost(t);
        signal.slippageaccum(t) = signal.slippageaccum(t-1)+...
          signal.slippage(t);
        signal.rlognetaccum(t) = signal.rlogaccum(t)-signal.costaccum(t);
        signal.rlogaccummax(t) =...
          max(signal.rlognetaccum(t),signal.rlogaccummax(t-1));
        signal.rlogunderwater(t)=signal.rlognetaccum(t)-...
          signal.rlogaccummax(t);
        %------------------------------------------------------------------
    
      end
      %}
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

