function RISK_GUI_Template(curr_fig, cfighandles )

%TEMPLATE_MARKET
%   Plot market
  if ~isempty(cfighandles.Account)
    if ~isempty(cfighandles.Strategy)
      if ~isempty(cfighandles.Position)
        position = cfighandles.Position;
        pcol = position.IO.cols;
        cfighandles.edit_position_equity.String = ...
          num2str(position.alocation(pcol.value));
        cfighandles.edit_position_stop.String = ...
          num2str(position.stoploss(pcol.value));
        tcol = position.OMS(1).OMSTrades.cols;
        if position.ntrades>0
          cfighandles.edit_position_contracts.String = ...
            num2str(position.contracts(position.ntrades));
        else
          cfighandles.edit_position_contracts.String = '0';
        end
        position.autotrade(pcol.value) = ...
          cfighandles.checkbox_position_auto.Value;
        status = position.status(pcol.value);
        if status>0
          cfighandles.text_position_status.String =...
            position.OMS_STATUS(status);
        else
          cfighandles.text_position_status.String ='OFF';
        end
        if status == position.OMS_STATUS_AUTO
          cfighandles.text_position_status.BackgroundColor = [.94 .94 .94];
        elseif status == position.OMS_STATUS_MANUAL
          cfighandles.text_position_status.BackgroundColor = [.94 0 0];
        else
          cfighandles.text_position_status.BackgroundColor = [.94 .94 0];
        end
        
        noms = cfighandles.popupmenu_oms.Value-1;
        if noms>0
         if position.OMS(noms).active
           position.activeOMS = noms;
         end
        end
        
        if length(cfighandles.popupmenu_oms.String) ~=...
                      length(position.OMS)
          for o = 1:length(position.OMS)
            cfighandles.popupmenu_oms.String{o+1} = ...
              position.OMS(o).Instance.Attributes.oms;
            if position.activeOMS == o
              cfighandles.popupmenu_oms.Value = o+1;
            end
          end
        end
      end
    end
  end
  guidata(curr_fig,cfighandles);
end

