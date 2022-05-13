function signal = Signal_ShortVol(symbol,signal)
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
    %----------------------------------------------------------------------
    %-----------------------------GAMMA---------------------------------
    if t-ob>10 && ndays>=100
      if (signal.delta(t-1)>0 && ...
          quotes.rlogintraday(n,t)>=symbol.filters.reversionavg(t)) ||...
          (signal.delta(t-1)<0 && ...
          quotes.rlogintraday(n,t)<=symbol.filters.reversionavg(t))
        signal.gamma(t) = 0 - signal.delta(t-1);
      elseif quotes.rlogintraday(n,t) > symbol.filters.reversionavg(t)+...
          symbol.filters.sigreversion(ndays)
        signal.gamma(t) = -1 - signal.delta(t-1);
      elseif quotes.rlogintraday(n,t) < symbol.filters.reversionavg(t)-...
          symbol.filters.sigreversion(ndays)
        signal.gamma(t) = 1 - signal.delta(t-1);
      end
    else
      signal.gamma(t) = 0 - signal.delta(t-1);
    end
    %------------------------------------------------------------------
    %% ----------------------------INTEGRATORS---------------------------
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
    signal.lastbar = t;
  end
  %}
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  taureversion = 0.02;
  sigreversion = ones(length(quotes.tradedates),1)*0.005;
  reversionavg = zeros(size(quotes.rlog(n,:)));
  reversionupprpx = zeros(size(quotes.rlog(n,:)));
  reversionlowrpx = zeros(size(quotes.rlog(n,:)));
  reversionavgpx = zeros(size(quotes.rlog(n,:)));
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    if ob~=0
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
        %---------------------------FILTER-------------------------------
        if t==ob
          reversionavg(t)=0;
        elseif quotes.volume(n,t)~=0
          reversionavg(t)=...
            reversionavg(t-1)*(1-taureversion)+...
            quotes.rlogintraday(n,t)*(taureversion);
        else
          reversionavg(t)=reversionavg(t-1);
        end
        reversionupprpx(t) = quotes.close(n,ob)*...
          exp(reversionavg(t) + sigreversion(d));
        reversionlowrpx(t) = quotes.close(n,ob)*...
          exp(reversionavg(t) - sigreversion(d));
        reversionavgpx(t) = quotes.close(n,ob)*exp(reversionavg(t));
        %-----------------------------------------------------------------
        %-----------------------------GAMMA-------------------------------
        if t-ob>10 && lb-t>40 && d>=100
          if (signal.delta(t-1)>0 && ...
              quotes.rlogintraday(n,t)>=reversionavg(t)) ||...
              (signal.delta(t-1)<0 && ...
              quotes.rlogintraday(n,t)<=reversionavg(t))
            signal.gamma(t) = 0 - signal.delta(t-1);
          elseif quotes.rlogintraday(n,t) > reversionavg(t)+sigreversion(d)
            signal.gamma(t) = -1 - signal.delta(t-1);
          elseif quotes.rlogintraday(n,t) < reversionavg(t)-sigreversion(d)
            signal.gamma(t) = 1 - signal.delta(t-1);
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
  symbol.filters.reversionavg = reversionavg;
  symbol.filters.sigreversion = sigreversion;
  symbol.filters.reversionupprpx = reversionupprpx;
  symbol.filters.reversionlowrpx = reversionlowrpx;
  symbol.filters.reversionavgpx = reversionavgpx;
end

