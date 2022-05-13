function LongFly( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end)-1;
  if openbar > 0
    lastbar = quotes.lastbar(n,end);
    finalchannelid = openbar + ...
      round((0.00694444444444444-quotes.dt)/quotes.dt);
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
      spread = round(contracts*.05);
      symbol = Position.Symbol;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      lb=lastbar;
      lstp = quotes.close(n,lb);
      %% SETPOSITIONPROFILE
      Position.setpositionprofile=contracts.*symbol.filters.deltaref;
      %% SET REQTRADE
      lastpx = round(lstp/symbol.ticksize);
      deltaerr = Position.setpositionprofile(lastpx) - currcontracts;
      deltaerr = round(deltaerr/symbol.lotmin)*symbol.lotmin;
      if deltaerr>=symbol.lotmin*spread
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = lstp+symbol.ticksize;
        Position.reqtrade(pcol.value) = deltaerr;
      elseif deltaerr<=-symbol.lotmin*spread
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = lstp-symbol.ticksize;
        Position.reqtrade(pcol.value) = deltaerr;
      else
        Position.reqtrade(pcol.value) = 0;
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