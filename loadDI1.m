clear all
te = tic;
dstart = datenum(2013,01,01);
dend = datenum(2017,05,02);

h = mysql( 'open', 'BDKPTL03','traders', 'kapitalo' );
query = sprintf(['SELECT COLUMN_NAME ',...
                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                  'AND TABLE_NAME = ''%s'';'],...
                  'dbmarketdata',...
                  'daily');
[ fields ] = mysql(query);
mysql('close') 
cols_count=0;
str_query = '';
str_qresult = '';
%create dictionary
for f=1:length(fields)
  column = strsplit(cell2mat(fields(f)),'_');
  if size(column,2)>1
      cols_count = cols_count +1;
      cols.(column{2:end}) = cols_count;
      dictionary{cols_count} = fields{f};
      columns{cols_count} = column{2:end};
      columns_type{cols_count} = column{1};
      str_query = strcat(str_query,fields{f});
      str_query = strcat(str_query,',');
      str_qresult = strcat(str_qresult,'result.');
      str_qresult = strcat(str_qresult,fields{f});
      str_qresult = strcat(str_qresult,',');
  end
end
str_query = str_query(1:end-1);

ntd = 0;
query = sprintf(['SELECT %s FROM dbmarketdata.daily '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'' '...
  'ORDER BY p_tradedate;'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'BDKPTL03','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result] = mysql(query);
mysql('close')
daily = table(p_tradedate,t_ts,s_source,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater);
toc(te)
%}