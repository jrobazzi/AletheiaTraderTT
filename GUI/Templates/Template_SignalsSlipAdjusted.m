function Template_SignalsSlipAdjusted(curr_fig, cfighandles, Market)
if isempty(cfighandles.symbol)
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    for s=1:length(Market.Symbols)
      symbol = Market.Symbols(s);
      n=symbol.n;
      quotes = symbol.Main.quotes;
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        quotes.rlogaccum(n,1:quotes.lastbar(n,end)),'b');
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        -quotes.rlogaccum(n,1:quotes.lastbar(n,end)),'r');
      for sig=1:length(symbol.signals)
        lb=symbol.signals(sig).lastbar;
        rlogaccum=symbol.signals(sig).rlogaccum(1:lb);
        stairs(cfighandles.ax_time_price,...
          [1:length(rlogaccum)],rlogaccum,'w');
      end
    end
    hold(cfighandles.ax_time_price,'off');
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'YLimMode','auto');
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot round(quotes.lastbar(n,end)*1.05)]);
    set(cfighandles.ax_time_price, 'Color', [0 0 0]);
    set(cfighandles.ax_time_price, 'XColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'YColor', [1 1 1]);
    set(cfighandles.ax_time_price, 'LineWidth', 2);
    set(cfighandles.ax_time_price, 'Fontsize', 16);
    set(cfighandles.ax_time_price, 'XGrid', 'on');
    set(cfighandles.ax_time_price, 'YGrid', 'on');
    set(cfighandles.ax_time_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_price, 'YMinorGrid', 'off');
  end
else
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm|hh:MM:ss');
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    position = cfighandles.Position;
    %stairs(cfighandles.ax_time_price,...
    %    [1:quotes.lastbar(n,end)],...
    %    quotes.rlogaccum(n,1:quotes.lastbar(n,end)),'b');
    %stairs(cfighandles.ax_time_price,...
    %  [1:quotes.lastbar(n,end)],...
    %  -quotes.rlogaccum(n,1:quotes.lastbar(n,end)),'r');
    longsharpe = sharpe(quotes.rlogaccum(n,1:quotes.lastbar(n,end)),0);
    shortsharpe = sharpe(-quotes.rlogaccum(n,1:quotes.lastbar(n,end)),0);
    if isempty(position)
      %str = {strcat('Long:',num2str(longsharpe)),...
      %       strcat('Short:',num2str(shortsharpe))};
      for s=1:length(symbol.signals)
        str{s} = strcat(strcat(symbol.signals(s).signal,':'),...
                          num2str(symbol.signals(s).sharpe));
        lb=symbol.signals(s).lastbar;
        rlogaccum=symbol.signals(s).rlognetaccum(1:lb);
        rlogaccum = exp(rlogaccum) - 1;
        stairs(cfighandles.ax_time_price,[1:length(rlogaccum)],...
          rlogaccum*100,...
          'LineWidth',2);
      end
      legend(cfighandles.ax_time_price,str,...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    else
      ns=position.nsignal;
      np=position.npos;
      %{
      if ns>0 
        stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.rlogaccumadj(np,1:quotes.lastbar(n,end)),...
        'g','LineWidth',2);
      end
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],...
        symbol.positions.rlogaccum(np,1:quotes.lastbar(n,end)),...
        'y','LineWidth',2);
      %}
      rlognetaccum = symbol.signals(ns).rlogaccum(1:quotes.lastbar(n,end))...
        -symbol.signals(ns).gammaaccum(1:quotes.lastbar(n,end)).*...
        -symbol.positions.gammaslippage(np)...
        -symbol.signals(ns).costaccum(1:quotes.lastbar(n,end));
      cmax = cummax(rlognetaccum);
      adjunderwater = rlognetaccum-cmax;
      rlognetaccum = exp(rlognetaccum)-1;
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],rlognetaccum*100,'c','LineWidth',2);
      btrlognetaccum = ...
        symbol.signals(ns).rlognetaccum(1:quotes.lastbar(n,end));
      btrlognetaccum = exp(btrlognetaccum)-1;
      stairs(cfighandles.ax_time_price,...
        [1:quotes.lastbar(n,end)],btrlognetaccum*100,...
        'y','LineWidth',2);
      legend(cfighandles.ax_time_price,{'Backtest Net Return','Adjusted Net Return'},...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    end
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'g','LineWidth',3);
    stairs(cfighandles.ax_time_price,...
      [nan nan],[nan nan],'y','LineWidth',3);
    hold(cfighandles.ax_time_price,'off');
    title(cfighandles.ax_time_price,'Net Return(%) x Time','FontSize',16);
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
    firstplot = quotes.lastbar(n,end)...
        -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    shiftt = round((quotes.lastbar(n,end)-firstplot)*0.05);
    if quotes.lastbar(n,end)>1
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot quotes.lastbar(n,end)+shiftt]);
    xticks = get(cfighandles.ax_time_price, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'yyyy-mm');
    set(cfighandles.ax_time_price, 'XTickLabel',xticklabel);
    end
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
    set(cfighandles.ax_volume_price, 'Fontsize', 16);
    
    set(cfighandles.ax_volume_price, 'XGrid', 'on');
    set(cfighandles.ax_volume_price, 'YGrid', 'on');
    set(cfighandles.ax_volume_price, 'XMinorGrid', 'off');
    set(cfighandles.ax_volume_price, 'YMinorGrid', 'off');
  else
    cfighandles.ax_volume_price.Children(4).XData=[0 0];
    cfighandles.ax_volume_price.Children(4).YData=...
      get(cfighandles.ax_time_price,'Ylim');
    set(cfighandles.ax_volume_price, 'Ylim',...
      get(cfighandles.ax_time_price,'Ylim'));
  end
  %% VALUE x TIME
  if isempty(cfighandles.ax_time_volume.Children)
    hold(cfighandles.ax_time_volume,'on');
    for s=1:length(symbol.signals)
      lb=symbol.signals(s).lastbar;
      uw = symbol.signals(s).rlogunderwater(1:lb);
      uw = exp(uw)-1;
      adjunderwater = exp(adjunderwater)-1;
      stairs(cfighandles.ax_time_volume,[1:lb],uw*100,'c',...
        'LineWidth',2);
      stairs(cfighandles.ax_time_volume,[1:lb],adjunderwater*100,'y',...
        'LineWidth',2);
    end
    legend(cfighandles.ax_time_volume,{'Backtest Underwater','Adjusted Underwater'},...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    hold(cfighandles.ax_time_volume,'off');
    title(cfighandles.ax_time_volume,'UnderWater(%) x Time','FontSize',16);
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
      xticklabel = datestr(quotes.time(xticks),'yyyy-mm');
      set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
    end
  end
  guidata(curr_fig,cfighandles);
end
end

