function ShortVolProfileExitLimit( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end);
  if openbar > 0
    lastbar = quotes.lastbar(n,end);
    finalchannelid = openbar + ...
      round((datenum(0,0,0,0,1,0)-quotes.dt)/quotes.dt);
    closepositionid = openbar + ...
      round((datenum(0,0,0,8,30,0)-quotes.dt)/quotes.dt);
    if lastbar>=finalchannelid && lastbar<=closepositionid
      pcol = Position.IO.cols;
      tags = Position.IO.tags;
      tagid = Position.IO.tagid;
      q = symbol.tickvalue/symbol.ticksize;
      lastpx = quotes.close(n,lastbar);
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
      avgpx = quotes.close(n,openbar)*...
        exp(symbol.filters.reversionavg(lastbar));
      avgpx = round(avgpx/symbol.ticksize)*symbol.ticksize;
      upprpx = quotes.close(n,openbar)*...
        exp(symbol.filters.reversionavg(lastbar)+...
            symbol.filters.sigreversion(end));
      upprpx = floor(upprpx/symbol.ticksize)*symbol.ticksize;
      lowrpx = quotes.close(n,openbar)*...
        exp(symbol.filters.reversionavg(lastbar)-...
            symbol.filters.sigreversion(end));
      lowrpx = ceil(lowrpx/symbol.ticksize)*symbol.ticksize;
      dist=(quotes.rlogintraday(n,lastbar)-...
        symbol.filters.reversionavg(lastbar))/...
        symbol.filters.sigreversion(end);
      %% SETPOSITIONPROFILE
      upprid = round(upprpx/symbol.ticksize);
      avgid = round(avgpx/symbol.ticksize);
      lowrid = round(lowrpx/symbol.ticksize);
      if currcontracts>0
        Position.setpositionprofile(upprid+1:end)=-contracts;
        Position.setpositionprofile(avgid:upprid)=0;
        Position.setpositionprofile(lowrid:avgid-1)=currcontracts;
        Position.setpositionprofile(1:lowrid-1)=contracts;
      elseif currcontracts<0
        Position.setpositionprofile(upprid+1:end)=-contracts;
        Position.setpositionprofile(avgid:upprid)=currcontracts;
        Position.setpositionprofile(lowrid:avgid-1)=0;
        Position.setpositionprofile(1:lowrid-1)=contracts;
      else
        Position.setpositionprofile(upprid+1:end)=-contracts;
        Position.setpositionprofile(lowrid:upprid)=0;
        Position.setpositionprofile(1:lowrid-1)=contracts;
      end
      %% SET REQTRADE
      if currcontracts==0
        Position.reqorders(:,pcol.value) = 0;
        if lastpx < lowrpx
          Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
          Position.reqtrade(pcol.price) = lastpx+2*symbol.ticksize;
          Position.reqtrade(pcol.value) = contracts;
        elseif lastpx > upprpx
          Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
          Position.reqtrade(pcol.price) = lastpx-2*symbol.ticksize;
          Position.reqtrade(pcol.value) = -contracts;
        else
          Position.reqtrade(pcol.value) = 0;
        end
      elseif currcontracts > 0
        Position.reqorders(:,pcol.value) = 0;
        if lastpx < lowrpx
          Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
          Position.reqtrade(pcol.price) = lastpx+2*symbol.ticksize;
          Position.reqtrade(pcol.value) = contracts-currcontracts;
        else
          if dist>0
            deltaref = 0;
          elseif abs(dist)<0.9
            deltaref = min(currcontracts,abs(dist)*contracts);
          else
            deltaref = currcontracts;
          end
          deltaref = round(deltaref/symbol.lotmin)*symbol.lotmin;
          gamma = deltaref - currcontracts;
          if abs(gamma)>=symbol.lotmin
            Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
            Position.reqtrade(pcol.price) = lastpx-2*symbol.ticksize;
            Position.reqtrade(pcol.value) = gamma;
          else
            Position.reqtrade(pcol.value) = 0;
          end
        end
      elseif currcontracts < 0
        Position.reqorders(:,pcol.value) = 0;
        if lastpx > upprpx
          Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
          Position.reqtrade(pcol.price) = lastpx-2*symbol.ticksize;
          Position.reqtrade(pcol.value) = -contracts-currcontracts;
        else
          if dist<0
            deltaref = 0;
          elseif abs(dist)<0.9
            deltaref = max(currcontracts,-abs(dist)*contracts);
          else
            deltaref = currcontracts;
          end
          deltaref = round(deltaref/symbol.lotmin)*symbol.lotmin;
          gamma = deltaref - currcontracts;
          if abs(gamma)>=symbol.lotmin
            Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
            Position.reqtrade(pcol.price) = lastpx+2*symbol.ticksize;
            Position.reqtrade(pcol.value) = gamma;
          else
            Position.reqtrade(pcol.value) = 0;
          end
        end
      end
    else
      tcol = Position.OMS(1).OMSTrades.cols;
      pcol = Position.IO.cols;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      if currcontracts~=0
        tags = Position.IO.tags;
        tagid = Position.IO.tagid;
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = quotes.close(n,lastbar);
        Position.reqtrade(pcol.value) = -currcontracts;
      else
        Position.reqtrade(pcol.value) = 0;
        Position.reqorders(:,pcol.value) = 0;
      end
      Position.setpositionprofile(1:end)=0;
    end
    
  end
end