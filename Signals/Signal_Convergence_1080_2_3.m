function signal = Signal_Convergence_1080_2_3(symbol,signal)
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
  %parameters
  tauMA = 1080*1;sigref = 2;spread = 3; slip=2;
  nma = find(symbol.filters.tau == tauMA);
  %% TRADEDATES LOOP
  for d=1:length(quotes.tradedates)
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if d>1
      sigMA = symbol.filters.sig(d-1,nma);
    else
      sigMA = symbol.filters.sig(d,nma);
    end
    if ob>0 && d>=(tauMA*30/540)
      longsigref = sigref;
      inLong=-longsigref; outLong=0; 
      inLongExp = spread; outLongExp = 1/inLongExp;
      shortsigref = sigref;
      inShort=shortsigref; outShort=0; 
      inShortExp = spread; outShortExp=1/inShortExp;
      %% INTRADAY LOOP
      for t=signal.lastbar:lb
        lstp = quotes.close(n,t);
        maxp = quotes.max(n,t);
        minp = quotes.min(n,t);
        avgp = symbol.filters.avg(t,nma);
        ldelta=signal.delta(t-1);
        %-----------------------------GAMMA---------------------------------
        if t>=ob && t<=lb
          if lstp>avgp && ldelta>0
            signal.gamma(t) = 0-signal.delta(t-1);
          elseif lstp<avgp && ldelta<0
            signal.gamma(t) = 0-signal.delta(t-1);
          elseif lstp<=avgp
            %long
            xLong = (lstp-avgp)/(sigMA*avgp);
            if xLong<-longsigref
              xLong=-longsigref;
            end
            inLongRef = ...
              (1-(abs(xLong-inLong)/abs(outLong-inLong)))^inLongExp;
            if ~isreal(inLongRef)
              disp('err');
            end
            if inLongRef > ldelta
              signal.gamma(t) = inLongRef - ldelta;
            else
              outLongRef = ...
                (1-(abs(xLong-inLong)/abs(outLong-inLong)))^outLongExp;
              if ~isreal(outLongRef)
                disp('err');
              end
              if outLongRef<ldelta
                signal.gamma(t) = outLongRef - ldelta;
              end
            end
          elseif lstp>=avgp
            %short
            xShort = (lstp-avgp)/(sigMA*avgp);
            if xShort>shortsigref
              xShort=shortsigref;
            end
            inShortRef = ...
              -((abs(xShort-outShort)/abs(inShort-outShort)))^inShortExp;
            if ~isreal(inShortRef)
              disp('err');
            end
            if inShortRef < ldelta
              signal.gamma(t) = inShortRef - ldelta;
            else
              outShortRef = ...
                -((abs(xShort-outShort)/abs(inShort-outShort)))^outShortExp;
              if ~isreal(outShortRef)
                disp('err');
              end
              if outShortRef>ldelta
                signal.gamma(t) = outShortRef - ldelta;
              end
            end
          end
        end
        %------------------------------------------------------------------
        %% --------------------------INTEGRATORS---------------------------
        %max gamma
        if abs(signal.gamma(t))>0.05
          signal.gamma(t) = sign(signal.gamma(t))*0.05;
        end
        %minimum gamma
        if abs(signal.delta(t-1))>0.005 && abs(signal.gamma(t))<0.005
          signal.gamma(t) = 0;
          signal.slippage(t) = 0;
        else
          signal.slippage(t) = abs(signal.gamma(t))*...
          -log((quotes.close(n,t)+slip*symbol.ticksize)/quotes.close(n,t));
        end
        %execution
        %
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
        %}
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

