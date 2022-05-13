function [pricemarket, pricemarket_dic] = convert_single_file(curr_file_path,tick_size)
%curr_file_path = 'C:/TRADE/TRADEDAYS/2015_09_09/DATAFEED/WINV15_2015_09_09.bin';
%tick_size = 5;
try
    pricemarket = [];
    pricemarket_dic = [];
    
    TAG_TRADE_BUY_MARKET = 1;
    TAG_TRADE_SELL_MARKET = 2;
    TAG_TRADE_NEUTRAL = 3;
    TAG_BOOK_OFFER_UPDATE = 4;
    TAG_BOOK_BID_UPDATE = 5;

    disp(' ');
    disp('converting...');
    disp(curr_file_path);

    %read file
    tic
    file_handle = fopen(curr_file_path,'r');
    fseek(file_handle,0,'eof');
    curr_bytes = ftell(file_handle);
    fseek(file_handle,0,'bof');
    cols = 68;
    rows = floor(curr_bytes/(cols*8));
    events = fread(file_handle,[cols rows],'double');
    events = events';
    fclose(file_handle);
    tfile = toc;
    disp('Time to read file:');
    disp(tfile);
    disp(' ');
    n_events = size(events,1);
    disp(strcat('Number of events:',num2str(n_events)));

    if (n_events > 0)
        events = sortrows(events,4); %sort by id

        time_reference = datenum('1970', 'yyyy'); 
        time = time_reference + (events(:,3) ./ 8.64e4);

        last_book = zeros(20000,1);
        curr_book = zeros(20000,1);
        book_ids = [1:20000]';

        n_evts = 0;
        pricemarket = zeros(10000000,5);
        pricemarket_dic = 'i_id,i_tag,t_time,d_price,d_value';
        last_trade_event = 1;
        for e=1:n_events

            if events(e,1) == 1 %trade
                price = events(e,7);
                valid_p = price > tick_size*10 & price < 20000*tick_size;
                if any(valid_p)
                    n_evts = n_evts+1;

                    bid = events(e,5);   	
                    ask = events(e,6); 
                    value = (bid+ask)/2;

                    if last_trade_event ~=1
                       tag = pricemarket(last_trade_event,2); 
                    else
                       tag = TAG_TRADE_NEUTRAL;
                    end
                    
                    if price > value
                        tag = TAG_TRADE_BUY_MARKET;
                    elseif price < value 
                        tag = TAG_TRADE_SELL_MARKET;
                    end
                    volume = events(e,8);

                    pricemarket(n_evts,1) = n_evts;      %id
                    pricemarket(n_evts,2) = tag;         %tag
                    pricemarket(n_evts,3) = time(e);     %time
                    pricemarket(n_evts,4) = price;       %price
                    pricemarket(n_evts,5) = volume;      %volume

                    last_trade_event = e;
                end
            end

           if events(e,1) == 2 %book
              prices = events(e,5:36);
              volumes = [-events(e,37:52) events(e,53:68)];
              valid_p = prices > tick_size*10 & prices < 20000*tick_size;
              valid_v = volumes >= -65365 & volumes < 65365;
              if all(valid_p) && all(valid_v)
                  %zeroes the book inside range
                  top_of_book = round(max(prices)/tick_size);
                  best_offer = round(prices(16)/tick_size);
                  best_bid = round(prices(17)/tick_size);
                  bottom_of_book = round(min(prices)/tick_size);
                  curr_book(bottom_of_book:top_of_book) = 0;
                  %update new data
                  curr_book(round(prices./tick_size)) = volumes;
                  %check for changes
                  book_changes = curr_book ~= last_book;
                  book_change_ids = book_ids.*book_changes;
                  book_change_ids(book_change_ids==0)=[];
                  for b=1:length(book_change_ids)
                    n_evts = n_evts + 1;
                    if book_change_ids(b) >= best_offer
                        tag = TAG_BOOK_OFFER_UPDATE;     
                    elseif book_change_ids(b) <= best_bid
                        tag = TAG_BOOK_BID_UPDATE;  
                    else
                        tag = TAG_BOOK_OFFER_UPDATE;
                    end
                    
                    volume = abs(curr_book(book_change_ids(b)));
                    price = book_change_ids(b)*tick_size;
                    
                    pricemarket(n_evts,1) = n_evts;      %id
                    pricemarket(n_evts,2) = tag;         %tag
                    pricemarket(n_evts,3) = time(e);     %time
                    pricemarket(n_evts,4) = price;       %price
                    pricemarket(n_evts,5) = volume;      %volume
                  end
                  last_book = curr_book;
              end
           end

        end

        disp(sprintf('final lines %i!',n_evts));
        toc

        pricemarket = pricemarket(1:n_evts,:);
    end
catch
   disp(lasterr);
   pause(1);
end
end
