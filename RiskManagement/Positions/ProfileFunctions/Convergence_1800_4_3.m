function Convergence_1800_4_3( Position )
  symbol = Position.Symbol;
  n=symbol.n;
  quotes = Position.Main.quotes;
  openbar = quotes.openbar(n,end)-1;
  firstbar= quotes.firstbar(end);
  lb= quotes.lastbar(n,end);
  
  tauMA = 1800*1;sigref = 4;spread = 3; slip=2;
  nma = find(symbol.filters.tau == tauMA);
  sigMA = symbol.filters.sig(end,nma);
  %nnidx = symbol.filters.sig(:,nma)~=0;
  %sigMA = mean(symbol.filters.sig(nnidx,nma));
  longsigref = sigref;
  inLong=-longsigref; outLong=0; 
  inLongExp = spread; outLongExp = 1/inLongExp;
  shortsigref = sigref;
  inShort=shortsigref; outShort=0; 
  inShortExp = spread; outShortExp=1/inShortExp;
  
  if openbar > 0
    pcol = Position.IO.cols;
    tags = Position.IO.tags;
    tagid = Position.IO.tagid;
    q = symbol.tickvalue/symbol.ticksize;
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
    %long
    lstp = quotes.close(n,lb);
    if (symbol.bestbid~=0 && symbol.bestask~=0) && ...
        symbol.bestbid<symbol.bestask
      lstp = (symbol.bestbid+symbol.bestask)/2;
    end
    lstpx = round(lstp/symbol.ticksize);
    avgp = symbol.filters.avg(lb,nma);
    avgpx = round(avgp/symbol.ticksize);
    
    maxlongp = -sigref*sigMA*avgp+avgp;
    maxlongpx = round(maxlongp/symbol.ticksize);
    maxshortp = sigref*sigMA*avgp+avgp;
    maxshortpx = round(maxshortp/symbol.ticksize);
    steppx = abs(inLong-outLong)/abs(maxlongpx-avgpx);
    xLong = inLong:steppx:outLong;
    inLongRef = (1-(abs(xLong-inLong)./abs(outLong-inLong))).^inLongExp;
    inLongRef = inLongRef.*contracts;
    outLongRef = (1-(abs(xLong-inLong)./abs(outLong-inLong))).^outLongExp;
    outLongRef = outLongRef.*contracts;
    
    maxshortp = -sigref*sigMA*avgp+avgp;
    maxshortpx = round(maxshortp/symbol.ticksize);
    maxshortp = sigref*sigMA*avgp+avgp;
    maxshortpx = round(maxshortp/symbol.ticksize);
    steppx = abs(inShort-outShort)/abs(maxshortpx-avgpx);
    xShort = outShort:steppx:inShort;
    inShortRef =...
      -((abs(xShort-outShort)./abs(inShort-outShort))).^inShortExp;
    inShortRef = inShortRef.*contracts;
    outShortRef = ...
      -((abs(xShort-outShort)./abs(inShort-outShort))).^outShortExp;
    outShortRef = outShortRef.*contracts;
    
    if currcontracts>0
      ccpx = find(inLongRef>=currcontracts,1,'last');
      outpx = find(outLongRef<=currcontracts,1,'first');
      npx = length(inLongRef);
      
      Position.setpositionprofile(avgpx-npx+outpx:avgpx)=outLongRef(outpx:npx);
      Position.setpositionprofile(avgpx-npx+ccpx:avgpx-npx+outpx-1)=currcontracts;
      Position.setpositionprofile(maxlongpx:avgpx-npx+ccpx-1)=inLongRef(2:ccpx);
      Position.setpositionprofile(1:maxlongpx-1) = contracts;
      
      Position.setpositionprofile(avgpx:maxshortpx) = inShortRef;
      Position.setpositionprofile(maxshortpx+1:end) = -contracts;
    elseif currcontracts<0
      ccpx = find(inShortRef<=currcontracts,1,'first');
      outpx = find(outShortRef>=currcontracts,1,'last');
      
      Position.setpositionprofile(avgpx:avgpx+outpx-1)=outShortRef(1:outpx);
      Position.setpositionprofile(avgpx+outpx:avgpx+ccpx-1)=currcontracts;
      Position.setpositionprofile(avgpx+ccpx:maxshortpx)=inShortRef(ccpx:end-1);
      Position.setpositionprofile(maxshortpx+1:end) = -contracts;
      
      Position.setpositionprofile(maxlongpx:avgpx) = inLongRef;
      Position.setpositionprofile(1:maxlongpx-1) = contracts;
    else
      if lstpx>avgpx
        Position.setpositionprofile(maxlongpx:avgpx) = inLongRef;
        Position.setpositionprofile(1:maxlongpx-1) = contracts;
        
        Position.setpositionprofile(avgpx:maxshortpx) = inShortRef;
        Position.setpositionprofile(maxshortpx+1:end) = -contracts;
      elseif lstpx<avgpx
        Position.setpositionprofile(maxlongpx:avgpx) = inLongRef;
        Position.setpositionprofile(1:maxlongpx-1) = contracts;
        
        Position.setpositionprofile(avgpx:maxshortpx) = inShortRef;
        Position.setpositionprofile(maxshortpx+1:end) = -contracts;
      else
        Position.setpositionprofile(maxlongpx:avgpx) = inLongRef;
        Position.setpositionprofile(1:maxlongpx-1) = contracts;
        
        Position.setpositionprofile(avgpx:maxshortpx) = inShortRef;
        Position.setpositionprofile(maxshortpx+1:end) = -contracts;
      end
    end
    %
    %% SET REQTRADE
    Position.reqorders(:,pcol.value) = 0;
    Position.reqtrade(pcol.value) = 0;
    %{
    deltaerr = Position.setpositionprofile(lstpx) - currcontracts;
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
    %}
    deltaerr = Position.setpositionprofile - currcontracts;
    deltaerr = round(deltaerr/symbol.lotmin)*symbol.lotmin;
    askidx = find(deltaerr<0,1,'first');
    if any(askidx)
      askpx = askidx*symbol.ticksize;
      if symbol.bestbid>0 && symbol.bestask>0
        spread = (symbol.bestask - symbol.bestbid);
        mid = (symbol.bestbid+symbol.bestask)/2;
        mid = floor(mid/symbol.ticksize)*symbol.ticksize;
        if askpx<symbol.bestbid-symbol.ticksize*10
          if spread<10*symbol.ticksize
            askpx = symbol.bestbid-1*symbol.ticksize;
          else
            askpx = mid;
          end
        end
      end
      askqty = deltaerr(askidx);
      Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
      Position.reqorders(1,pcol.price) =askpx;
      Position.reqorders(1,pcol.value) = askqty;
    end
    
    bididx = find(deltaerr>0,1,'last');
    if any(bididx)
      bidpx = bididx*symbol.ticksize;
      if symbol.bestbid>0 && symbol.bestask>0
        spread = (symbol.bestask - symbol.bestbid);
        mid = (symbol.bestbid+symbol.bestask)/2;
        mid = ceil(mid/symbol.ticksize)*symbol.ticksize;
        if bidpx>symbol.bestask+symbol.ticksize*10
          if spread<10*symbol.ticksize
            bidpx = symbol.bestask+1*symbol.ticksize;
          else
            bidpx = mid;
          end
        end
      end
      bidqty = deltaerr(bididx);
      Position.reqorders(2,pcol.tag) = tagid(tags.reqlimit);
      Position.reqorders(2,pcol.price) =bidpx;
      Position.reqorders(2,pcol.value) = bidqty;
    end
  end
end