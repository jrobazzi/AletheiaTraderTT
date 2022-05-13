function Template_Trades(curr_fig, cfighandles, Market)
  symbol = cfighandles.symbol;
  n=symbol.n;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  broker = 0;
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'c^',...
      'LineWidth',1);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'mv',...
      'LineWidth',1);
    
    hold(cfighandles.ax_time_price,'off');
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'YLimMode','manual');
    firstplot = symbol.ntrades-round(cfighandles.zoom);
    firstplot = max(firstplot,1);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot round(symbol.ntrades*1.05)]);
    set(cfighandles.ax_time_price, 'Color', [0 0 0]);
    set(cfighandles.ax_time_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'LineWidth', 2);
    set(cfighandles.ax_time_price, 'Fontsize', 10.5);
    grid(cfighandles.ax_time_price,'on');
  else
    if symbol.ntrades>0
      cols = symbol.MDTrades.cols;
      tags = symbol.MDTrades.tags;
      tagid = symbol.MDTrades.tagid;
      firstplot = symbol.ntrades-round(cfighandles.zoom);
      firstplot = max(firstplot,1);
      trades = symbol.trades(firstplot:symbol.ntrades,:);
      
      longidx =trades(:,cols.tag)==tagid(tags.agressorbuy);
      if any(longidx)
        cfighandles.ax_time_price.Children(2).XData=firstplot+find(longidx);
        cfighandles.ax_time_price.Children(2).YData=trades(longidx,cols.price);
      end
      
      shortidx =trades(:,cols.tag)==tagid(tags.agressorsell);
      if any(shortidx)
        cfighandles.ax_time_price.Children(1).XData=firstplot+find(shortidx);
        cfighandles.ax_time_price.Children(1).YData=trades(shortidx,cols.price);
      end
      set(cfighandles.ax_time_price, 'Xlim',[firstplot symbol.ntrades+10]);
      maxp = max(trades(:,cols.price))+symbol.ticksize;
      minp = min(trades(:,cols.price))-symbol.ticksize;
      set(cfighandles.ax_time_price, 'Ylim',[minp maxp]);
    end
    %{
    xticks = get(cfighandles.ax_time_price, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_price, 'XTickLabel',xticklabel);
      %}
    
  end
  %% PRICE x VALUE
  if isempty(cfighandles.ax_volume_price.Children)
    hold(cfighandles.ax_volume_price,'on');
    barh(cfighandles.ax_volume_price,[nan nan],[nan nan],'b');
    barh(cfighandles.ax_volume_price,[nan nan],[nan nan],'r');
    barh(cfighandles.ax_volume_price,[nan nan],[nan nan],'c');
    barh(cfighandles.ax_volume_price,[nan nan],[nan nan],'m');
    hold(cfighandles.ax_volume_price,'off');
    set(cfighandles.ax_volume_price, 'YAxisLocation', 'right');
    set(cfighandles.ax_volume_price, 'XAxisLocation', 'bottom');
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
    set(cfighandles.ax_volume_price, 'Color', [0 0 0]);
    set(cfighandles.ax_volume_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_volume_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_volume_price, 'LineWidth', 2);
    set(cfighandles.ax_volume_price, 'Fontsize', 10.5);
    grid(cfighandles.ax_volume_price,'on');
  else
    firstplot = symbol.ntrades-round(cfighandles.zoom);
    firstplot = max(firstplot,1);
    trades = symbol.trades(firstplot:symbol.ntrades,:);
    cols = symbol.MDTrades.cols;
    tags = symbol.MDTrades.tags;
    tagid = symbol.MDTrades.tagid;
    maxv = 0;
    imbalance = zeros(20000,1);
    if broker~=0
      buyeridx = trades(:,cols.buyfirm)==broker;
      selleridx = trades(:,cols.sellfirm)==broker;
      longidx = buyeridx & ~selleridx;
    else
      longidx =trades(:,cols.tag)==tagid(tags.agressorbuy);
    end
    if any(longidx)
      longtrades = trades(longidx,:);
      [C,ia,ic] = unique(longtrades(:,cols.price));
      longvolume = zeros(size(C,1),1);
      for i=1:length(C)
        idx = longtrades(:,cols.price)==C(i);
        if any(idx)
          volumes = longtrades(idx,cols.value);
          longvolume(i) = sum(volumes);
        else
          longvolume(i) = 0;
        end
      end
      cfighandles.ax_volume_price.Children(4).XData=C;
      cfighandles.ax_volume_price.Children(4).YData=longvolume;
      pidx = round(C./symbol.ticksize);
      imbalance(pidx) = imbalance(pidx)+ longvolume;
      maxv = max(maxv,max(longvolume));
    end
    if broker~=0
      buyeridx = trades(:,cols.buyfirm)==broker;
      selleridx = trades(:,cols.sellfirm)==broker;
      shortidx = ~buyeridx & selleridx;
    else
      shortidx =trades(:,cols.tag)==tagid(tags.agressorsell);
    end
    if any(shortidx)
      shorttrades = trades(shortidx,:);
      [C,ia,ic] = unique(shorttrades(:,cols.price));
      shortvolume = zeros(size(C,1),1);
      for i=1:length(C)
        idx = shorttrades(:,cols.price)==C(i);
        if any(idx)
          volumes = shorttrades(idx,cols.value);
          shortvolume(i) = sum(volumes);
        else
          shortvolume(i) = 0;
        end
      end
      cfighandles.ax_volume_price.Children(3).XData=C;
      cfighandles.ax_volume_price.Children(3).YData=-shortvolume;
      pidx = round(C./symbol.ticksize);
      imbalance(pidx) = imbalance(pidx)-shortvolume;
      maxv = max(maxv,max(shortvolume));
    end
    longidx = imbalance>0;
    if any(longidx)
      cfighandles.ax_volume_price.Children(2).XData=...
        find(longidx).*symbol.ticksize;
      cfighandles.ax_volume_price.Children(2).YData=imbalance(longidx);
    end
    shortidx = imbalance<0;
    if any(shortidx)
      cfighandles.ax_volume_price.Children(1).XData=...
        find(shortidx).*symbol.ticksize;
      cfighandles.ax_volume_price.Children(1).YData=imbalance(shortidx);
    end
    set(cfighandles.ax_volume_price, 'Xlim',...
      [-symbol.lotmin-maxv maxv+symbol.lotmin]);
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    hold(cfighandles.ax_time_volume,'off');
    set(cfighandles.ax_time_volume, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_volume, 'XAxisLocation', 'bottom');
    set(cfighandles.ax_time_volume, 'Xlim',...
      get(cfighandles.ax_time_price,'Xlim'));
    set(cfighandles.ax_time_volume, 'Color', [0 0 0]);
    set(cfighandles.ax_time_volume, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_volume, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_volume, 'LineWidth', 2);
    set(cfighandles.ax_time_volume, 'Fontsize', 10.5);
    grid(cfighandles.ax_time_volume,'on');
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    %{
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
      %}
  else
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    %{
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
      %}
  end
  guidata(curr_fig,cfighandles);
end

