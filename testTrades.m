
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
                  'mdtrades');
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

td = tic;
  
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
query = ['SELECT p_symbol,t_time,d_price,d_qty '...
        'FROM dbmarketdata.mdtrades '...
        'where p_tradedate>=''2017-01-01'' '...
        'and  p_exchange=2 '...
        'and p_symbol=''ABEV3'';'];
[ buffer.symbol, buffer.time, buffer.price, buffer.qty] = mysql(query);
mysql('close') 
if size(buffer.symbol,1)>0
newidx = quotes.count+1:quotes.count+size(buffer.symbol,1);
newidx = newidx';
quotes.symbol(newidx) = buffer.symbol;
quotes.data(newidx,cols.time) = buffer.time;
quotes.data(newidx,cols.price) = buffer.price;
quotes.data(newidx,cols.qty) = buffer.qty;
quotes.count = quotes.count + size(buffer.symbol,1);
quotes.count
end
tday = toc(td);
%fprintf('%s , %f\n',datestr(t,'yyyy-mm-dd'),tday)
fprintf('%f\n',tday)
  
toc(te)