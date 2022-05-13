function ShortVol( Position )
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
        if lastpx < avgpx
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lowrpx;
          Position.reqorders(1,pcol.value) = contracts;
        end
        if lastpx > avgpx
          Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(2,pcol.price) = upprpx;
          Position.reqorders(2,pcol.value) = -contracts;
        end
        Position.reqtrade(pcol.value) = 0;
      elseif currcontracts > 0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        Position.reqorders(1,pcol.price) = lowrpx;
        Position.reqorders(1,pcol.value) = contracts-currcontracts;

        Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
        Position.reqorders(2,pcol.price) = avgpx;
        Position.reqorders(2,pcol.value) = -currcontracts;
        
        Position.reqtrade(pcol.value) = 0;
      elseif currcontracts < 0
        Position.reqorders(:,pcol.value) = 0;
        
        Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        Position.reqorders(1,pcol.price) = avgpx;
        Position.reqorders(1,pcol.value) = -currcontracts;

        Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
        Position.reqorders(2,pcol.price) = upprpx;
        Position.reqorders(2,pcol.value) = -contracts-currcontracts;
        
        Position.reqtrade(pcol.value) = 0;
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