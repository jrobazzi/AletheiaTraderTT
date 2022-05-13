function LongFlyLimit( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end)-1;
  if openbar > 0
    firstbar = quotes.firstbar(end);
    lastbar = quotes.lastbar(n,end);
    finalchannelid = openbar + ...
      round((0.00694444444444444-quotes.dt)/quotes.dt);
    closepositionid = openbar + ...
      round((datenum(0,0,0,7,15,0)-quotes.dt)/quotes.dt);
    finalpositionid =  openbar + ...
      round((datenum(0,0,0,8,00,0)-quotes.dt)/quotes.dt);
    fadePos = (finalpositionid-lastbar)/(finalpositionid-closepositionid);
    fadePos = min(fadePos,1);
    fadePos = max(fadePos,0);
    if lastbar>=finalchannelid && lastbar<=finalpositionid
      pcol = Position.IO.cols;
      tags = Position.IO.tags;
      tagid = Position.IO.tagid;
      q = symbol.tickvalue/symbol.ticksize;
      contracts = Position.alocation(pcol.value)/...
        quotes.close(n,firstbar-1)/q;
      contracts = contracts*fadePos;
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
      spread = round(contracts*.05);
      Position.reqorders(:,pcol.value) = 0;
      Position.reqtrade(pcol.value) = 0;
      deltaerr = Position.setpositionprofile(lastpx) - currcontracts;
      deltaerr = round(deltaerr/symbol.lotmin)*symbol.lotmin;
      if abs(deltaerr)>=symbol.lotmin
        Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        if deltaerr>0
          Position.reqorders(1,pcol.price) =lstp-symbol.ticksize;
        elseif deltaerr<0
          Position.reqorders(1,pcol.price) =lstp+symbol.ticksize;
        end
        Position.reqorders(1,pcol.value) = deltaerr;
      end
      %{
      if bidpx~=0
        deltaerr = Position.setpositionprofile(bidpx) - currcontracts;
        deltaerr = round(deltaerr/symbol.lotmin)*symbol.lotmin;
        if deltaerr>0
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = bidp;
          Position.reqorders(1,pcol.value) = deltaerr;
        end
      end
      
      if askpx~=0
        deltaerr = Position.setpositionprofile(askpx) - currcontracts;
        deltaerr = round(deltaerr/symbol.lotmin)*symbol.lotmin;
        if deltaerr<0
          Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(2,pcol.price) = askp;
          Position.reqorders(2,pcol.value) = deltaerr;
        end
      end
      %}
    else
      tcol = Position.OMS(1).OMSTrades.cols;
      pcol = Position.IO.cols;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
        tags = Position.IO.tags;
        tagid = Position.IO.tagid;
      if currcontracts>0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = ...
            quotes.close(n,lastbar)-2*symbol.ticksize;
        Position.reqtrade(pcol.value) = -currcontracts;
      elseif currcontracts<0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = ...
            quotes.close(n,lastbar)+2*symbol.ticksize;
        Position.reqtrade(pcol.value) = -currcontracts;
      else
        Position.reqtrade(pcol.value) = 0;
        Position.reqorders(:,pcol.value) = 0;
      end
      Position.setpositionprofile(1:end)=0;
    end
  end
end