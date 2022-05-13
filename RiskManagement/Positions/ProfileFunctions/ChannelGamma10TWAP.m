function ChannelGamma10TWAP( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end);
  if openbar > 0
    lastbar = quotes.lastbar(n,end);
    finalchannelid = openbar + ...
      round((datenum(0,0,0,0,10,0)-quotes.dt)/quotes.dt);
    closepositionid = openbar + ...
      round((datenum(0,0,0,8,0,0)-quotes.dt)/quotes.dt);
    finalpositionid =  openbar + ...
      round((datenum(0,0,0,8,50,0)-quotes.dt)/quotes.dt);
    fadePos = (finalpositionid-lastbar)/(finalpositionid-closepositionid);
    fadePos = min(fadePos,1);
    fadePos = max(fadePos,0);
    if lastbar>=finalchannelid && lastbar<=finalpositionid
      symbol.filters.channelup=max(quotes.max(n,openbar:finalchannelid));
      symbol.filters.channeldn=min(quotes.min(n,openbar:finalchannelid));
      symbol.filters.channelmid=...
        (symbol.filters.channelup+symbol.filters.channeldn)/2;
      symbol.filters.channelmid=...
        symbol.RoundPrice(symbol.filters.channelmid);
      pcol = Position.IO.cols;
      tags = Position.IO.tags;
      tagid = Position.IO.tagid;
      q = symbol.tickvalue/symbol.ticksize;
      firstbar = quotes.firstbar(end);
      contracts = Position.alocation(pcol.value)/...
        quotes.close(n,firstbar-1)/q;
      contracts = contracts*fadePos;
      contracts = round(contracts/symbol.lotmin)*symbol.lotmin;
      maxgamma = round((contracts/10)/symbol.lotmin)*symbol.lotmin;
      %maxgamma = symbol.lotmin;
      symbol = Position.Symbol;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      %% SETPOSITIONPROFILE
      chupid = round(symbol.filters.channelup/symbol.ticksize);
      chdnid = round(symbol.filters.channeldn/symbol.ticksize);
      chmidid = round(symbol.filters.channelmid/symbol.ticksize);
      if currcontracts>0
        Position.setpositionprofile(chupid+1:end)=contracts;
        Position.setpositionprofile(chmidid:chupid)=currcontracts;
        Position.setpositionprofile(chdnid:chmidid-1)=0;
        Position.setpositionprofile(1:chdnid-1)=-contracts;
      elseif currcontracts<0
        Position.setpositionprofile(chupid+1:end)=contracts;
        Position.setpositionprofile(chmidid+1:chupid)=0;
        Position.setpositionprofile(chdnid:chmidid)=currcontracts;
        Position.setpositionprofile(1:chdnid-1)=-contracts;
      else
        Position.setpositionprofile(chupid+1:end)=contracts;
        Position.setpositionprofile(chdnid:chupid)=0;
        Position.setpositionprofile(1:chdnid-1)=-contracts;
      end
      %% SET REQTRADE
      t = quotes.lastbar(n,end);
      lstp = quotes.close(n,t);
      maxp = quotes.max(n,t);
      minp = quotes.min(n,t);
      Position.reqorders(:,pcol.value) = 0;
      Position.reqtrade(pcol.value) = 0;
      if currcontracts==0
        if maxp>symbol.filters.channelup
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = contracts - currcontracts;
          if cts > maxgamma
            cts = maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
        elseif minp<symbol.filters.channeldn
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = -contracts - currcontracts;
          if cts < -maxgamma
            cts = -maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
        end
      elseif currcontracts > 0
        if maxp>symbol.filters.channelup
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = contracts - currcontracts;
          if cts > maxgamma
            cts = maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
        elseif minp<=symbol.filters.channelmid
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = 0 - currcontracts;
          if cts < -maxgamma
            cts = -maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
        end
      elseif currcontracts < 0
        if minp<symbol.filters.channeldn
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = -contracts - currcontracts;
          if cts < -maxgamma
            cts = -maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
        elseif maxp>=symbol.filters.channelmid
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
          Position.reqorders(1,pcol.price) = lstp;
          cts = 0 - currcontracts;
          if cts > maxgamma
            cts = maxgamma;
          end
          Position.reqorders(1,pcol.value) = cts;
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