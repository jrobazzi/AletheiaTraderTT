function Template_DifusionArcsine(curr_fig, cfighandles, Market)
if ~isempty(cfighandles.symbol)
  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  cfighandles.textHour.String = datestr(symbol.Main.time,'dd/mm/yyyy|hh:MM:ss');
  
  %% PRICE x TIME
  if isempty(cfighandles.ax_time_price.Children)
    hold(cfighandles.ax_time_price,'on');
    %{
    ntd = length(quotes.tradedates);
    for d=1:ntd-1
      fb = quotes.firstbar(d);
      ob = quotes.openbar(n,d);
      lb = quotes.lastbar(n,d);
      lob = quotes.openbar(n,end);
      t = lob:lob+lb-ob;
      logret = quotes.rlogintraday(n,ob:lb);
      c =0.05+ 0.45*d/ntd;
      stairs(cfighandles.ax_time_price,t,logret,'Color',[c c c]);
    end
    stairs(cfighandles.ax_time_price,[nan nan],[nan nan],'g',...
      'LineWidth',3);
    %}
    obs = quotes.openbar(n,1:end-1);
    maxbs = quotes.maxbar(n,:);
    minbs = quotes.minbar(n,:);
    c = [20:20:2160];
    [maxcounts,maxcenters] = hist(maxbs-obs,c);
    maxcounts = maxcounts./sum(maxcounts);
    [mincounts,mincenters] = hist(minbs-obs,c);
    mincounts = mincounts./sum(mincounts);
    x = [0:20:2160]./2160;
    arcsinecdf = (2/pi).*asin(sqrt(x));
    arcsinepdf = diff(arcsinecdf);
    bar(cfighandles.ax_time_price,quotes.openbar(n,end)+maxcenters,maxcounts,...
      'c','LineWidth',2);
    hold on
    plot(cfighandles.ax_time_price,quotes.openbar(n,end)+maxcenters,arcsinepdf,...
      'w','LineWidth',2);
    bar(cfighandles.ax_time_price,quotes.openbar(n,end)+mincenters,-mincounts,...
      'm','LineWidth',2);
    plot(cfighandles.ax_time_price,quotes.openbar(n,end)+maxcenters,-arcsinepdf,...
      'w','LineWidth',2);
    
    hold(cfighandles.ax_time_price,'off');
    legend(cfighandles.ax_time_price,{'Maxima time','Arcsine time','Minima time'},...
        'Color',[0 0 0],'TextColor',[1 1 1],'FontSize',16);
    set(cfighandles.ax_time_price, 'YAxisLocation', 'left');
    set(cfighandles.ax_time_price, 'XAxisLocation', 'top');
    set(cfighandles.ax_time_price, 'XLimMode','manual');
    set(cfighandles.ax_time_price, 'YLimMode','auto');
    firstplot = quotes.lastbar(n,end)...
      -round(cfighandles.zoom*datenum(0,0,0,0,1,0)/quotes.dt);
    firstplot = max(firstplot,1);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot round(quotes.lastbar(n,end)*1.05)]);
    %{
    set(cfighandles.ax_time_price, 'Ylim',...
      [0.9975*min(quotes.close(n,firstplot:quotes.lastbar(n,end))),...
      1.0025*max(quotes.max(n,firstplot:quotes.lastbar(n,end)))]);
      %}
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
    %{
    cfighandles.ax_time_price.Children(1).XData=...
      [quotes.firstbar(end):quotes.lastbar(n,end)];
    cfighandles.ax_time_price.Children(1).YData=...
      quotes.rlogintraday(n,quotes.firstbar(end):quotes.lastbar(n,end));
    %}
    firstplot = quotes.firstbar(n,end);
    firstplot = max(firstplot,1);
    set(cfighandles.ax_time_price, 'Xlim',...
      [firstplot quotes.firstbar(end)+2170]);
    %{
    maxp = max(quotes.rlogintraday(n,firstplot:quotes.lastbar(n,end)));
    maxp = max(maxp,max(quotes.rlogintraday(n,:)));
    minp = min(quotes.rlogintraday(n,firstplot:quotes.lastbar(n,end)));
    minp = min(minp,min(quotes.rlogintraday(n,:)));
    set(cfighandles.ax_time_price, 'Ylim',[0.9975*minp,1.0025*maxp]);
      %}
    xticks = get(cfighandles.ax_time_price, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'hh:MM');
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
    %{
    obs = quotes.openbar(n,1:end-1);
    maxbs = quotes.maxbar(n,:);
    minbs = quotes.minbar(n,:);
    c = [20:20:2160];
    [maxcounts,maxcenters] = hist(maxbs-obs,c);
    maxcounts = maxcounts./sum(maxcounts);
    [mincounts,mincenters] = hist(minbs-obs,c);
    mincounts = mincounts./sum(mincounts);
    x = [0:20:2160]./2160;
    arcsinecdf = (2/pi).*asin(sqrt(x));
    arcsinepdf = diff(arcsinecdf);
    bar(cfighandles.ax_time_volume,quotes.openbar(n,end)+maxcenters,maxcounts,...
      'c','LineWidth',2);
    hold on
    plot(cfighandles.ax_time_volume,quotes.openbar(n,end)+maxcenters,arcsinepdf,...
      'w','LineWidth',2);
    bar(cfighandles.ax_time_volume,quotes.openbar(n,end)+mincenters,-mincounts,...
      'm','LineWidth',2);
    plot(cfighandles.ax_time_volume,quotes.openbar(n,end)+maxcenters,-arcsinepdf,...
      'w','LineWidth',2);
    %}
    hold off
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
    xticklabel = datestr(quotes.time(xticks),'hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  else
    
    set(cfighandles.ax_time_volume, 'Xlim', ...
      get(cfighandles.ax_time_price,'Xlim'));
    xticks = get(cfighandles.ax_time_volume, 'XTick');
    xticks(xticks<1) = 1;
    xticks(xticks>quotes.lastbar(n,end)) = quotes.lastbar(n,end);
    xticklabel = datestr(quotes.time(xticks),'hh:MM');
    set(cfighandles.ax_time_volume, 'XTickLabel',xticklabel);
  end
  guidata(curr_fig,cfighandles);
end
end

