function Table_RequestsProfile(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.Account)
    if ~isempty(cfighandles.Strategy)
      position = cfighandles.Position;
      if ~isempty(position)
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
        rcol = position.IO.cols;
        activeidx = position.activeidx;
        if any(activeidx)
        columnname = {'Time','Type','Tag','PosPx','PosQty','OrderId','ReqID'};
        columnformat = {'char','numeric','numeric','bank','numeric','bank','numeric'};
        set(orders,'columnname',columnname,'columnformat',columnformat);


        ordersdata = cell(sum(activeidx),8);
        ordersdata(:,1) = ...
          cellstr(datestr(flipud(...
          position.reqordersprofile(:,rcol.time)),'HH:mm:ss.fff'));
        %ordersdata(:,2) = ...
        %  num2cell(flipud(position.reqordersprofile(:,rcol.ordtype)));
        ordersdata(:,3) = ...
          num2cell(flipud(position.reqordersprofile(:,rcol.tag)));
        ordersdata(:,4) = ...
          num2cell(flipud(position.reqordersprofile(:,rcol.price)));
        ordersdata(:,5) = ...
          num2cell(flipud(position.reqordersprofile(:,rcol.value)));
        %ordersdata(:,6) = ...
        %  num2cell(flipud(position.reqordersprofile(:,rcol.orderid)));
        %ordersdata(:,7) = ...
        %  num2cell(flipud(position.reqordersprofile(:,rcol.requestid)));
        %ordersdata(:,8) = ...
        %  num2cell(flipud(position.reqordersprofile(:,rcol.id)));
        [tmp idx] = sortrows(cell2mat(ordersdata(:,4)),-1);
        ordersdata = ordersdata(idx,:);
        set(orders,'Data',ordersdata);
        else
          set(orders,'Data',[]);
        end
        
      else
        set(orders,'Data',[]);
      end
    end
  end
  guidata(curr_fig,cfighandles);
end

