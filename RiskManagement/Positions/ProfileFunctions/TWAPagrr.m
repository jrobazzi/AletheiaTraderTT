function TWAP( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  ob = quotes.openbar(n,end);
  
  contracts = -1000;
  starttime = datenum(0,0,0,12,18,0);
  finaltime = datenum(0,0,0,14,30,0);
  maxgamma = symbol.lotmin;
  minsell = 9.0;
  maxbuy = 10.0;
  
  pcol = Position.IO.cols;
  tags = Position.IO.tags;
  tagid = Position.IO.tagid;
  Position.setpositionprofile(1:end)=0;
  Position.reqtrade(pcol.value) = 0;
  Position.reqorders(:,pcol.value) = 0;
  
  if ob > 0
    if Position.ntrades>0
      currcontracts = Position.contracts(Position.ntrades);
    else
      currcontracts = 0;
    end
    hnow = symbol.Main.time-fix(symbol.Main.time);
    fadeIN = (hnow-starttime)/(finaltime-starttime);
    fadeIN = min(fadeIN,1);
    fadeIN = max(fadeIN,0);
    gamma = contracts*fadeIN - currcontracts;
    Position.setpositionprofile(1:end)=contracts*fadeIN;
    if abs(gamma)>maxgamma
      gamma = sign(gamma)*maxgamma;
    end
    gamma = ceil(gamma/symbol.lotmin)*symbol.lotmin;
    if gamma~=0
      mid=(symbol.bestask+symbol.bestbid)/2;
      if gamma>0 && contracts>0
        Position.reqorders(1,pcol.price) = ...
          ceil(mid/symbol.ticksize)*symbol.ticksize;
      elseif gamma<0 && contracts<0
        Position.reqorders(1,pcol.price) = ...
          floor(mid/symbol.ticksize)*symbol.ticksize;
      end
      Position.reqorders(1,pcol.value) = gamma;
      Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
    end
  end
end