function signal = Signal_LongFly(symbol,signal)
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
  d = length(quotes.tradedates);
  wingssig = 4;
  mindeltaerror = 0.01;
  spread = 3;
  %-----------------------------FILTER INIT-------------------------------
  if ob~=0 && lb-ob<50
    openp = symbol.Main.quotes.close(n,ob);
    px = [1:20000].*symbol.ticksize;
    rlog = log(px/openp);
    s = exp(rlog);
    deltaref = zeros(size(rlog));
    fstob = quotes.openbar(n,d-99);
    window = fstob:length(quotes.rlogintraday(n,:));
    [mu,sig]=normfit(quotes.rlogintraday(n,window));
    [atmcall,atmput] = blsprice(s,1,0,1,sig);
    [itmcall,otmput] = blsprice(s,1+4*sig,0,1,sig);
    [otmcall,itmput] = blsprice(s,1-4*sig,0,1,sig);
    shortfly = itmcall-2.*atmcall+otmcall;
    deltaref = [diff(shortfly),0];
    deltaref = deltaref./max(deltaref);
    symbol.filters.deltaref = deltaref;
    symbol.filters.deltarefinit = true;
  elseif ~symbol.filters.deltarefinit 
    symbol.filters.deltaref = zeros(size([1:20000]));
  end
  %-----------------------------------------------------------------------
  %-----------------------------HISTORY---------------------------------
  if d>=100
    fstob = quotes.openbar(n,d-99);
    window = fstob:ob;
    lastp = quotes.close(n,ob);
    px = [1:20000].*symbol.ticksize;
    s = px./lastp;
    deltaref = zeros(size(s));
    [mu,sig]=normfit(quotes.rlogintraday(n,window));
    [atmcall,atmput] = blsprice(s,1,0,1,sig);
    [itmcall,otmput] = blsprice(s,1+wingssig*sig,0,1,sig);
    [otmcall,itmput] = blsprice(s,1-wingssig*sig,0,1,sig);
    shortfly = itmcall-2.*atmcall+otmcall;
    deltaref = [diff(shortfly),0];
    deltaref = deltaref./max(abs(deltaref));
    gammaref = diff(deltaref);
  end
  %---------------------------------------------------------------------
  startid = ob + ...
    round((0.00694444444444444-quotes.dt)/quotes.dt);
  closepositionid = ob + ...
    round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
  finalpositionid =  ob + ...
    round((datenum(0,0,0,8,55,0)-quotes.dt)/quotes.dt);
  lastpxid = 0;
  %% INTRADAY LOOP
  for t=signal.lastbar:lb
    fadePos = (finalpositionid-t)/(finalpositionid-closepositionid);
    fadePos = min(fadePos,1);
    fadePos = max(fadePos,0);
    %% -----------------------------GAMMA-------------------------------
    lstp = quotes.close(n,t);
    if d>=100
      if t<=startid
        signal.gamma(t) = 0 - signal.delta(t-1);
      elseif t>startid && t<=finalpositionid
        rlogid = round(lstp/symbol.ticksize);
        dref = deltaref(rlogid);
        dref = dref*fadePos;
        derr = dref-signal.delta(t-1);
        if abs(derr)>=mindeltaerror && abs(lastpxid-rlogid)>=spread
          signal.gamma(t) = derr;
          lastpxid = rlogid;
          %long gamma/ short gamma slippage
          if gammaref(rlogid) > 0
            signal.slippage(t) = ...
              abs(signal.gamma(t))*log((lstp-symbol.ticksize*0.5)/lstp);
          end
        end
      else
        signal.gamma(t) = 0 - signal.delta(t-1);
      end
    end
    %------------------------------------------------------------------
    %% --------------------------INTEGRATORS---------------------------
      %minimum gamma
      if abs(signal.gamma(t))<0.01
        signal.gamma(t) = 0;
      end
      %execution hypotesis
      %{
      if length(quotes.close)>t
        if signal.gamma(t)>0
          if quotes.min(t+1)>quotes.close(t) || quotes.volume(t+1)==0
            signal.gamma(t) = 0;
            signal.slippage(t) = 0;
          end
        elseif signal.gamma(t)<0 
          if quotes.max(t+1)<quotes.close(t) || quotes.volume(t+1)==0
            signal.gamma(t) = 0;
            signal.slippage(t) = 0;
          end
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
    

end
function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  symbol.filters.deltarefinit = false;
  wingssig = 4;
  mindeltaerror = 0.005;
  spread = 3;
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    fb=quotes.firstbar(d);
    ob=quotes.openbar(symbol.n,d);
    lb=quotes.lastbar(symbol.n,d);
    if ob~=0
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %-----------------------------HISTORY---------------------------------
    if d>=100
      fstob = quotes.openbar(n,d-99);
      window = fstob:ob;
      lastp = quotes.close(n,ob);
      px = [1:20000].*symbol.ticksize;
      s = px./lastp;
      deltaref = zeros(size(s));
      [mu,sig]=normfit(quotes.rlogintraday(n,window));
      [atmcall,atmput] = blsprice(s,1,0,1,sig);
      [itmcall,otmput] = blsprice(s,1+wingssig*sig,0,1,sig);
      [otmcall,itmput] = blsprice(s,1-wingssig*sig,0,1,sig);
      shortfly = itmcall-2.*atmcall+otmcall;
      deltaref = [diff(shortfly),0];
      deltaref = deltaref./max(abs(deltaref));
      gammaref = diff(deltaref);
    end
    %---------------------------------------------------------------------
    startid = ob + ...
      round((0.00694444444444444-quotes.dt)/quotes.dt);
    closepositionid = ob + ...
      round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
    finalpositionid =  ob + ...
      round((datenum(0,0,0,8,55,0)-quotes.dt)/quotes.dt);
    lastpxid = 0;
    %% INTRADAY LOOP
    for t=signal.lastbar:lb
      fadePos = (finalpositionid-t)/(finalpositionid-closepositionid);
      fadePos = min(fadePos,1);
      fadePos = max(fadePos,0);
      %% -----------------------------GAMMA-------------------------------
      lstp = quotes.close(n,t);
      if d>=100
        if t<=startid
          signal.gamma(t) = 0 - signal.delta(t-1);
        elseif t>startid && t<=finalpositionid
          rlogid = round(lstp/symbol.ticksize);
          dref = deltaref(rlogid);
          dref = dref*fadePos;
          derr = dref-signal.delta(t-1);
          if abs(derr)>=mindeltaerror && abs(lastpxid-rlogid)>=spread
            signal.gamma(t) = derr;
            lastpxid = rlogid;
            %long gamma/ short gamma slippage
            if gammaref(rlogid) > 0
              signal.slippage(t) = ...
                abs(signal.gamma(t))*log((lstp-symbol.ticksize*0.5)/lstp);
            end
          end
        else
          signal.gamma(t) = 0 - signal.delta(t-1);
        end
      end
      %------------------------------------------------------------------
      %% --------------------------INTEGRATORS---------------------------
        %minimum gamma
        if abs(signal.gamma(t))<0.005
          signal.gamma(t) = 0;
          signal.slippage(t) = 0;
        end
        %execution hypotesis
        %{
        if length(quotes.close)>t
          if signal.gamma(t)>0
            if quotes.min(t+1)>quotes.close(t) || quotes.volume(t+1)==0
              signal.gamma(t) = 0;
              signal.slippage(t) = 0;
            end
          elseif signal.gamma(t)<0 
            if quotes.max(t+1)<quotes.close(t) || quotes.volume(t+1)==0
              signal.gamma(t) = 0;
              signal.slippage(t) = 0;
            end
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
