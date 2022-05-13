function Channel( Position )
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
      if currcontracts==0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqorders(1,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(1,pcol.price) = ...
          symbol.filters.channelup + symbol.ticksize;
        Position.reqorders(1,pcol.value) = contracts;

        Position.reqorders(2,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(2,pcol.price) =...
          symbol.filters.channeldn - symbol.ticksize;
        Position.reqorders(2,pcol.value) = -contracts;
        
        Position.reqtrade(pcol.value) = 0;
      elseif currcontracts > 0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqorders(1,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(1,pcol.price) = ...
          symbol.filters.channelup + symbol.ticksize;
        Position.reqorders(1,pcol.value) = contracts-currcontracts;

        Position.reqorders(2,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(2,pcol.price) = symbol.filters.channelmid;
        Position.reqorders(2,pcol.value) = -currcontracts;

        Position.reqorders(3,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(3,pcol.price) = ...
          symbol.filters.channeldn - symbol.ticksize;
        Position.reqorders(3,pcol.value) = -contracts;
        
        Position.reqtrade(pcol.value) = 0;
      elseif currcontracts < 0
        Position.reqorders(:,pcol.value) = 0;
        Position.reqorders(1,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(1,pcol.price) =...
          symbol.filters.channelup + symbol.ticksize;
        Position.reqorders(1,pcol.value) = contracts;

        Position.reqorders(2,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(2,pcol.price) = symbol.filters.channelmid;
        Position.reqorders(2,pcol.value) = -currcontracts;

        Position.reqorders(3,pcol.tag) = tagid(tags.reqstop);
        Position.reqorders(3,pcol.price) =...
          symbol.filters.channeldn - symbol.ticksize;
        Position.reqorders(3,pcol.value) = -contracts-currcontracts;
        
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