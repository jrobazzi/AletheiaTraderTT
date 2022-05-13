query = sprintf('SELECT t_tradedate FROM dbconfig.tradedates order by t_tradedate;');
h = mysql( 'open', 'BDKPTL03', 'traders', 'kapitalo' );
tradedates = mysql(query);
mysql('close') ;

fid = find(tradedates>datenum(2017,01,01),1,'first');
for t=fid:length(tradedates)
  
  query = ['insert ignore into dbaccounts.omsquotes ',...
    '(s_source,s_tradedate,s_account,s_symbol,
end