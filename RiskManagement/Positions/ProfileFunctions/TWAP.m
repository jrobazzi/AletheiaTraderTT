function TWAP( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  ob = quotes.openbar(n,end);
  
  contracts = -690;
  inicontracts = -3400;
  contracts = inicontracts+contracts;
  starttime = datenum(0,0,0,19,50,0);
  finaltime = starttime + datenum(0,0,0,1,0,0);
  %finaltime = datenum(0,0,0,19,0,0);
  maxgamma = symbol.lotmin;
  maxagressor = maxgamma;
  maxlimit = 40;
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
    Position.setpositionprofile(1:end)=...
      (contracts-inicontracts)*fadeIN+inicontracts;
    gamma = (contracts-inicontracts)*fadeIN - (currcontracts-inicontracts);
    
    gammalimit = gamma;
    if abs(gammalimit)>maxlimit
      gammalimit = sign(gammalimit)*maxlimit;
    end
    gammalimit = ceil(gammalimit/symbol.lotmin)*symbol.lotmin;
    
    gammaagressor = gamma - gammalimit;
    if abs(gammaagressor)>maxagressor
      gammaagressor = sign(gammaagressor)*maxagressor;
    end
    gammaagressor = ceil(gammaagressor/symbol.lotmin)*symbol.lotmin;
    
    if gammaagressor~=0
      if gammaagressor>0 && contracts>0
        Position.reqorders(1,pcol.price) = symbol.bestbid+symbol.ticksize;
      elseif gammaagressor<0 && contracts<0
        Position.reqorders(1,pcol.price) = symbol.bestask-symbol.ticksize;
      end
      Position.reqorders(1,pcol.value) = gammaagressor;
      Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
    end
    
    if gammalimit~=0
      spread = symbol.bestask-symbol.bestbid;
      spread = round(spread/symbol.ticksize)*symbol.ticksize;
      if abs(spread)>symbol.ticksize
        if gammalimit>0 && contracts>0
          Position.reqorders(1,pcol.price) = symbol.bestbid+symbol.ticksize;
        elseif gammalimit<0 && contracts<0
          Position.reqorders(1,pcol.price) = symbol.bestask-symbol.ticksize;
        end
      else
        if gammalimit>0 && contracts>0
          Position.reqorders(2,pcol.price) = symbol.bestbid;
        elseif gammalimit<0 && contracts<0
          Position.reqorders(2,pcol.price) = symbol.bestask;
        end
      end
      
      Position.reqorders(2,pcol.value) = gammalimit;
      Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
    end
    
    
  end
end