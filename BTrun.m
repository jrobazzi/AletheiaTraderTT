%clear all and store breakpoints
addpath(genpath('./'));
if isempty(handles.Market)
  Market = MarketMain(hObject,handles);
  lstdate = find(Market.tradedatevec > Market.simdates(end),1,'first');
  Market.InitHistory(Market.tradedatevec(lstdate));
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
    Market.ResetBacktest();
  else
    Market = MarketMain(hObject,handles);
    lstdate = find(Market.tradedatevec > Market.simdates(end),1,'first');
    Market.InitHistory(Market.tradedatevec(lstdate));
    handles.Market = Market;
    guidata(hObject, handles);
  end
end
rtime = tic;
cla(Market.handles.axes1);
while (~Market.sim_stop)
  %% TRADEDATE LOOP
  Market.InitSignals();
  %Market.BacktestResults();
  Market.BacktestLoop();
  if Market.sim_stop
    break;
  end
end
disp('Runtime ended!!!');
toc(rtime)
