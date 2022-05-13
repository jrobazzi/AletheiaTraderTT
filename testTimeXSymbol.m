
clear all
te = tic;
dstart = datenum(2017,01,01);
dend = datenum(2017,11,30);

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
query = sprintf(['SELECT COLUMN_NAME ',...
                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                  'AND TABLE_NAME = ''%s'';'],...
                  'dbmarketdata',...
                  'mdquotes');
[ fields ] = mysql(query);
mysql('close') 
cols_count=0;
%create dictionary
for f=1:length(fields)
  column = strsplit(cell2mat(fields(f)),'_');
  if size(column,2)>1
    if ~strcmp(column{1},'s')
      cols_count = cols_count +1;
      cols.(column{2:end}) = cols_count;
      dictionary{cols_count} = fields{f};
      columns{cols_count} = column{2:end};
      columns_type{cols_count} = column{1};
    end
  end
end

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
quotes.symbol=cell(10000000,1);
quotes.data=zeros(10000000,13);
quotes.count = 0;

%for t=round(dstart):round(dend)
  td = tic;
  
  h = mysql( 'open', 'localhost','traders', 'kapitalo' );
  %{
  query = sprintf(['select s_symbol,'...
                    'i_id,t_time,d_open,d_close,d_max,d_min,'...
                    'd_volume,d_buyvolume,d_sellvolume,'...
                    'd_bestbid,d_bidqty,d_bestask,d_askqty '...
                    'from dbmarket.mdquotes ',...
                    'where s_source=''RT'' ',...
                    'and s_tradedate = ''%s'' '...
                    'and s_marketdata = 4 '...
                    'and s_period = ''S15'' '...
                    'and s_symbol in '...
                    '(SELECT s_symbol FROM dbconfig.series '...
                    'where s_serie=''DOLFUT'' '...
                    'and s_name=''FULL'' '...
                    'group by s_symbol);'],...
                    datestr(t,'yyyy-mm-dd'));
                  %}
period = 86400;  
query = ['SELECT p_symbol,p_time,d_open,d_close,d_max,d_min,'...
          'd_volume,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_Avg '...
          'FROM dbmarketdata.mdquotes '...
          'where p_period = 86400 '...
          'and p_tradedate>=''2014-01-01'' '...
          'and  p_exchange in (''XBOV'',''XBMF'') ;'];
[ buffer.symbol,      buffer.time,buffer.open,    buffer.close,   buffer.max, buffer.min,...
  buffer.volume,  buffer.buyQty, buffer.sellQty,  buffer.buyAvg, buffer.sellAvg, buffer.avg] = mysql(query);
mysql('close') 
if size(buffer.symbol,1)>0
  symbols = unique(buffer.symbol);
  nsymbols = length(symbols);
  ftime = min(buffer.time);
  for i=1:nsymbols
    symbol = symbols{i};
    mdquotes.(symbol) = i;
    symbolIdx = strcmp(buffer.symbol,symbols{i});
    time = buffer.time(symbolIdx);
    timeidx = 1 + round((time-ftime)./(period*datenum(0,0,0,0,0,1)));
    mdquotes.close(timeidx,i) = buffer.close(symbolIdx);
    mdquotes.rlog(timeidx,i) = ...
      [0; log(mdquotes.close(timeidx(2:end),i)./...
          mdquotes.close(timeidx(1:end-1),i))];

    fprintf('%.2f%% \r',100*i/nsymbols);
  end
end
tday = toc(td);
fprintf('%f\n',tday)
%}
figure
plot(cumsum(mdquotes.rlog(:,mdquotes.PETR4)))
hold on
plot(cumsum(mdquotes.rlog(:,mdquotes.PETR3)))
plot(cumsum(mdquotes.rlog(:,mdquotes.VALE3)))
plot(cumsum(mdquotes.rlog(:,mdquotes.VALE5)))
plot(cumsum(mdquotes.rlog(:,mdquotes.ITUB4)))
plot(cumsum(mdquotes.rlog(:,mdquotes.ITSA4)))

%}
%{
figure; hold on;
ratio = quotes.data(find(idx,1),cols.open);
candle(quotes.data(idx,cols.max)./ratio,quotes.data(idx,cols.min)./ratio,...
      quotes.data(idx,cols.close)./ratio,quotes.data(idx,cols.open)./ratio,...
      [],quotes.data(idx,cols.time),'yyyy-mm')
%}

toc(te)