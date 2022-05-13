
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

for t=round(dstart):round(dend)
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
  
query = ['SELECT p_symbol,p_time,d_open,d_close,d_max,d_min,'...
          'd_volume,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_Avg '...
          'FROM dbmarketdata.mdquotes '...
          'where p_period = 86400 '...
          'and p_tradedate>=''2014-01-01'' '...
          'and  p_exchange=''XBOV'' ;'];
  [ buffer.symbol,      buffer.time,buffer.open,    buffer.close,   buffer.max, buffer.min,...
    buffer.volume,  buffer.buyQty, buffer.sellQty,  buffer.buyAvg, buffer.sellAvg, buffer.avg] = mysql(query);
  mysql('close') 
  if size(buffer.symbol,1)>0
  newidx = quotes.count+1:quotes.count+size(buffer.symbol,1);
  newidx = newidx';
  quotes.symbol(newidx) = buffer.symbol;
  quotes.data(newidx,cols.time) = buffer.time;
  quotes.data(newidx,cols.open) = buffer.open;
  quotes.data(newidx,cols.close) = buffer.close;
  quotes.data(newidx,cols.max) = buffer.max;
  quotes.data(newidx,cols.min) = buffer.min;
  quotes.data(newidx,cols.volume) = buffer.volume;
  quotes.data(newidx,cols.buyQty) = buffer.buyQty;
  quotes.data(newidx,cols.sellQty) = buffer.sellQty;
  quotes.data(newidx,cols.buyAvg) = buffer.buyAvg;
  quotes.data(newidx,cols.sellAvg) = buffer.sellAvg;
  quotes.data(newidx,cols.avg) = buffer.avg;
  quotes.count = quotes.count + size(buffer.symbol,1);
  quotes.count
  end
  tday = toc(td);
  %fprintf('%s , %f\n',datestr(t,'yyyy-mm-dd'),tday)
  fprintf('%f\n',tday)
%end
%}

idx = strcmp(quotes.symbol,'VALE5');
figure; hold on;
ratio = quotes.data(find(idx,1),cols.open);
candle(quotes.data(idx,cols.max)./ratio,quotes.data(idx,cols.min)./ratio,...
      quotes.data(idx,cols.close)./ratio,quotes.data(idx,cols.open)./ratio,...
      [],quotes.data(idx,cols.time),'yyyy-mm')
%}

toc(te)