function LongFlyLimitSpread( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end)-1;
  if openbar > 0
    lastbar = quotes.lastbar(n,end);
    finalchannelid = openbar + ...
      round((0.000694444444444444-quotes.dt)/quotes.dt);
    closepositionid = openbar + ...
      round((0.333333333333333-quotes.dt)/quotes.dt);
    if lastbar>=finalchannelid && lastbar<=closepositionid
      pcol = Position.IO.cols;
      tags = Position.IO.tags;
      tagid = Position.IO.tagid;
      q = symbol.tickvalue/symbol.ticksize;
      firstbar = quotes.firstbar(end);
      contracts = Position.alocation(pcol.value)/...
        quotes.close(n,firstbar-1)/q;
      contracts = round(contracts/symbol.lotmin)*symbol.lotmin;
      symbol = Position.Symbol;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      %% SETPOSITIONPROFILE
      Position.setpositionprofile=contracts.*symbol.filters.deltaref;
      %% SET REQTRADE
      lb=lastbar;
      lstp = quotes.close(n,lb);
      lastpx = round(lstp/symbol.ticksize);
      bidp = quotes.bestbid(n,lb);
      bidpx = round(bidp/symbol.ticksize);
      askp = quotes.bestask(n,lb);
      askpx = round(askp/symbol.ticksize);
      
      lastbuyp = bidp;
      lastsellp = askp;
      nt = Position.ntrades;
      tcol = Position.OMS(1).OMSTrades.cols;
      if nt>0
        todayidx = Position.trades(:,tcol.time)>=fix(Position.Main.time);
        if any(todayidx)
          longidx = Position.trades(:,tcol.value)>0;
          if any(longidx)
            id = find(longidx & todayidx,1,'last');
            lastbuyp = Position.trades(id,tcol.price);
          end
          shortidx = Position.trades(:,tcol.value)<0;
          if any(shortidx)
            id = find(shortidx & todayidx,1,'last');
            lastsellp = Position.trades(id,tcol.price);
          end
        end
      end
      
      spread = 2;
      Position.reqorders(:,pcol.value) = 0;
      Position.reqtrade(pcol.value) = 0;
      
      deltaerr = Position.setpositionprofile - currcontracts;
      deltaerr = round(deltaerr./symbol.lotmin).*symbol.lotmin;
      if lastbuyp~=0
        lastbuypx = round(lastbuyp/symbol.ticksize);
        bestaskpx = lastbuypx+spread;
        derr = find(deltaerr(bestaskpx:end)<0,1);
        if ~isempty(derr)
          bestaskpx = bestaskpx + derr -1;
          bestaskp = bestaskpx*symbol.ticksize;
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) =bestaskp;
          Position.reqorders(1,pcol.value) = deltaerr(bestaskpx);
        elseif deltaerr(lastpx)<0
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) =lstp;
          Position.reqorders(1,pcol.value) = deltaerr(lastpx);
        end
      else
        if deltaerr(lastpx)<0
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) =lstp;
          Position.reqorders(1,pcol.value) = deltaerr(lastpx);
        end
      end
      
      if lastsellp~=0
        lastsellpx = round(lastsellp/symbol.ticksize);
        bestbidpx = lastsellpx-spread;
        derr = find(deltaerr(1:bestbidpx)>0,1,'last');
        if ~isempty(derr)
          bestbidpx = derr;
          bestbidp = bestbidpx*symbol.ticksize;
          Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(2,pcol.price) =bestbidp;
          Position.reqorders(2,pcol.value) = deltaerr(bestbidpx);
        elseif deltaerr(lastpx)>0
          Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(2,pcol.price) =lstp;
          Position.reqorders(2,pcol.value) = deltaerr(lastpx);
        end
      else
        if deltaerr(lastpx)>0
          Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(2,pcol.price) =lstp;
          Position.reqorders(2,pcol.value) = deltaerr(lastpx);
        end
      end
    else
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      pcol = Position.IO.cols;
      tags = Position.IO.tags;
      if currcontracts~=0
        tagid = Position.IO.tagid;
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        if -currcontracts>0
          Position.reqtrade(pcol.price) = ...
            quotes.close(n,lastbar)+2*symbol.ticksize;
          Position.reqtrade(pcol.value) = -currcontracts;
        else
          Position.reqtrade(pcol.price) = ...
            quotes.close(n,lastbar)-2*symbol.ticksize;
          Position.reqtrade(pcol.value) = -currcontracts;
        end
      else
        Position.reqtrade(pcol.value) = 0;
      end
    end
    
  end
end