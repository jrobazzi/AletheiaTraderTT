function Table_PositionHistory(curr_fig, cfighandles )
%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.Account)
    if ~isempty(cfighandles.Strategy)
      position = cfighandles.Position;
      trades = position;
      if ~isempty(trades)
        orders = cfighandles.uitable;
        orders.RowName = [];
        tempdata = get(orders,'Data');
        updatetable = false;
        lastid = 0;
        if isempty(tempdata)
          updatetable = true;
        else
          ids = cell2mat(tempdata(:,6));
          if ~isempty(ids)
            lastid = max(cell2mat(tempdata(:,6)));
          else
            updatetable = true;
          end
        end
        tcol = trades.OMS(1).OMSTrades.cols;
        tsize = trades.ntrades;
        
        if max(trades.trades(1:tsize,tcol.id))>lastid
          updatetable = true;
        end
        if updatetable 
          
          columnname = {'Time','PosPx','PosQty',...
                        'ResultClosed','TradeID','Id','TradePx','TradeQty'};
          columnformat = {'char','bank','numeric','bank','bank',...
            'numeric','bank','numeric'};
          set(orders,'columnname',columnname,'columnformat',columnformat);
          lastntrades = tsize;
          ordersdata = cell(tsize,6);
          ordersdata(:,1) = cellstr(datestr(flipud(...
            trades.trades(1:tsize,tcol.time)),'HH:mm:ss.fff'));
          ordersdata(:,2) = num2cell(flipud(trades.avgprice(1:tsize)));
          ordersdata(:,3) = num2cell(flipud(trades.contracts(1:tsize)));
          ordersdata(:,4) = num2cell(flipud(trades.resultclosed(1:tsize)));
          ordersdata(1:tsize,5) = ...
            num2cell(flipud(trades.trades(1:tsize,tcol.tradeid)));
          ordersdata(1:tsize,6) = ...
            num2cell(flipud(trades.trades(1:tsize,tcol.id)));
          ordersdata(1:tsize,7) = ...
            num2cell(flipud(trades.trades(1:tsize,tcol.price)));
          ordersdata(1:tsize,8) = ...
            num2cell(flipud(trades.trades(1:tsize,tcol.value)));
          set(orders,'Data',ordersdata);
        end
        
      else
        set(orders,'Data',[]);
      end
    end
  end
  guidata(curr_fig,cfighandles);
end

