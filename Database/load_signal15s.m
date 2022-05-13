clc
clear all

folder = 'C:/DB/signals/SIM/';
start_date = datenum(2012,01,01);
end_date = datenum(2016,02,19);

tic
%list tradedays
listing = dir(folder);
d = 0;
%open each tradeday
for t=3:length(listing)
   today = datenum(listing(t).name,'yyyy-mm-dd');
   if today>=start_date && today<=end_date
       found = false;
       %create symbol path
       tradeday_path = strcat(folder,listing(t).name);
       tradeday_path = strcat(tradeday_path,'/');
       tradeday_path = strcat(tradeday_path,'SignalTrades15S/');       

       %find symbol file
       flisting = dir(tradeday_path);
       for f=3:length(flisting)
         curr_file_path = strcat(tradeday_path,flisting(f).name);
         k = strfind(curr_file_path,'INDFUT_MINI');
         k1 = strfind(curr_file_path,'.bin');
         if ~isempty(k) && ~isempty(k1)
           found = true;
           fields = strsplit(curr_file_path,'/');
           disp(curr_file_path);
           file = fopen(curr_file_path,'r');
           fseek(file,0,'eof');
           fbytes = ftell(file);
           rows = fbytes/(5*8);
           fseek(file,0,'bof');
           new_trades = fread(file,[5 rows],'double');
           new_trades = new_trades';
           fclose(file);
           if ~exist('trades','var')
               trades = new_trades;
           else
             if ~isempty(new_trades)
               trades(end+1:end+size(new_trades,1),:) = new_trades;
             end
           end
           break;
         end
       end
   end
end
toc

plot(1:size(trades,1),trades(:,4));

