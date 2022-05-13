function Template_ProfilePosition(curr_fig, cfighandles, Market)
if ~isempty(cfighandles.symbol)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  if (quotes.lastbar(n,end)>0)
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    lb=quotes.lastbar(n,end);
    px = quotes.close(n,1:lb);
    px(quotes.openbar(n,2:end-1)-1) = NaN;
    stairs(cfighandles.ax_time_price,[1:quotes.lastbar(n,end)],px,...
      'g','LineWidth',2);
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'g','LineWidth',3);
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
    x_lim = [firstplot round(quotes.lastbar(n,end)*1.05)];
    set(cfighandles.ax_time_price, 'Xlim',x_lim);
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
        riskonidx = position.tradedirection~=0;
        riskoffidx = position.tradedirection==0;
        longidx = position.trades(:,tcol.value)>0;
        shortidx = position.trades(:,tcol.value)<0;
        if any(longidx) && any(riskoffidx) && any(longidx & riskoffidx)
          cfighandles.ax_time_price.Children(5).XData=...
            position.trades(longidx & riskoffidx,tcol.id);
          cfighandles.ax_time_price.Children(5).YData=...
            position.trades(longidx & riskoffidx,tcol.price); 
        end
        if any(shortidx) && any(riskoffidx) && any(shortidx & riskoffidx)
          cfighandles.ax_time_price.Children(4).XData=...
            position.trades(shortidx & riskoffidx,tcol.id);
          cfighandles.ax_time_price.Children(4).YData=...
            position.trades(shortidx & riskoffidx,tcol.price); 
        end
        if any(longidx) && any(riskonidx) && any(longidx & riskonidx)
          cfighandles.ax_time_price.Children(3).XData=...
            position.trades(longidx & riskonidx,tcol.id);
          cfighandles.ax_time_price.Children(3).YData=...
            position.trades(longidx & riskonidx,tcol.price); 
        end
        if any(shortidx) && any(riskonidx) &&  any(shortidx & riskonidx)
          cfighandles.ax_time_price.Children(2).XData=...
            position.trades(shortidx & riskonidx,tcol.id);
          cfighandles.ax_time_price.Children(2).YData=...
            position.trades(shortidx & riskonidx,tcol.price); 
        end
      end
    end
    cfighandles.ax_time_price.Children(6).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(6).YData=...
      quotes.close(n,quotes.firstbar(end):quotes.lastbar(n,end));
    
    
    dateid = find(quotes.tradedates<=cfighandles.date,1,'last');
    firstplot = quotes.lastbar(n,dateid)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,dateid)-firstplot)*0.05);
    xl = [firstplot quotes.lastbar(n,dateid)+shiftt];
    lstp = quotes.close(n,quotes.lastbar(n,end));
    cfighandles.ax_time_price.Children(1).XData=xl;
    cfighandles.ax_time_price.Children(1).YData=[lstp lstp];
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
    stairs(cfighandles.ax_volume_price,[nan nan],[nan nan],'w',...
      'LineWidth',1.0);
    stairs(cfighandles.ax_volume_price,[nan nan],[nan nan],'c',...
      'LineWidth',1.5);
    stairs(cfighandles.ax_volume_price,[nan nan],[nan nan],'g',...
      'LineWidth',2);
    stairs(cfighandles.ax_volume_price,[nan nan],[nan nan],'y',...
      'LineWidth',2.5);
    stairs(cfighandles.ax_volume_price,[nan nan],[nan nan],'g',...
      'LineWidth',1);
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
    position = cfighandles.Position;
    if ~isempty(position)
      currOMS = position.OMS(position.activeOMS);
      cfighandles.ax_volume_price.Children(2).XData=...
        currOMS.positionprofile;
      cfighandles.ax_volume_price.Children(2).YData=...
        [1:length(currOMS.positionprofile)].*symbol.ticksize;
      cfighandles.ax_volume_price.Children(3).XData=...
        position.reqpositionprofile;
      cfighandles.ax_volume_price.Children(3).YData=...
        [1:length(position.reqpositionprofile)].*symbol.ticksize;
      cfighandles.ax_volume_price.Children(4).XData=...
        position.setpositionprofile;
      cfighandles.ax_volume_price.Children(4).YData=...
        [1:length(position.setpositionprofile)].*symbol.ticksize;
      
      plim = get(cfighandles.ax_time_price,'Ylim');
      plim = round(plim./symbol.ticksize);
      setmax = max(position.setpositionprofile([plim(1):plim(2)]));
      setmin = min(position.setpositionprofile([plim(1):plim(2)]));
      reqmax = max(position.reqpositionprofile([plim(1):plim(2)]));
      reqmin = min(position.reqpositionprofile([plim(1):plim(2)]));
      ordmax = max(currOMS.positionprofile([plim(1):plim(2)]));
      ordmin = min(currOMS.positionprofile([plim(1):plim(2)]));
      pmax = max(max(reqmax,ordmax),setmax);
      pmax = pmax+0.1*abs(pmax)+symbol.lotmin;
      pmin = min(min(reqmin,ordmin),setmin);
      pmin = pmin-0.1*abs(pmin)-symbol.lotmin;
      if pmin==0 && pmax==0
        pmin=-0.01;
      end
      set(cfighandles.ax_volume_price, 'Xlim',[pmin pmax]);
      
      lstp = quotes.close(n,quotes.lastbar(n,end));
      cfighandles.ax_volume_price.Children(1).XData=[pmin pmax];
      cfighandles.ax_volume_price.Children(1).YData=[lstp lstp];
    end
    cfighandles.ax_volume_price.Children(5).XData=[0 0];
    cfighandles.ax_volume_price.Children(5).YData=...
      get(cfighandles.ax_time_price,'Ylim');
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    position = cfighandles.Position;
    if ~isempty(position)
      np=position.npos;
      stairs(cfighandles.ax_time_volume,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.contracts(np,1:quotes.lastbar(n,end)),...
        'y','LineWidth',2);
    end
    stairs(cfighandles.ax_time_volume,[nan nan],[nan nan],...
      'y','LineWidth',2);
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
    position = cfighandles.Position;
    if ~isempty(position)
      np=position.npos;
      if size(cfighandles.ax_time_volume.Children(1).XData,2)<...
          quotes.lastbar(n,end)
      cfighandles.ax_time_volume.Children(1).XData=...
        [quotes.firstbar(end):quotes.lastbar(n,end)];
      cfighandles.ax_time_volume.Children(1).YData=...
        symbol.positions.contracts...
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
end

