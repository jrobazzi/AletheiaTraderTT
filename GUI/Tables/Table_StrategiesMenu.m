function Table_StrategiesMenu(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  npos = 0;
  data={'','','',0};
  account=cfighandles.Account;
  if ~isempty(account)
    for s=1:length(account.Strategies)
      strategy=account.Strategies(s);
      for p=1:length(strategy.Positions)
        position = strategy.Positions(p);
        pcol=position.IO.cols;
        npos=npos+1;
        status = position.status(pcol.value);
        if status>0
          strstatus=position.OMS_STATUS{status};
        else
          strstatus ='OFF';
        end
        if position.ntrades>0
          pos = position.contracts(position.ntrades);
        else
          pos=0;
        end
        data(npos,1:6)=...
          {position.autotrade(pcol.value)~=0,strstatus,account.account,...
          strategy.strategy,position.Symbol.symbol,pos};
      end
    end

    if isempty(cfighandles.uitable.Data) && npos>0
      cfighandles.uitable.FontSize=10;
      cfighandles.uitable.RowName=[];
      cfighandles.uitable.ColumnName={'Auto','Status','Account','Strategy','Position','Contracts'};
      cfighandles.uitable.ColumnFormat={'logical','char','char','char','char','numeric'};
      cfighandles.uitable.ColumnEditable =[true,false,false,false,false,false];
      cfighandles.uitable.ColumnWidth = {50,75,100,200,100,75};
    end
    
    cfighandles.uitable.Data = data;
  end
  guidata(curr_fig,cfighandles);
end

