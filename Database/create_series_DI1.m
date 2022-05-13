clc
mysql( 'open', 'localhost', 'traders', 'kapitalo' );

query = ['SELECT s_symbol,t_lasttrade FROM dbconfig.symbols ',...
         'where s_market = ''DI1'' ',...
         'and s_contract = ''FUT'' ',...
         'and s_symbol like ''DI1F%'' ',...
         'order by t_lasttrade asc '];
[ symbol , lasttrade] = mysql(query);

query = ['SELECT t_tradedate FROM dbconfig.tradedates'];
[ tradedate ] = mysql(query);

%
query_prefix = ['INSERT IGNORE into dbconfig.series',...
                '(s_serie,t_tradedate,s_symbol,s_name) ',...
                'VALUES '];
for t = 1:length(tradedate)
    next_exp_id = find (lasttrade > tradedate(t)+365,1);
    serie_date = sprintf('(''DI1FUT'', ''%s'' , ''%s'' , ''DI1$'')',...
        datestr(tradedate(t),'yyyy-mm-dd'), symbol{next_exp_id});
    disp(serie_date);
    query = strcat(query_prefix,serie_date);
    [ lines ] = mysql(query);
end
%}
mysql('close')