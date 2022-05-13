function Template_SignalsSlippage(curr_fig, cfighandles, Market)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    position = cfighandles.Position;
    if ~isempty(position)
      ns=position.nsignal;
      np=position.npos;
      if ns>0 
        stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.rlogaccumadj(np,1:quotes.lastbar(n,end)),...
        'c','LineWidth',2);
      end
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.rlogaccum(np,1:quotes.lastbar(n,end)),...
        'y','LineWidth',2);
    end
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'g','LineWidth',3);
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'y','LineWidth',3);
    
    legend(cfighandles.ax_time_price,...
      {'Signal Log Return','Execution Log Return'},...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    
    hold(cfighandles.ax_time_price,'off');
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'YLimMode','auto');
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    if quotes.lastbar(n,end)>1
      set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot round(quotes.lastbar(n,end)*1.05)]);
    end
    set(cfighandles.ax_time_price, 'Color', [0 0 0]);
    set(cfighandles.ax_time_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'LineWidth', 2);
    set(cfighandles.ax_time_price, 'Fontsize', 16);
    set(cfighandles.ax_time_price, 'XGrid', 'on');
    set(cfighandles.ax_time_price, 'YGrid', 'on');
    set(cfighandles.ax_time_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_price, 'YMinorGrid', 'off');
  else
    position = cfighandles.Position;
    if ~isempty(position)
      ns=position.nsignal;
      np=position.npos; 
      n = symbol.n;
      fb=quotes.firstbar(end);
      lb=quotes.lastbar(n,end);
      if ns>0 && np>0
        cfighandles.ax_time_price.Children(2).XData=[fb:lb];
        cfighandles.ax_time_price.Children(2).YData=...
           symbol.positions.rlogaccumadj(np,fb:lb);
        cfighandles.ax_time_price.Children(1).XData=[fb:lb];
        cfighandles.ax_time_price.Children(1).YData=...
           symbol.positions.rlogaccum(np,fb:lb);
      end
    end
    dateid = find(quotes.tradedates<=cfighandles.date,1,'last');
    firstplot = quotes.lastbar(n,dateid)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,dateid)-firstplot)*0.05);
    if quotes.lastbar(n,dateid)>1
      set(cfighandles.ax_time_price, 'Xlim',...
        [firstplot quotes.lastbar(n,dateid)+shiftt]);
      xticks = get(cfighandles.ax_time_price, 'XTick');
      xticks(xticks<1) = 1;
      xticks(xticks>quotes.lastbar(n,dateid)) = quotes.lastbar(n,dateid);
      xticklabel = datestr(quotes.time(xticks),'yyyy-mm-dd');
      set(cfighandles.ax_time_price, 'XTickLabel',xticklabel);
    end
  end
  %% PRICE x VALUE
  if isempty(cfighandles.ax_volume_price.Children)
    hold(cfighandles.ax_volume_price,'on');
    position = cfighandles.Position;
    if ~isempty(position)
      ns=position.nsignal;
      np=position.npos;
      if ns>0 
        fbs = quotes.firstbar;
        lbs = quotes.lastbar(n,:);
        lb = quotes.lastbar(n,end);
        dslippage = symbol.positions.slippage(np,fbs)...
          -symbol.positions.slippage(np,lbs);
        nzidx = dslippage~=0;
        if ~isempty(nzidx)
          [counts,centers] = hist(dslippage,30);
          counts = counts./sum(counts);
          centers = centers + symbol.positions.rlogaccum(np,lb);
          barh(cfighandles.ax_volume_price,centers,counts,'g');
        end
      end
    end
    hold(cfighandles.ax_volume_price,'off');
    set(cfighandles.ax_volume_price, 'YAxisLocation', 'right');
    set(cfighandles.ax_volume_price, 'XAxisLocation', 'bottom');
    
    set(cfighandles.ax_volume_price, 'XLimMode','auto');
    set(cfighandles.ax_volume_price, 'YLimMode','auto');
    
    set(cfighandles.ax_volume_price, 'Color', [0 0 0]);
    set(cfighandles.ax_volume_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_volume_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_volume_price, 'LineWidth', 2);
    set(cfighandles.ax_volume_price, 'Fontsize', 16);
    
    set(cfighandles.ax_volume_price, 'XGrid', 'on');
    set(cfighandles.ax_volume_price, 'YGrid', 'on');
    set(cfighandles.ax_volume_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_volume_price, 'YMinorGrid', 'off');
  else
    %cfighandles.ax_volume_price.Children(4).XData=[0 0];
    %cfighandles.ax_volume_price.Children(4).YData=...
    %  get(cfighandles.ax_time_price,'Ylim');
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    position = cfighandles.Position;
    if ~isempty(position)
      ns=position.nsignal;
      np=position.npos;
      if ns>0 
        stairs(cfighandles.ax_time_volume,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.slippage(np,1:quotes.lastbar(n,end)),...
        'y','LineWidth',2);
      end
    end
    legend(cfighandles.ax_time_volume,{'Slippage Log Return'},...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    hold(cfighandles.ax_time_volume,'off');
    set(cfighandles.ax_time_volume, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_volume, 'XAxisLocation', 'bottom');
    set(cfighandles.ax_time_volume, 'Xlim',...
      get(cfighandles.ax_time_price,'Xlim'));
    set(cfighandles.ax_time_volume, 'Color', [0 0 0]);
    set(cfighandles.ax_time_volume, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_volume, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_volume, 'LineWidth', 2);
    set(cfighandles.ax_time_volume, 'Fontsize', 16);
    
    set(cfighandles.ax_time_volume, 'XGrid', 'on');
    set(cfighandles.ax_time_volume, 'YGrid', 'on');
    set(cfighandles.ax_time_volume, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_volume, 'YMinorGrid', 'off');
    
    set(cfighandles.ax_time_volume, 'XLimMode','manual');
    set(cfighandles.ax_time_volume, 'YLimMode','auto');
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    if quotes.lastbar(n,end)>1
      xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
      set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
    end
  else
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    if quotes.lastbar(n,end)>1
      xticklabel = datestr(quotes.time(xticks),'dd|hh:MM');
      set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
    end
  end
  guidata(curr_fig,cfighandles);
end

