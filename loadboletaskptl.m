%
query = sprintf(['SELECT * FROM dbkptl.tbl_carteira1 '...
                  'where str_mesa=''%s'' '...
                  'and dte_data=''%s''; '],desk,date);
h = mysql( 'open', host,'traders', 'kapitalo' );
[dte_data,str_fundo,str_mesa,str_mercado,str_codigo,str_serie,dbl_lote,str_estrategia,ID,str_origem]=...
  mysql(query);
mysql('close')
str_symbol = strcat(str_codigo,str_serie);
dbl_result = zeros(length(str_symbol),1);
dbl_m2m = zeros(length(str_symbol),1);
carteira = table(dte_data,str_fundo,str_mesa,str_mercado,str_symbol,str_codigo,str_serie,dbl_lote,str_estrategia,ID,str_origem,dbl_result,dbl_m2m);
DI1 = 12.88;
DOLm2m = 3123.66;
%}
for c=1:length(carteira.str_estrategia)
  symbol = cell2mat(carteira.str_symbol(c));
  if any(strcmp(snapshot.Properties.RowNames,symbol))
    quoteType = cell2mat(snapshot.s_quoteType(symbol));
    if strcmp(quoteType,'points')
      carteira.dbl_result(c) = (snapshot.d_last(symbol)-snapshot.d_m2m(symbol))...
        *snapshot.d_pointValue(symbol)*carteira.dbl_lote(c);
      carteira.dbl_m2m(c) = (snapshot.d_m2m(symbol)-snapshot.d_lastM2m(symbol))...
        *snapshot.d_pointValue(symbol)*carteira.dbl_lote(c);
    elseif strcmp(quoteType,'yield')
      yieldDays = snapshot.d_yieldDays(symbol);
      fC = (1+DI1/100)^(1/252);
      m2mPU = snapshot.d_m2m(symbol);
      lastPU = snapshot.d_lastM2m(symbol);
      PU = 100000/...
        ((1+snapshot.d_last(symbol)/100)^(yieldDays/252));
      carteira.dbl_result(c) = -(PU-m2mPU*fC)...
        *snapshot.d_pointValue(symbol)*carteira.dbl_lote(c);
      carteira.dbl_m2m(c) = -(m2mPU-lastPU)...
        *snapshot.d_pointValue(symbol)*carteira.dbl_lote(c);
    end
  end
end
carteira
dbl_result = sum(carteira.dbl_result)
dbl_result = sum(carteira.dbl_result)/bps
dbl_m2m = sum(carteira.dbl_m2m)
dbl_m2m = sum(carteira.dbl_m2m)/bps


guidata(hObject, handles); % Update handles structure