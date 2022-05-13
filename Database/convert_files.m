clc
folder = 'C:/TRADE/TRADEDAYS/';
database_folder = 'C:/DB/';
table = 'pricemarket/';
marketdata = 'mdmt5_main/';
start_date = datenum(2015,04,10);
end_date = datenum(2015,09,30);

%list tradedays
listing = dir(folder);
d = 0;

%open each tradeday
for t=3:length(listing)
 today = datenum(listing(t).name,'yyyy_mm_dd');
 if today>=start_date && today<=end_date
   disp(datestr(today));
   %create symbol path
   tradeday_path = strcat(folder,listing(t).name);
   datafeed_path = strcat(tradeday_path,'/DATAFEED/');
   %find symbol file
   flisting = dir(datafeed_path);
   for f=3:length(flisting)
       curr_file_path = strcat(datafeed_path,flisting(f).name);
       k = strfind(curr_file_path,'CANDLE');
     if isempty(k)
         disp(curr_file_path);
         if strfind(curr_file_path,'WIN')
             tick_size = 5;
         elseif strfind(curr_file_path,'WDO')
             tick_size = .5;
         elseif strfind(curr_file_path,'IND')
             tick_size = 5;
         elseif strfind(curr_file_path,'DOL')
             tick_size = .5;
         end
         [pricemarket, pricemarket_dic] = ...
             convert_single_file(curr_file_path,tick_size);
       if size(pricemarket,1) > 0
           tradedate_str = datestr(today,'yyyy-mm-dd');
           save_folder = strcat(database_folder,table);
           save_folder = strcat(save_folder,tradedate_str);
           save_folder = strcat(save_folder,'/');
           save_folder = strcat(save_folder,marketdata);
           if ~exist(save_folder,'dir')
               mkdir(save_folder);
           end
           symbol_temp = strsplit(flisting(f).name,'_');
           symbol_str = symbol_temp(1);
           bin_filename = strcat(symbol_str,'.bin');
           dict_filename = strcat(symbol_str,'.csv');
           data_file_path = strcat(save_folder,bin_filename);
           data_file_path = cell2mat(data_file_path);
           pricemarket_file = fopen(data_file_path,'w');
           fwrite(pricemarket_file,pricemarket','double');
           fclose(pricemarket_file);
           dictionary_file_path = strcat(save_folder,dict_filename);
           dictionary_file_path = cell2mat(dictionary_file_path);
           dictionary_file = fopen(dictionary_file_path,'w');
           fwrite(dictionary_file,pricemarket_dic);
           fclose(dictionary_file);
       end
     end
   end
 end
end