clc
mysql( 'open', '127.0.0.1:6446', 'traders', 'kapitalo' );

query = ['SELECT symbol,lasttrade FROM dbconfig.symbol ',...
         'where market = ''WIN'' ',...
         'and contracttype = ''FUT'' ',...
         'and `exchange` = ''BVMF'' ',...
         'order by lasttrade asc '];
[ symbol , lasttrade] = mysql(query);

query = ['SELECT tradedate FROM dbconfig.tradedate'];
[ tradedate ] = mysql(query);

query_prefix = ['INSERT IGNORE into dbconfig.series',...
                '(serie,tradedate,symbol,name) ',...
                'VALUES '];
for t = 1:length(tradedate)
    if tradedate(t) >= today
    next_exp_id = find (lasttrade > tradedate(t),1);
    serie_date = sprintf('(''INDFUT'', ''%s'' , ''%s'' , ''MINI'')',...
        datestr(tradedate(t),'yyyy-mm-dd'), symbol{next_exp_id});
    disp(serie_date);
    query = strcat(query_prefix,serie_date);
    [ lines ] = mysql(query);
    end
end
%}
mysql('close')