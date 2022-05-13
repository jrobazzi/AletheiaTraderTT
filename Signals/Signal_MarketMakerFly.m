function signal = Signal_MarketMaker(symbol,signal)
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
  ndays=100;
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
  if d>=ndays
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
    if d>=ndays
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
  mindeltaerror = 0.01;
  %trade simulation
  contracts=500;
  buyAvg = zeros(size(quotes.rlog(n,:)));
  sellAvg = zeros(size(quotes.rlog(n,:)));
  buyQty = zeros(size(quotes.rlog(n,:)));
  sellQty = zeros(size(quotes.rlog(n,:)));
  position = zeros(size(quotes.rlog(n,:)));
  result = zeros(size(quotes.rlog(n,:)));
  orders = zeros(10,2);
  lasttradepx = 0;
  spread = 1*symbol.ticksize;
  ndays=100;
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    datestr(quotes.tradedates(d))
    fb=quotes.firstbar(d);
    ob=quotes.openbar(symbol.n,d);
    lb=quotes.lastbar(symbol.n,d);
    if ob~=0
    if toc(tdot)>1
      tdot=tic;
      fprintf('.');
    end
    %-----------------------------HISTORY---------------------------------
    if d>=ndays
      fstob = quotes.openbar(n,d-ndays+1);
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
      contractsref = round(deltaref.*contracts./symbol.lotmin).*symbol.lotmin;
    end
    %---------------------------------------------------------------------
    startid = ob;% + ...
      %round((0.00694444444444444-quotes.dt)/quotes.dt);
    closepositionid = ob + ...
      round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
    finalpositionid =  ob + ...
      round((datenum(0,0,0,8,55,0)-quotes.dt)/quotes.dt);
    lastpxid = 0;
    %order simulation
    orders = zeros(10,2);
    lasttradepx=0;lasttradedir=0;
    
    for t=signal.lastbar:lb % INTRADAY LOOP
      %% EXECUTION SIMULATION
      lstp = quotes.close(n,t);
      maxp = quotes.max(n,t);
      minp = quotes.min(n,t);
      position(t)=position(t-1);
      if quotes.volume(t)>0
        longidx = orders(:,2)>0;
        if any(longidx)
          execidx = minp<=orders(:,1) & longidx;
          if any(execidx)
            buyQty(t)=sum(orders(execidx,2));
            maxidx = orders(execidx,1)>maxp;
            if any(maxidx)
              orders(maxidx,1)=maxp;
            end
            buyAvg(t)=sum(orders(execidx,1).*orders(execidx,2))/buyQty(t);
            position(t) = position(t)+buyQty(t);
            orders(execidx,2)=0;
            lasttradepx = min(orders(execidx,1));
            lasttradedir = 1;
          end
        end
        shortidx = orders(:,2)<0;
        if any(shortidx)
          execidx = maxp>=orders(:,1) & shortidx;
          if any(execidx)
            sellQty(t)=sum(orders(execidx,2));
            minidx = orders(execidx,1)<minp;
            if any(minidx)
              orders(minidx,1)=minp;
            end
            sellAvg(t)=sum(orders(execidx,1).*orders(execidx,2))/sellQty(t);
            position(t) = position(t)+sellQty(t);
            orders(execidx,2)=0;
            lasttradepx = max(orders(execidx,1));
            lasttradedir = -1;
          end
        end
        dPos = buyQty(t)+sellQty(t);
        if dPos~=0
          dPx = (buyQty(t)*buyAvg(t)+sellQty(t)*sellAvg(t))/dPos;
          signal.gamma(t) = dPos/contracts;
          signal.slippage(t) = log(quotes.close(n,t)/dPx);
        elseif buyQty(t)~=0 || sellQty(t)~=0
          dPx = -(buyQty(t)*buyAvg(t)+sellQty(t)*sellAvg(t))/contracts;
          signal.gamma(t) = 0;
          signal.slippage(t) = log((quotes.close(n,t)+dPx)/quotes.close(n,t));
        end
      end
      if abs(position(t))>contracts
        disp('err');
      end
      %% -----------------------------GAMMA-------------------------------
      if d>=ndays
        if t<=startid
          signal.gamma(t) = 0 - signal.delta(t-1);
          orders(:,2) = 0;
        elseif t>startid && t<=finalpositionid
          if lasttradepx ==0
            lasttradepx = lstp;
          end
          if lasttradedir>0
            bestbid = lasttradepx;
            bestask = lasttradepx+spread;
          elseif lasttradedir<0
            bestbid = lasttradepx-spread;
            bestask = lasttradepx;
          else
            bestbid = lasttradepx-symbol.ticksize;
            bestask = lasttradepx+symbol.ticksize;
          end
          fadePos = (finalpositionid-t)/(finalpositionid-closepositionid);
          fadePos = min(fadePos,1);
          fadePos = max(fadePos,0);
          cref = round((contractsref.*fadePos)./symbol.lotmin).*symbol.lotmin;
          %cref = cref-position(t);
          bestbidpx = round(bestbid/symbol.ticksize);
          orders(6:10,1) = flip([bestbidpx-4:bestbidpx].*symbol.ticksize);
          orders(6:10,2) = diff([position(t),flip(cref(bestbidpx-4:bestbidpx))]);
          ordersPos(6:10) = cumsum(flip(orders(6:10,2)))+position(t);
          
          ordersPos(6:10,2) = cumsum(orders(6:10,2));
          bestaskpx = round(bestask/symbol.ticksize);
          orders(1:5,1) = flip([bestaskpx:bestaskpx+4].*symbol.ticksize);
          orders(1:5,2) = flip(diff([position(t),cref(bestaskpx:bestaskpx+4)]));
          ordersPos(1:5) = cumsum((orders(1:5,2)))+position(t);
          
          
          %if quotes.tradedates(d)==736775
            figure(1)
            %stairs(position(fb:lb))
            %px = [min(orders(:,1)):max(orders(:,1))].*symbol.tickszie;
            ax1=subplot(1,2,1);plot(quotes.close(n,fb:t))
            ax2=subplot(1,2,2);barh(orders(:,1),orders(:,2))
            linkaxes([ax1 ax2],'y')
            set(ax1,'YLim',[min(quotes.close(n,fb:t)),max(quotes.close(n,fb:t))]);
            pause(0.01);
          %end
        else
          signal.gamma(t) = 0 - signal.delta(t-1);
          position(t) = 0;
        end
      end
      %------------------------------------------------------------------
      %% --------------------------INTEGRATORS---------------------------
        %delta 
        %signal.delta(t) = signal.delta(t-1) + signal.gamma(t);
        signal.delta(t) = position(t)/contracts;
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
        %signal.rlog(t) = ...
        %  quotes.rlog(n,t)*signal.delta(t-1)+signal.slippage(t);
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
