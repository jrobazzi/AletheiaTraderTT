function Template_SignalsDelta(curr_fig, cfighandles, Market)
if ~isempty(cfighandles.symbol)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  
  signal = [];
  
  
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    nsig=cfighandles.popupmenu_strategies.Value;
    if nsig>1
      currsig = cfighandles.popupmenu_strategies.String{nsig};
      for sig = 1:length(symbol.signals)
        if strcmp(currsig,symbol.signals(sig).signal)
          signal = symbol.signals(sig);
          break;
        end
      end
    end
    hold(cfighandles.ax_time_price,'on');
    lb=quotes.lastbar(n,end);
    px = quotes.close(n,1:lb);
    avgpx = symbol.filters.reversionavgpx(1:lb);
    lowrpx = symbol.filters.reversionupprpx(1:lb);
    upprpx = symbol.filters.reversionlowrpx(1:lb);
    nanidx = quotes.openbar(n,2:end-1)-1;
    px(nanidx) = NaN;
    avgpx(nanidx) = NaN;
    upprpx(nanidx) = NaN;
    lowrpx(nanidx) = NaN;
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],px,...
      'g','LineWidth',2);
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],avgpx,...
      'y','LineWidth',2);
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],upprpx,...
      'w','LineWidth',2);
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],lowrpx,...
      'w','LineWidth',2);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'g','LineWidth',3);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'y','LineWidth',2);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'w','LineWidth',2);
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'w','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'c^','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'mv','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'b^','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'rv','LineWidth',2);
    plot(cfighandles.ax_time_price,[nan nan],[nan nan],'g','LineWidth',1);
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
    fb = quotes.firstbar(end);
    lb=quotes.lastbar(n,end);
    nsig=cfighandles.popupmenu_strategies.Value;
    if nsig>1
      currsig = cfighandles.popupmenu_strategies.String{nsig};
      for sig = 1:length(symbol.signals)
        if strcmp(currsig,symbol.signals(sig).signal)
          signal = symbol.signals(sig);
          break;
        end
      end
    end
    if ~isempty(signal)
      longidx = signal.gamma>0;
      shortidx = signal.gamma<0;
      riskonidx = signal.gammadir>0;
      riskoffidx = signal.gammadir<0;
      cfighandles.ax_time_price.Children(5).XData=...
        find(longidx & riskoffidx);
      cfighandles.ax_time_price.Children(5).YData=...
        quotes.close(n,longidx & riskoffidx);
      
      cfighandles.ax_time_price.Children(4).XData=...
        find(shortidx & riskoffidx);
      cfighandles.ax_time_price.Children(4).YData=...
        quotes.close(n,shortidx & riskoffidx);
      
      cfighandles.ax_time_price.Children(3).XData=...
        find(longidx & riskonidx);
      cfighandles.ax_time_price.Children(3).YData=...
        quotes.close(n,longidx & riskonidx);
      
      cfighandles.ax_time_price.Children(2).XData=...
        find(shortidx & riskonidx);
      cfighandles.ax_time_price.Children(2).YData=...
        quotes.close(n,shortidx & riskonidx);
      
      cfighandles.ax_time_price.Children(8).XData=[fb:lb];
      cfighandles.ax_time_price.Children(8).YData=...
        symbol.filters.reversionavgpx(fb:lb);
      cfighandles.ax_time_price.Children(6).XData=[fb:lb];
      cfighandles.ax_time_price.Children(6).YData=...
        symbol.filters.reversionupprpx(fb:lb);
      cfighandles.ax_time_price.Children(7).XData=[fb:lb];
      cfighandles.ax_time_price.Children(7).YData=...
        symbol.filters.reversionlowrpx(fb:lb);
    end
    
    cfighandles.ax_time_price.Children(9).XData=[fb:lb];
    cfighandles.ax_time_price.Children(9).YData=quotes.close(n,fb:lb);
    
    dateid = find(quotes.tradedates<=cfighandles.date,1,'last');
    firstplot = quotes.lastbar(n,dateid)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,dateid)-firstplot)*0.05);
    xl = [firstplot quotes.lastbar(n,dateid)+shiftt];
    set(cfighandles.ax_time_price, 'Xlim',xl);
    set(cfighandles.ax_time_price, 'Ylim',...
      [0.9975*min(quotes.close(n,firstplot:quotes.lastbar(n,dateid))),...
      1.0025*max(quotes.max(n,firstplot:quotes.lastbar(n,dateid)))]);
    xticks = get(cfighandles.ax_time_price, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,dateid)) = quotes.lastbar(n,dateid);
    xticklabel = datestr(quotes.time(xticks),'yyyy-mm-dd');
    set(cfighandles.ax_time_price, 'XTickLabel',xticklabel);
  end
  %% PRICE x VALUE
  if isempty(cfighandles.ax_volume_price.Children)
    hold(cfighandles.ax_volume_price,'on');
    
    hold(cfighandles.ax_volume_price,'off');
    set(cfighandles.ax_volume_price, 'YAxisLocation', 'right');
    set(cfighandles.ax_volume_price, 'XAxisLocation', 'bottom');
    
    set(cfighandles.ax_volume_price, 'XLimMode','manual');
    set(cfighandles.ax_volume_price, 'YLimMode','manual');
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
    cfighandles.ax_volume_price.Children(5).XData=[0 0];
    cfighandles.ax_volume_price.Children(5).YData=...
      get(cfighandles.ax_time_price,'Ylim');
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    fb = quotes.firstbar(end);
    lb=quotes.lastbar(n,end);
    if ~isempty(signal)
      stairs(cfighandles.ax_time_volume,...
        [1 length(quotes.time)],[0 0],...
        'w','LineWidth',2);
      stairs(cfighandles.ax_time_volume,...
        [1:lb],signal.delta(1:lb),'c','LineWidth',2);
      
      position = cfighandles.Position;
      if ~isempty(position)
        np = position.npos;
        stairs(cfighandles.ax_time_volume,...
          [1:lb],...
          symbol.positions.delta(np,1:lb),...
          'y','LineWidth',2);
      else
        stairs(cfighandles.ax_time_volume,...
          [nan nan],[nan nan],'y','LineWidth',2);
      end
      stairs(cfighandles.ax_time_volume,...
        [nan nan],[nan nan],'c','LineWidth',2);
      stairs(cfighandles.ax_time_volume,...
          [nan nan],[nan nan],'y','LineWidth',2);
    end
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
    
    set(cfighandles.ax_time_volume, 'XLimMode','manual');
    set(cfighandles.ax_time_volume, 'YLimMode','manual');
    
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  else
    fb = quotes.firstbar(end);
    lb=quotes.lastbar(n,end);
    
    cfighandles.ax_time_volume.Children(2).XData=[fb:lb];
    cfighandles.ax_time_volume.Children(2).YData=signal.delta(fb:lb);

    position = cfighandles.Position;
    if ~isempty(position)
      np = position.npos;
      cfighandles.ax_time_volume.Children(1).XData=[fb:lb];
      cfighandles.ax_time_volume.Children(1).YData=...
        symbol.positions.delta(np,fb:lb);
    end
    
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
     xl = get(cfighandles.ax_time_price,'Xlim');
    if length(signal.delta)<xl(2)
      xl(2) = length(signal.delta);
    end
    xl = xl(1):xl(2);
    yl = [min(signal.delta(xl))-0.005 max(signal.delta(xl))+0.005];
    if ~isempty(position)
      np = position.npos;
      yl(1) = min(yl(1),min(symbol.positions.delta(np,xl)));
      yl(2) = max(yl(2),max(symbol.positions.delta(np,xl)));
    end
    
    if ~any(yl)
      yl = [0 0.00001];
    end
    set(cfighandles.ax_time_volume, 'Ylim',yl);
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  end
  guidata(curr_fig,cfighandles);
end
end

