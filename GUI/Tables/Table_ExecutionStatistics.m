function Table_ExecutionStatistics(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.Account)
    if ~isempty(cfighandles.Strategy)
      position = cfighandles.Position;
      if ~isempty(position)
        results = cfighandles.uitable;
        results.FontName = 'Arial';
        results.FontSize = 12;
        results.FontWeight = 'Normal';
        results.ColumnName = [];
        results.RowName=[];...
        columnwidth =  {200,'auto'};    
        columnformat = {'char','numeric'};
        set(results,'columnformat',columnformat,'columnwidth',columnwidth);
        
        resultsdata = cell(8,2);
        resultsdata(:,1)=...
          {'Win Probability(%)',...
          'Expected Profit(%)',...
          'Expected Loss(%)',...
          'Total Positions',...
          'Gross Result(pts)',...
          'Gross Result(R$)',...
          'Gross Profit(R$)',...
          'Gross Loss(R$)'};
        
        np = position.positions;
        wontradesidx = position.positionsresult>0;
        losttradesidx = position.positionsresult<0;
        longtradesidx = position.positionsequity>0;
        shorttradesidx = position.positionsequity<0;
        
        n=0;
        n=n+1;resultsdata{n,2} = sum(wontradesidx)*100/np;
        n=n+1;resultsdata{n,2} = mean(position.positionsreturn(wontradesidx))*100;
        n=n+1;resultsdata{n,2} = mean(position.positionsreturn(losttradesidx))*100;
        n=n+1;resultsdata{n,2} = np;
        n=n+1;resultsdata{n,2} = sum(position.positionspoints(1:np));
        n=n+1;resultsdata{n,2} = sum(position.positionsresult(1:np));
        n=n+1;resultsdata{n,2} = sum(position.positionsresult(wontradesidx));
        n=n+1;resultsdata{n,2} = sum(position.positionsresult(losttradesidx));
        
        set(results,'Data',resultsdata);
      end
    end
  end
  guidata(curr_fig,cfighandles);
end

