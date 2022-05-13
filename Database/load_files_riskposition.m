
clc
clear all

market = 'DOL';
%market = 'WDO';
%market = 'IND';
%market = 'WIN';

%strategy = 'Trading_Moedas';
%strategy = 'Trading_Moedas_Channel';
%strategy = 'Trading_Moedas_ShortVol';
strategy = 'Channel';
%strategy = 'ShortVol';
%strategy = 'DeltaHedge';

folder = 'C:\DB\riskpositions\RT\';
acc_strategy = '\235765\';
acc_strategy = '\MASTERKPTL\';
acc_strategy = strcat(acc_strategy,strategy);
acc_strategy = strcat(acc_strategy,'\');
marketdata = {'mdbvmf'};
start_date = datenum(2016,03,20);
end_date = datenum(2016,06,30);
tic
%list tradedays
listing = dir(folder);
d = 0;
%open each tradeday
results = [];
for t=3:length(listing)
  today = datenum(listing(t).name,'yyyy-mm-dd');
  %disp(datestr(today));
  if today>=start_date && today<=end_date
    found = false;
    %create symbol path
    tradeday_path = strcat(folder,listing(t).name);
    tradeday_path = strcat(tradeday_path,acc_strategy);
    flisting = dir(tradeday_path);
   
   for f=3:length(flisting)
     curr_file_path = strcat(tradeday_path,flisting(f).name);
     k = strfind(curr_file_path,market);
     k1 = strfind(curr_file_path,'.bin');
     if today > 735978
       %disp('no data');
     end
     if ~isempty(k) && ~isempty(k1)
       %disp(curr_file_path);
       file = fopen(curr_file_path,'r');
       fseek(file,0,'eof');
       fbytes = ftell(file);
       rows = fbytes/(6*8);
       if rows > 0
         disp(datestr(today));
         fseek(file,0,'bof');
         new_trades = fread(file,[6 rows],'double');
         new_trades = new_trades';
         if size(new_trades,1)>0
         returnidx = new_trades(:,3) == 81;
         if isempty(results)
           results.value = new_trades(returnidx,end);
           results.time = new_trades(returnidx,4);
           results.daccumreturn = results.value;
         else
           %{
           results.daccumreturn = new_trades(returnidx,end) +...
                                          results.value(end);
           results.value(end+1:end+sum(returnidx)) = results.daccumreturn(end);
           %}
           new_trades(returnidx,end) = new_trades(returnidx,end) +...
                                          results.value(end);
           results.value(end+1:end+sum(returnidx)) = new_trades(returnidx,end);
           
           results.time(end+1:end+sum(returnidx)) = new_trades(returnidx,4);
         end
         d = d+1;
         results.day(d) = results.time(end);
         results.accumreturn(d) = results.value(end);
         if d>1
         if results.accumreturn(d) - results.accumreturn(d-1)<=-0.002
           %results.accumreturn(d) = results.accumreturn(d-1)-0.002;
         end
         end
         %results.accumreturn(d) = results.daccumreturn(end);
         
         end
       else
         %disp('no data');
       end
       fclose(file);
     end
   end
   %}
  else
    %disp('no date');
  end
end
toc
%}
if ~isempty(results)
x = results.time;
%x = [1:size(results.value,1)]';
p = polyfit(x,results.value,1);
returnExpected = polyval(p,x);
returnError = results.value-returnExpected;
SSresid = sum(returnError.^2);
SStotal = (length(results.value)-1) * var(results.value);
figure(1)
plot(x,results.value);
hold on
plot(x,returnExpected);
hold off
grid on
datetick('x')
%{
a=[cellstr(num2str(get(gca,'ytick')'*100))]; 
pct = char(ones(size(a,1),1)*'%'); 
new_yticks = [char(a),pct];
set(gca,'yticklabel',new_yticks) 
%}
title('Accumulated Return')

figure(3)
bar(results.day,[results.accumreturn(1),diff(results.accumreturn)]);
grid on
datetick('x');
%{
a=[cellstr(num2str(get(gca,'ytick')'*100))]; 
pct = char(ones(size(a,1),1)*'%'); 
new_yticks = [char(a),pct];
set(gca,'yticklabel',new_yticks) 
%}
title('Daily Unleveraged Returns')
figure(2)
histfit(diff(results.accumreturn),100);
[u ,sig] = normfit(diff(results.accumreturn));
temp = [results.day;results.accumreturn];
%xlswrite(strcat(market,strcat(strategy,'.xlsx')),temp');
%save(strcat(market,strcat(strategy,'.mat')),'results')
end

