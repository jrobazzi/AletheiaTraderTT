clear all

lastrows = 0;
curr_file_path = 'C:\TRADE\mdmql5_priceentry\2015-09-17\DOLV15_2015-09-17.bin';
file = fopen(curr_file_path,'r');
fseek(file,0,'eof');
fbytes = ftell(file);
rows = fbytes/40;
lastrows = rows;
lastrows = 0;
book = zeros(1,20000);
tick_size = 0.5;
while(1)
    
    
    fseek(file,0,'eof');
    fbytes = ftell(file);
    rows = fbytes/40;
    newrows = floor(rows-lastrows);
    if rows>lastrows
        
        fseek(file,lastrows*40,'bof');
        new_trades = fread(file,[5 newrows],'double');
        new_trades = new_trades';
        lastrows = rows;
        
        if exist('trades','var')
            trades(end+1:end+newrows,:) = new_trades;
        else
            trades = new_trades;
        end
        
        book_idx = new_trades(:,3) > 3;
        offer_idx = new_trades(:,3) == 4 | new_trades(:,3) == 6;
        
        book_ids = round(new_trades(book_idx,4)/tick_size);
        new_trades(offer_idx,5) = -new_trades(offer_idx,5);
        book(book_ids) = new_trades(book_idx,5);
        
        figure(1)
        plot(trades(:,2),trades(:,4));
        datetick('x')

        figure(2)
        mid = round(mean(trades(:,4))/tick_size);
        book_range = mid-100:mid+100;
        barh(book_range.*tick_size,book(book_range));
        grid on
    end
    pause(0.100);
end
fclose(file);