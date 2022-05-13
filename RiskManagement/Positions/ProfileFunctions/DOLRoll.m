function DOLRoll( Position )
  pcol = Position.IO.cols;
  tags = Position.IO.tags;
  tagid = Position.IO.tagid;
  tcol = Position.OMS(1).OMSTrades.cols;
  Position.reqtrade(pcol.value) = 0;
  Position.reqorders(:,pcol.value) = 0;
  rollpoints=23.0; 
  rollposition=85;
  
  first=[];next=[];roll=[];
  sfirst='DOLM17';snext='DOLN17';sroll='DR1M17N17';
  fid=0;nid=0;rid=0;
  main = Position.Main;
  for i=1:length(main.Symbols)
    if strcmp(main.Symbols(i).symbol,sfirst)
      fid=i;first=main.Symbols(i);
    elseif strcmp(main.Symbols(i).symbol,snext)
      nid=i;next=main.Symbols(i);
    elseif strcmp(main.Symbols(i).symbol,sroll)
      rid=i;roll=main.Symbols(i);
    end
  end
  for i=1:length(first.Positions)
    if strcmp(first.Positions(i).Strategy.strategy,'DOLRoll')
      firstpos = first.Positions(i);
      break;
    end
  end
  for i=1:length(next.Positions)
    if strcmp(next.Positions(i).Strategy.strategy,'DOLRoll')
      nextpos = next.Positions(i);
      break;
    end
  end
  
  if firstpos.ntrades>0
    firstcontracts = firstpos.contracts(firstpos.ntrades);
    firstavg = firstpos.avgprice(firstpos.ntrades);
    firsttrade = firstpos.trades(firstpos.ntrades,tcol.price);
  else
    firstcontracts = 0;
    firstavg=0;
  end
  if nextpos.ntrades>0
    nextcontracts = nextpos.contracts(nextpos.ntrades);
    nextavg = nextpos.avgprice(nextpos.ntrades);
    nexttrade = nextpos.trades(nextpos.ntrades,tcol.price);
  else
    nextcontracts = 0;
    nextavg = 0;
  end
  
  symbol = Position.Symbol;
  n=symbol.n;
  
  if roll.bestbid ~=0
    %rollpoints = floor(roll.bestbid/symbol.ticksize)*symbol.ticksize;
  end
  
  
          
  if n==nid
    if nextcontracts<rollposition
      if next.bestask~=0
        deltacontracts = 0 - (nextcontracts+firstcontracts);
        if deltacontracts>0
          nextbid = floor((firsttrade+rollpoints)/symbol.ticksize)*symbol.ticksize;
          Position.reqorders(1,pcol.price) = nextbid+0*symbol.ticksize;
          Position.reqorders(1,pcol.value) = symbol.lotmin;
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        elseif first.bestbid~=0
          nextbid = first.bestbid+rollpoints-0*next.ticksize;
          %nextbid = ((first.bestbid+rollpoints)*symbol.lotmin + ...
          %  nextavg*nextcontracts)/(nextcontracts+symbol.lotmin);
          Position.reqorders(1,pcol.price) = nextbid;
          Position.reqorders(1,pcol.value) = symbol.lotmin;
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        end
      end
    end
  elseif n==fid
    if firstcontracts>-rollposition
      if first.bestbid~=0
        deltacontracts = 0 - (nextcontracts+firstcontracts);
        if deltacontracts<0
          firstask = ceil((nexttrade-rollpoints)/symbol.ticksize)*symbol.ticksize;
          Position.reqorders(1,pcol.price) = firstask+1*symbol.ticksize;
          Position.reqorders(1,pcol.value) = -symbol.lotmin;
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        elseif next.bestask~=0
          firstask = next.bestask-rollpoints+0*next.ticksize;
          Position.reqorders(1,pcol.price) = firstask;
          Position.reqorders(1,pcol.value) = -symbol.lotmin;
          Position.reqorders(1,pcol.tag) = tagid(tags.reqlimit);
        end
      end
      
    end
  end
  
end