function signal = Signal_ChannelTwoSigExit(symbol,signal)
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
  knockoutr = zeros(size(quotes.tradedates)); 
  knockoutsig = 0.025;
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
    if d>=100
      windowsample = 540*100;
      window = fb-windowsample:fb;
      [counts,centers]=hist(quotes.rlogintraday(n,window),100);
      counts = counts/sum(counts);
      cumdistfunc = cumsum(counts);
      knockoutr(d) = abs(centers(find(cumdistfunc>knockoutsig,1,'first')));
      knockoutr(d) = max(knockoutr(d),...
        abs(centers(find(cumdistfunc>1-knockoutsig,1,'first'))));
    else
      knockoutr(d) = 0.03;
    end
    finalchannelid = ob + ...
      round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
    closepositionid = ob + ...
      round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
    channelup = [];
    knockout = false;
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      knockout = abs(quotes.rlogintraday(n,t))>knockoutr(d) | knockout;
      %-----------------------------GAMMA---------------------------------
      if t>=finalchannelid && t<=closepositionid && ~knockout
        if isempty(channelup)
          channelup = max(quotes.max(n,ob:finalchannelid));
          channeldn = min(quotes.min(n,ob:finalchannelid));
          channelmid= (channelup+channeldn)/2;
        end
        lstp = quotes.close(n,t);
        maxp = quotes.max(n,t);
        minp = quotes.min(n,t);
        if maxp>channelup
          signal.gamma(t) = 1 - signal.delta(t-1);
        elseif minp<channeldn
          signal.gamma(t) = -1 - signal.delta(t-1);
        elseif (signal.delta(t-1)>0 && lstp<=channelmid) ||...
            (signal.delta(t-1)<0 && lstp>=channelmid)
          signal.gamma(t) = 0 - signal.delta(t-1);
        end
      else
        signal.gamma(t) = 0 - signal.delta(t-1);
      end
      %------------------------------------------------------------------
      %----------------------------INTEGRATORS---------------------------
        %minimum gamma
        if abs(signal.gamma(t))<0.01
          signal.gamma(t) = 0;
        end
        %delta 
        signal.delta(t) = signal.delta(t-1) + signal.gamma(t);
        %rlog
        signal.rlog(t) = ...
          quotes.rlog(n,t)*signal.delta(t-1)+signal.slippage(t);
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
    signal.lastbar = lb;
  end
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
  %FILTERS
  symbol.filters.knockoutr = knockoutr;
  figure
  plot(knockoutr);
end

