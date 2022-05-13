function Template_ProfileReturn(curr_fig, cfighandles, Market)
if ~isempty(cfighandles.symbol)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    px = quotes.close(n,1:quotes.lastbar(n,end));
    px(quotes.openbar(n,2:end-1)-1) = NaN;
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],px,...
      'g','LineWidth',2);
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'g',...
      'LineWidth',3);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'b^','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'rv','LineWidth',2);
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
      1.0025*max(quotes.max(n,firstplot:quotes.lastbar(n,end)))]);
    set(cfighandles.ax_time_price, 'Color', [0 0 0]);
    set(cfighandles.ax_time_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'LineWidth', 2);
    set(cfighandles.ax_time_price, 'Fontsize', 10.5);
    set(cfighandles.ax_time_price, 'XGrid', 'on');
    set(cfighandles.ax_time_price, 'YGrid', 'on');
    set(cfighandles.ax_time_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_price, 'YMinorGrid', 'off');
  else
    position = cfighandles.Position;
    if ~isempty(position)
      if position.ntrades>0
        tcol = position.OMS(1).OMSTrades.cols;
        longidx = position.trades(:,tcol.value)>0;
        if any(longidx)
          cfighandles.ax_time_price.Children(2).XData=...
            position.trades(longidx,tcol.id);
          cfighandles.ax_time_price.Children(2).YData=...
            position.trades(longidx,tcol.price); 
        end
        shortidx = position.trades(:,tcol.value)<0;
        if any(shortidx)
          cfighandles.ax_time_price.Children(1).XData=...
            position.trades(shortidx,tcol.id);
          cfighandles.ax_time_price.Children(1).YData=...
            position.trades(shortidx,tcol.price); 
        end
      end
    end
    cfighandles.ax_time_price.Children(3).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(3).YData=...
      quotes.close(n,quotes.firstbar(end):quotes.lastbar(n,end));
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,end)-firstplot)*0.05);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot quotes.lastbar(n,end)+shiftt]);
    set(cfighandles.ax_time_price, 'Ylim',...
      [0.9975*min(quotes.close(n,firstplot:quotes.lastbar(n,end))),...
      1.0025*max(quotes.max(n,firstplot:quotes.lastbar(n,end)))]);
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
    
    set(cfighandles.ax_volume_price, 'XGrid', 'on');
    set(cfighandles.ax_volume_price, 'YGrid', 'on');
    set(cfighandles.ax_volume_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_volume_price, 'YMinorGrid', 'off');
  else
    
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    position = cfighandles.Position;
    if ~isempty(position)
      np=position.npos;
      stairs(cfighandles.ax_time_volume,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.rlogaccum(np,1:quotes.lastbar(n,end)),...
        'c','LineWidth',2);
    end
    stairs(cfighandles.ax_time_volume,[nan nan],[nan nan],...
      'c','LineWidth',2);
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
    
    set(cfighandles.ax_time_volume, 'XGrid', 'on');
    set(cfighandles.ax_time_volume, 'YGrid', 'on');
    set(cfighandles.ax_time_volume, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_volume, 'YMinorGrid', 'off');
    
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  else
    if ~isempty(position)
      np=position.npos;
      if size(cfighandles.ax_time_volume.Children(1).XData,2)<...
          quotes.lastbar(n,end)
      cfighandles.ax_time_volume.Children(1).XData=...
        [quotes.firstbar(end):quotes.lastbar(n,end)];
      cfighandles.ax_time_volume.Children(1).YData=...
        symbol.positions.rlogaccum...
        (np,quotes.firstbar(end):quotes.lastbar(n,end)); 
      end
    end
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
end

