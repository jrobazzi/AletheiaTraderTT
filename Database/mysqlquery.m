clc
clear all
mysql( 'open', 'localhost', 'traders', 'qazxc123' );

query = sprintf(['SELECT s_marketdata,i_priority FROM db.marketdata '...
                    'ORDER BY i_priority DESC'],datestr(now,'yyyy-mm-dd'));

[ marketdata, priority ] = mysql(query);

for s = 1:length(marketdata)
    disp(sprintf('%s , %i',marketdata{s},priority(s)));
end

query = sprintf(['SELECT s_symbol,s_alias FROM db.series ',...
         'where s_serie = ''DOLFUT'' ',...
         'and t_tradedate = ''%s'' '],datestr(now,'yyyy-mm-dd'));
[ symbols, aliases ] = mysql(query);

for s = 1:length(symbols)
    disp(sprintf('%s , %s',symbols{s},aliases{s}));
end

mysql('close')
