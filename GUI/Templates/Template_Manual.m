function Template_Manual(curr_fig, cfighandles, Market)

  symbol = cfighandles.symbol;
  n=symbol.n;
  quotes = symbol.Main.quotes;
  signal = symbol.signals(2);
  npos = signal.positions.npos;
  idx = signal.positions.return(1:npos)~=0;
  [counts,centers] = hist(signal.positions.return(idx),200);
  counts = counts./sum(counts);
  figure(1)
  bar(centers,counts);
  ax = gca;
  title(ax,'Return PDF','FontSize',16);
  set(ax,'FontSize',16);
  
  idx = signal.positions.points(1:npos)~=0;
  [counts,centers] = hist(signal.positions.points(idx),200);
  counts = counts./sum(counts);
  figure(2)
  bar(centers,counts);
  ax = gca;
  title(ax,'Points PDF','FontSize',16);
  set(ax,'FontSize',16);
  
  guidata(curr_fig,cfighandles);

end

