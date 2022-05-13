%clear all and store breakpoints
%addpath(genpath('./'));
if isempty(handles.Market)
  Market = MarketMain(hObject,handles);
  Market.InitHistory(Market.startdate);
  handles.Market = Market;
  guidata(hObject, handles);
else
  samemode = (handles.Market.backtest && handles.radiobuttonBT.Value)...
          || (handles.Market.sim && handles.radiobuttonSIM.Value)...
          || (~handles.Market.sim && handles.radiobuttonRT.Value);
  sameperiod=...
    (handles.Market.startdate == datenum(handles.startdate.String))...
    && (handles.Market.enddate == datenum(handles.enddate.String));
  sameinit = (handles.Market.ninit == handles.popupmenu_init.Value);
  if samemode && sameperiod && sameinit
    Market = handles.Market;
  else
    Market = MarketMain(hObject,handles);
    Market.InitHistory(Market.startdate);
    handles.Market = Market;
    guidata(hObject, handles);
  end
end
rtime = tic;
Market.InitSignals();
Market.InitPositions(Market.simdates(1));
Market.InitFunds(Market.simdates(1));
Market.StartTradedate(Market.simdates(1));
%% TRADEDATE LOOP
Market.RealtimeLoop();
%% END LOOP 
Market.FinishTradedate();
disp('Runtime ended!!!');
toc(rtime)
