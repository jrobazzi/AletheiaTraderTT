function Tendencias_Juros( Position )
  symbol = Position.Symbol;
  %{
  ts15 = symbol.Bars(1);
  dtclose = ts15.buffer.alltag('dtclose','price');
  dtmax = ts15.buffer.alltag('dtmax','price');
  dtmin = ts15.buffer.alltag('dtmin','price');
  dttime = ts15.buffer.alltag('dtclose','time');
  
  if ~isempty(dtclose)
    dtsec=datenum(0,0,0,0,0,ts15.dtsec);
    elapsedt = dttime(end)-dttime(1)-dtsec;
    if elapsedt >= datenum(0,0,0,0,1,0) && elapsedt < datenum(0,0,0,9,0,0)
      
      pcol = Position.buffer.cols;
      pcolcount = Position.buffer.cols_count;
      tag = Position.buffer.tags;
      tagid = Position.buffer.tagid;
      tcol = Position.Trades.buffer.cols;
      nt = Position.Trades.ntrades;
      lastp = Position.Symbol.Bars(1).dtclose.price;
      tsize = Position.Symbol.ticksize;
      q = Position.Symbol.tickvalue/Position.Symbol.ticksize;
      riskcontracts = Position.equitymax(pcol.value)/(q*lastp);
      riskcontracts = ceil(riskcontracts/Position.Symbol.lotmin)...
        *Position.Symbol.lotmin;
      currpos.value = Position.Trades.positioncontracts(nt,tcol.value);
      currpos.price = Position.Trades.positioncontracts(nt,tcol.price);
      currpos.weight = abs(currpos.value)/riskcontracts;
      upprpx = floor(ts15.dt.uppr(end)/Position.Symbol.ticksize)*Position.Symbol.ticksize;
      lowrpx = ceil(ts15.dt.lowr(end)/Position.Symbol.ticksize)*Position.Symbol.ticksize;
      fastpx = round(ts15.dt.dfast(end)/Position.Symbol.ticksize)*Position.Symbol.ticksize;
      
      
      sig = ts15.sig;  
      if ~isempty(ts15.dt.dfast)
        if currpos.value == 0
          Position.reqorders = zeros(1,pcolcount);
          currord =1;
          Position.reqorders(currord,pcol.price) = upprpx;
          Position.reqorders(currord,pcol.value) = -riskcontracts;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          
          currord =2;
          Position.reqorders(currord,pcol.price) = lowrpx;
          Position.reqorders(currord,pcol.value) = riskcontracts;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          
          Position.reqorders = sortrows(Position.reqorders,-pcol.price);
        elseif  currpos.value > 0
          Position.reqorders = zeros(1,pcolcount);
          currord =1;
          Position.reqorders(currord,pcol.price) = fastpx;
          Position.reqorders(currord,pcol.value) = -currpos.value;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          Position.reqorders = sortrows(Position.reqorders,-pcol.price);
          
          currord =2;
          Position.reqorders(currord,pcol.price) = upprpx;
          Position.reqorders(currord,pcol.value) = -riskcontracts;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          Position.reqorders = sortrows(Position.reqorders,-pcol.price);
        elseif  currpos.value < 0
          Position.reqorders = zeros(1,pcolcount);
          currord =1;
          Position.reqorders(currord,pcol.price) = fastpx;
          Position.reqorders(currord,pcol.value) = -currpos.value;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          Position.reqorders = sortrows(Position.reqorders,-pcol.price);
          
         currord =2;
          Position.reqorders(currord,pcol.price) = lowrpx;
          Position.reqorders(currord,pcol.value) = riskcontracts;
          Position.reqorders(currord,pcol.tag) = tagid(tag.reqlimit);
          Position.reqorders = sortrows(Position.reqorders,-pcol.price);
        end
        
      elseif elapsedt >= datenum(0,0,0,8,50,0)
        tcol = Position.Trades.buffer.cols;
        nt = Position.Trades.ntrades;
        pcol = Position.buffer.cols;
        tag = Position.buffer.tags;
        tagid = Position.buffer.tagid;
        currpos.value = Position.Trades.positioncontracts(nt,tcol.value);
        if currpos.value>0
          Position.reqtrade(pcol.price) = dtclose(end)-Position.Symbol.ticksize*5;
          Position.reqtrade(pcol.value) = -currpos.value;
          Position.reqtrade(pcol.tag) = tagid(tag.reqlimit);
        elseif currpos.value<0
          Position.reqtrade(pcol.price) = dtclose(end)+Position.Symbol.ticksize*5;
          Position.reqtrade(pcol.value) = -currpos.value;
          Position.reqtrade(pcol.tag) = tagid(tag.reqlimit);
        end
      end
    end
  end
  %}
end