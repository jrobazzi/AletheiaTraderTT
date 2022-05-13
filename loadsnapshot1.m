tic
if ~exist('ts','var')
  ts = datenum(1970,01,01);
end
dict = 't_ts,s_source,p_exchange,p_symbol,p_tag,s_market,t_time,d_value,s_value';
query = sprintf(['SELECT * FROM dbmarketdata.snapshot '...
    'WHERE p_exchange= ''XBMF'' and s_market = ''DI1'' and t_ts>''%s'';'],...
    datestr(ts,'yyyy-MM-dd HH:mm:ss.fff'));
h = mysql( 'open', 'BDKPTL03','traders', 'kapitalo' );
[result.t_ts,result.s_source,result.p_exchange,result.p_symbol,result.p_tag,result.s_market,result.t_time,result.d_value,result.s_value] = ...
mysql(query);
mysql('close')
for i=1:length(result.t_ts)
  exch = cell2mat(result.p_exchange(i));
  symb = cell2mat(result.p_symbol(i));
  tag = cell2mat(result.p_tag(i));
  if result.t_ts(i) > ts
    ts = result.t_ts(i);
  end
  if tag(1) == 'd'
    snapshot.(exch).(symb).(tag) = result.d_value(i);
  elseif tag(1) == 's'
    snapshot.(exch).(symb).(tag) = result.s_value(i);
  elseif tag(1) == 't'
    snapshot.(exch).(symb).(tag) = result.t_time(i);
  end
end
toc
