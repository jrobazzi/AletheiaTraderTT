function Table_BacktestStatistics(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.symbol)
      results = cfighandles.uitable;
      results.FontName = 'Arial';
      results.FontSize = 12;
      results.FontWeight = 'Normal';
      results.ColumnName = [];
      results.RowName=[];...
      columnwidth =  {200,'auto'};    
      columnformat = {'char','bank'};
      set(results,'columnformat',columnformat,'columnwidth',columnwidth);

      resultsdata = cell(5,2);
      resultsdata(:,1)=...
        {'Win Probability(%)',...
        'Expected Profit(%)',...
        'Expected Loss(%)',...
        'Total Positions',...
        'Gross Result(pts)'};
      symbol=cfighandles.symbol;
      q = symbol.tickvalue/symbol.ticksize;
      signal = symbol.signals(2);
      np = signal.positions.npos;
      wontradesidx = signal.positions.return(1:np)>0;
      losttradesidx = signal.positions.return(1:np)<=0;
      longtradesidx = signal.positions.equity(1:np)>0;
      shorttradesidx = signal.positions.equity(1:np)<0;

      n=0;
      n=n+1;resultsdata{n,2} = 100*sum(wontradesidx)/np;
      n=n+1;resultsdata{n,2} = mean(signal.positions.return(wontradesidx))*100;
      n=n+1;resultsdata{n,2} = mean(signal.positions.return(losttradesidx))*100;
      n=n+1;resultsdata{n,2} = np;
      n=n+1;resultsdata{n,2} = sum(signal.positions.result(1:np))/q;

      set(results,'Data',resultsdata);
  end
  guidata(curr_fig,cfighandles);
end

