%
clear all
te = tic;
dstart = datenum(2004,01,01);
dend = datenum(2017,02,06);
host = 'BDKPTL03';

h = mysql( 'open', host,'traders', 'kapitalo' );
query = sprintf(['SELECT COLUMN_NAME ',...
                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                  'AND TABLE_NAME = ''%s'';'],...
                  'dbmarketdata',...
                  'intraday');
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
query = sprintf(['SELECT * FROM dbmarketdata.intraday '...
  'WHERE p_tradedate>''%s'' '...
  'AND p_period=15 '...
  'and s_market in (''DOL'',''WDO'') '...
  'AND s_contractType in (''FUT'');'],...
  datestr(dstart,'yyyy-mm-dd'));
h = mysql( 'open', host,'traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_period,p_time,s_market,s_contractType,d_open,d_close,d_max,d_min,d_trades,d_volume,d_avg,d_buyQty,d_buyAvg,d_sellQty,d_sellAvg] = mysql(query);
mysql('close')
daily = table(t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_period,p_time,s_market,s_contractType,d_open,d_close,d_max,d_min,d_trades,d_volume,d_avg,d_buyQty,d_buyAvg,d_sellQty,d_sellAvg);
  
toc(te)
%}

figure
dolidx = strcmp(daily.s_market,'DOL') & ...
  strcmp(daily.s_contractType,'FUT') & ...
  daily.d_futSeq==1 ;
candle(daily.d_max(dolidx),daily.d_min(dolidx),daily.d_last(dolidx),daily.d_open(dolidx),[],daily.p_tradedate(dolidx))
%}

%{
di1idx = strcmp(daily.s_market,'DI1') & ...
    strcmp(daily.s_contractType,'FUT');
 
yieldidx = daily.d_yieldDays~=0;
ffutidx=daily.d_futSeq==1;
days = unique(daily.p_tradedate);
for d=1:length(days)
  currd = days(d);
  currdidx = daily.p_tradedate == currd & di1idx & yieldidx;
  m2m = daily.d_m2m(currdidx);
  yieldDays = daily.d_yieldDays(currdidx);
  yield = (((100000./m2m).^(252./yieldDays))-1)*100;
  figure(1)
  plot(daily.t_liquidation(currdidx),yield,'*')
  hold on
  datetick('x')
  pause(0.05)
end
%}
%{
array(:,1) = daily.d_yieldDays(di1idx);
array(:,2) = daily.d_contracts(di1idx);
[C,ia,idx] = unique(array(:,1),'stable');
 val = accumarray(idx,array(:,2),[],@mean); 
meancontracts.diasSaque = C;
meancontracts.mediaContratos = val;
mconttbl = struct2table(meancontracts);
writetable(mconttbl,'MediaContratosDiasSaque.xlsb');

array(:,1) = daily.d_yieldDays(di1idx);
array(:,2) = daily.d_volumeBRL(di1idx);
[C,ia,idx] = unique(array(:,1),'stable');
 val = accumarray(idx,array(:,2),[],@mean); 
meanvolume.diasSaque = C;
meanvolume.mediaVolume = val;
mvoltbl = struct2table(meanvolume);
writetable(mvoltbl,'MediaVolumeBRLDiasSaque.xlsb');

 
figure(1000)
bar(C,val)
%}