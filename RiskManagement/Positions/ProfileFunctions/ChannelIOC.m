function ChannelIOC( Position )
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
      contracts = round(contracts/symbol.lotmin)*symbol.lotmin;
      symbol = Position.Symbol;
      np = Position.npos;
      tcol = Position.OMS(1).OMSTrades.cols;
      if Position.ntrades>0
        currcontracts = Position.contracts(Position.ntrades);
      else
        currcontracts = 0;
      end
      lb=lastbar;
      lstp = quotes.close(n,lb);
      maxp = quotes.max(n,lb);
      minp = quotes.min(n,lb);
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
      if maxp>symbol.filters.channelup+symbol.ticksize
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = lstp+symbol.ticksize;
        Position.reqtrade(pcol.value) = contracts-currcontracts;
      elseif minp<symbol.filters.channeldn-symbol.ticksize
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.price) = lstp-symbol.ticksize;
        Position.reqtrade(pcol.value) = -contracts-currcontracts;
      elseif (currcontracts>0 && lstp<=symbol.filters.channelmid) ||...
           (currcontracts<0 && lstp>=symbol.filters.channelmid)
        Position.reqorders(:,pcol.value) = 0;
        Position.reqtrade(pcol.tag) = tagid(tags.reqlimit);
        Position.reqtrade(pcol.value) = -currcontracts;
        if -currcontracts>0
          Position.reqtrade(pcol.price) = lstp+symbol.ticksize;
        else
          Position.reqtrade(pcol.price) = lstp-symbol.ticksize;
        end
      else
        Position.reqtrade(pcol.value) = 0;
      end
    else
      tcol = Position.OMS(1).OMSTrades.cols;
      Position.setpositionprofile=zeros(size(Position.setpositionprofile));
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