function Table_OrdersActive(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.Account)
    if ~isempty(cfighandles.Strategy)
      position = cfighandles.Position;
      reports = position.OMS(position.activeOMS);
      if ~isempty(reports)
        orders = cfighandles.uitable;
        orders.RowName = [];
        tempdata = get(orders,'Data');
        updatetable = false;
        lastid = 0;
        if isempty(tempdata)
          updatetable = true;
        else
          lastid = max(cell2mat(tempdata(:,8)));
        end
        rcol = reports.OMSReports.cols;
        osize = reports.norders;
        
        if updatetable || max(reports.orders(1:osize,rcol.id))>lastid
          activeidx = reports.activeidx(1:osize);
          if any(activeidx)
          columnname = {'Time','Type','Tag','OrdPx','OrdQty','OrderId','ReqID'};
          columnformat = {'char','numeric','numeric','bank','numeric','bank','numeric'};
          set(orders,'columnname',columnname,'columnformat',columnformat);

          ordersdata = cell(sum(activeidx),8);
          ordersdata(:,1) = ...
            cellstr(datestr(flipud(reports.orders(activeidx,rcol.time)),...
            'HH:mm:ss.fff'));
          ordersdata(:,2) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.ordtype)));
          ordersdata(:,3) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.tag)));
          ordersdata(:,4) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.price)));
          ordersdata(:,5) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.value)));
          ordersdata(:,6) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.orderid)));
          ordersdata(:,7) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.requestid)));
          ordersdata(:,8) = ...
            num2cell(flipud(reports.orders(activeidx,rcol.id)));
          [tmp idx] = sortrows(cell2mat(ordersdata(:,4)),-1);
          ordersdata = ordersdata(idx,:);
          
          set(orders,'Data',ordersdata);
          else
            set(orders,'Data',[]);
          end
        end
      else
        set(orders,'Data',[]);
      end
    end
  end
  guidata(curr_fig,cfighandles);
end

