clc
clear all

folder = 'C:/DB/mdtrades/RT/';
marketdata = {'mdbvmf'};
start_date = datenum(2015,01,01);
end_date = datenum(2015,12,30);

tic
%list tradedays
listing = dir(folder);
d = 0;
%open each tradeday
for t=3:length(listing)
   today = datenum(listing(t).name,'yyyy-mm-dd');
   if today>=start_date && today<=end_date
       found = false;
       disp(datestr(today));
       for md=1:length(marketdata)
           %create symbol path
           tradeday_path = strcat(folder,listing(t).name);
           tradeday_path = strcat(tradeday_path,'/');
           tradeday_path = strcat(tradeday_path,marketdata{md});
           tradeday_path = strcat(tradeday_path,'/');

           %find symbol file
           flisting = dir(tradeday_path);
           for f=3:length(flisting)
             curr_file_path = strcat(tradeday_path,flisting(f).name);
             k = strfind(curr_file_path,'DOL');
             k1 = strfind(curr_file_path,'.bin');
             if ~isempty(k) && ~isempty(k1)
               found = true;
               fields = strsplit(curr_file_path,'/');
               if size(fields{end},2)==10
                 %disp(curr_file_path);
                 tick_size = .5;
                 file = fopen(curr_file_path,'r');
                 fseek(file,0,'eof');
                 fbytes = ftell(file);
                 rows = fbytes/(9*8);
                 if rows > 1000
                   fseek(file,0,'bof');
                   new_trades = fread(file,[9 rows],'double');
                   new_trades = new_trades';
                   if ~exist('trades','var')
                       trades = new_trades;
                   else
                     if ~isempty(new_trades)
                       trades(end+1:end+size(new_trades,1),:) = new_trades;
                     end
                   end
                   break;
                 end
                 fclose(file);
               end
               
             end
           end
           if found 
               %break;
           end
       end
   end
end
toc

plot(trades(:,7),trades(:,8));
datetick('x');
disp(size(trades))
