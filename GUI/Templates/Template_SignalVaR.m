function Template_SignalVaR(curr_fig, cfighandles, Market)
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
    ntd = length(quotes.tradedates);
    for d=1:ntd-1
      fb = quotes.firstbar(d);
      ob = quotes.openbar(n,d);
      lb = quotes.lastbar(n,d);
      if ob>0 && lb>0 
        if any(signal.rlog(ob:lb))
          c =0.15+ 0.75*d/ntd;
          stairs(cfighandles.ax_time_price,...
            [1:lb-ob+1],cumsum(signal.rlog(ob:lb)),'Color',[c c c]);
        end
      end
    end
    hold(cfighandles.ax_time_price,'off');
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'XLim',[0 2500]);
    set(cfighandles.ax_time_price, 'YLimMode','auto');
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
   
  end
  %% PRICE x VALUE
  if isempty(cfighandles.ax_volume_price.Children)
    hold(cfighandles.ax_volume_price,'on');
    obs = quotes.openbar(n,:);
    lbs = quotes.lastbar(n,:);
    lbs(obs==0)=[];
    obs(obs==0)=[];
    obs(lbs==0)=[];
    lbs(lbs==0)=[];
    
    drlog = signal.rlogaccum(lbs)-signal.rlogaccum(obs);
    drlog(drlog==0) = [];
    [counts,centers] = hist(drlog,30);
    counts = counts./sum(counts);
    barh(cfighandles.ax_volume_price,centers,counts,'w');
    
    hold(cfighandles.ax_volume_price,'off');
    set(cfighandles.ax_volume_price, 'YAxisLocation', 'right');
    set(cfighandles.ax_volume_price, 'XAxisLocation', 'bottom');
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
    set(cfighandles.ax_time_volume, 'Fontsize', 16);
    
    set(cfighandles.ax_time_volume, 'XGrid', 'on');
    set(cfighandles.ax_time_volume, 'YGrid', 'on');
    set(cfighandles.ax_time_volume, 'XMinorGrid', 'off');
    set(cfighandles.ax_time_volume, 'YMinorGrid', 'off');
   
  else
    
  end
  guidata(curr_fig,cfighandles);
end
end

