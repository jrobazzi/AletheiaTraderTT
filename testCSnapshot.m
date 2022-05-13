%{
clear all;
ID = CIntraday();
SS = CSnapshot();
%}
SID = 62281;
period = 6;
nbars = 300;
figure(1); grid on;
maxdelay=0;
while 1
  ti = tic;
  ID.Update();
  SS.Update();
  pause(0.001)
  maxdelay = max(maxdelay,toc(ti));
  fprintf('DOLQ17: %2.2f, %i, %2.0f,%2.0f\n',...
    SS.snapshot(SID,9),SS.snapshot(SID,44),maxdelay*1000,toc(ti)*1000)
  candle(ID.intraday{period,SID}(end-nbars:end,4), ID.intraday{period,SID}(end-nbars:end,5), ...
    ID.intraday{period,SID}(end-nbars:end,3), ID.intraday{period,SID}(end-nbars:end,2));
  grid on;
  drawnow;
end