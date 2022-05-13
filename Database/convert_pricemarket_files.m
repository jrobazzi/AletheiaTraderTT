clc
clear all

pmarketfolder = 'C:/DB/pricemarket/RT/';
marketdata = {'mdmt5_main'};
start_date = datenum(2016,01,01);
end_date = datenum(2016,02,17);
mdtradesdict = 'i_id,i_tradeid,i_buyfirm,i_sellfirm,t_timestamp,i_tag,t_time,d_price,d_value';
tic
%list tradedays
listing = dir(pmarketfolder);
d = 0;
%open each tradeday
for t=3:length(listing)
   today = datenum(listing(t).name,'yyyy-mm-dd');
   if today>=start_date && today<=end_date
       found = false;
       disp(datestr(today));
       for md=1:length(marketdata)
           %create symbol path
           tradeday_path = strcat(pmarketfolder,listing(t).name);
           tradeday_path = strcat(tradeday_path,'/');
           tradeday_path = strcat(tradeday_path,marketdata{md});
           tradeday_path = strcat(tradeday_path,'/');

           %find symbol file
           flisting = dir(tradeday_path);
           for f=3:length(flisting)
             curr_file_path = strcat(tradeday_path,flisting(f).name);
             k1 = strfind(curr_file_path,'.bin');
             if ~isempty(k1)
               found = true;
               fields = strsplit(curr_file_path,'/');
               filename = fields(end);
               disp(filename);
               %read pricemarket file
               file = fopen(curr_file_path,'r');
               fseek(file,0,'eof');
               fbytes = ftell(file);
               cols = 5;
               rows = fbytes/(cols*8);
               fseek(file,0,'bof');
               pricemarket = fread(file,[cols rows],'double');
               pricemarket = pricemarket';
               fclose(file);
               %write mdtrades file
               if ~isempty(pricemarket)
                 tradeidx = pricemarket(:,2) <=3;           
                 ntrades = sum(tradeidx);
                 if ntrades > 0
                   mdtrades = zeros(ntrades,9);
                   mdtrades(:,1) = 1:ntrades;
                   mdtrades(:,2) = 1:ntrades;
                   mdtrades(:,6:9) = pricemarket(tradeidx,2:5);
                   buyidx = mdtrades(:,6) == 1;
                   if ~isempty(buyidx)
                     mdtrades(buyidx,6) = 300;
                   end
                   sellidx = mdtrades(:,6) == 2;
                   if ~isempty(sellidx)
                     mdtrades(sellidx,6) = 301;
                   end
                   crossidx = mdtrades(:,6) == 3;
                   if ~isempty(crossidx)
                     mdtrades(crossidx,6) = 302;
                   end
                   mdtradesfpath = strrep(curr_file_path,'pricemarket','mdtrades');
                   [pathstr,name,ext] = fileparts(mdtradesfpath);
                   if ~exist(pathstr,'dir')
                     mkdir(pathstr);
                   end
                   file = fopen(mdtradesfpath,'w');
                   fwrite(file,mdtrades','double');
                   fclose(file);
                   mdtradesdictpath = strrep(mdtradesfpath, '.bin', '.csv');
                   file = fopen(mdtradesdictpath,'w');
                   fprintf(file,mdtradesdict);
                   fclose(file);
                 end
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
disp('done!')
