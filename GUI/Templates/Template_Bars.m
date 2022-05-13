function Template_Bars(curr_fig, cfighandles, Market)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    stairs(cfighandles.ax_time_price,...
      [1:quotes.lastbar(end)],quotes.close(n,1:quotes.lastbar(end)),'g',...
      'LineWidth',2);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'r',...
      'LineWidth',3);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'b',...
      'LineWidth',3);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'g',...
      'LineWidth',3);
    hold(cfighandles.ax_time_price,'off');
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'YLimMode','manual');
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot round(quotes.lastbar(n,end)*1.05)]);
    set(cfighandles.ax_time_price, 'Ylim',...
      [0.9975*min(quotes.close(n,firstplot:quotes.lastbar(n,end))),...
      1.0025*max(quotes.close(n,firstplot:quotes.lastbar(n,end)))]);
    set(cfighandles.ax_time_price, 'Color', [0 0 0]);
    set(cfighandles.ax_time_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'LineWidth', 2);
    set(cfighandles.ax_time_price, 'Fontsize', 10.5);
    grid(cfighandles.ax_time_price,'on');
  else
    cfighandles.ax_time_price.Children(1).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(1).YData=...
      quotes.close(n,quotes.firstbar(end):quotes.lastbar(n,end));
    cfighandles.ax_time_price.Children(2).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(2).YData=...
      quotes.max(n,quotes.firstbar(end):quotes.lastbar(n,end));
    cfighandles.ax_time_price.Children(3).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(3).YData=...
      quotes.min(n,quotes.firstbar(end):quotes.lastbar(n,end));
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,end)-firstplot)*0.05);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot quotes.lastbar(n,end)+shiftt]);
    set(cfighandles.ax_time_price, 'Ylim',...
      [0.9975*min(quotes.close(n,firstplot:quotes.lastbar(n,end))),...
      1.0025*max(quotes.close(n,firstplot:quotes.lastbar(n,end)))]);
    xticks = get(cfighandles.ax_time_price, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_price, 'XTickLabel',xticklabel);
  end
  %% PRICE x VALUE
  if isempty(cfighandles.ax_volume_price.Children)
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
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  else
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  end
  guidata(curr_fig,cfighandles);
end

