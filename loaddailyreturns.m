%
clear all
te = tic;
dstart = datenum(2004,01,01);
dend = datenum(2017,06,06);
host = 'BDKPTL03';

h = mysql( 'open', host,'traders', 'kapitalo' );
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

figure(1)
cla
hold on
ntd = 0;
query = sprintf(['SELECT %s FROM dbmarketdata.daily '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND s_market in (''DOL'',''WDO'') '...
  'AND s_contractType=''FUT'' '...
  'and p_tradedate>=''2004-01-01'' '...
  'and p_tradedate<=''2017-06-06'';'],...
  str_query);
h = mysql( 'open', host,'traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_contractTypeId,s_market,s_contractType,s_contract,s_optionType,s_m2mType,s_lastM2mType,s_symbolVoice,s_channels,s_currency,t_strikeDate,t_lastTrade,t_liquidation,t_deliveryDate,t_time,d_open,d_max,d_min,d_close,d_closeQty,d_lastClose,d_last,d_avg,d_bestBid,d_bidQty,d_bestAsk,d_askQty,d_trades,d_contracts,d_openInterest,d_volumeBRL,d_volumeUSD,d_pointValue,d_m2m,d_lastM2m,d_m2mReturn,d_m2mValue,d_dM2m,d_dM2mValue,d_strikePrice,d_exercBRL,d_exercUSD,d_exercTrades,d_exercContracts,d_delta,d_impVol,d_yieldDays,d_totalDays,d_busDays,d_margin,d_marginMM,d_futSeq,d_lowerLimit,d_upperLimit,d_tickSize,d_buyAvg,d_sellAvg,d_buyQty,d_sellQty] = mysql(query);
mysql('close')
daily = table(t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_contractTypeId,s_market,s_contractType,s_contract,s_optionType,s_m2mType,s_lastM2mType,s_symbolVoice,s_channels,s_currency,t_strikeDate,t_lastTrade,t_liquidation,t_deliveryDate,t_time,d_open,d_max,d_min,d_close,d_closeQty,d_lastClose,d_last,d_avg,d_bestBid,d_bidQty,d_bestAsk,d_askQty,d_trades,d_contracts,d_openInterest,d_volumeBRL,d_volumeUSD,d_pointValue,d_m2m,d_lastM2m,d_m2mReturn,d_m2mValue,d_dM2m,d_dM2mValue,d_strikePrice,d_exercBRL,d_exercUSD,d_exercTrades,d_exercContracts,d_delta,d_impVol,d_yieldDays,d_totalDays,d_busDays,d_margin,d_marginMM,d_futSeq,d_lowerLimit,d_upperLimit,d_tickSize,d_buyAvg,d_sellAvg,d_buyQty,d_sellQty);
  
toc(te)
%}
