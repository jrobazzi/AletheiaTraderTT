
fundo='KAPITALO ZETA MASTER FIM';
estrategia = 'Trading Moedas';

query = sprintf(['select * from dbkptl.tbl_boletas1 '...
  'where str_estrategia=''%s'' '...
  'and str_fundo=''%s'' '...
  'order by dte_data asc;'],estrategia,fundo);

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
 
[ boletas.data,  boletas.fundo,      boletas.corretora,...
    boletas.mercado,   boletas.codigo, boletas.serie,   boletas.descricao,...
    boletas.lote,...
    boletas.preco,  boletas.baseroll,boletas.estrategia,...
    boletas.chavetrader, boletas.confirmacao,...
    boletas.hora,boletas.mesa,boletas.origem] = ...
    mysql(query);
  
mysql('close') 

query = sprintf(['select * from dbkptl.tbl_carteira1 '...
  'where str_estrategia=''%s'' '...
  'and str_fundo=''%s'' '...
  'order by dte_data asc;'],estrategia,fundo);
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
 
[ carteira.data,  carteira.fundo,  carteira.mesa,...
    carteira.mercado,   carteira.codigo, carteira.serie,...
    carteira.lote, carteira.estrategia,...
    carteira.ID,carteira.origem] = ...
    mysql(query);
  
mysql('close') 

query = sprintf(['select dte_data,dbl_plpactual from dbkptl.tbl_cotaspl '...
  'where str_fundo=''%s'' '...
  'order by dte_data asc;'],fundo);
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
 
[ pl.data,  pl.pl] =  mysql(query);
  
mysql('close') 
%}

trades = [];
datas = unique(boletas.data);
for d=1:length(datas)
  datestr(datas(d))
  didx = boletas.data==datas(d);
  codigo = boletas.codigo(didx);
  serie = boletas.serie(didx);
  lote = boletas.lote(didx);
  preco = boletas.preco(didx);
  clear symbols
  for c=1:length(codigo)
    symbols{c} = strcat(codigo{c},serie{c});
  end
  sym = unique(symbols);
  for s=1:length(sym)
    sidx = strcmp(symbols,sym{s});
    sidx=sidx';
    trades(d).codigo{s} = sym{s}(1:3);
    trades(d).serie{s} = sym{s}(4:end);
    trades(d).symbol{s} = sym{s};
    trades(d).buyqty(s) = 0;
    trades(d).buypx(s) = 0;
    trades(d).sellqty(s) = 0;
    trades(d).sellpx(s) = 0;
    
    longidx = lote>0;
    if any(sidx & longidx)
      longpx = preco(sidx & longidx);
      longqty = lote(sidx & longidx);
      trades(d).buyqty(s) = sum(lote(sidx & longidx));
      trades(d).buypx(s) = sum(longpx.*longqty)/sum(longqty);
    end
    shortidx = lote<0;
    if any(sidx & shortidx)
      shortpx = preco(sidx & shortidx);
      shortqty = lote(sidx & shortidx);
      trades(d).sellqty(s) = sum(lote(sidx & shortidx));
      trades(d).sellpx(s) = sum(shortpx.*shortqty)/sum(shortqty);
    end
    trades(d).qty(s) = ...
      trades(d).buyqty(s) + trades(d).sellqty(s);
    trades(d).preco(s) = ...
     - trades(d).buypx(s) + trades(d).sellpx(s);
   
   fprintf('%s; c: %d,%2.10f ; v:%d,%2.10f\n',trades(d).symbol{s},...
     trades(d).buyqty(s),trades(d).buypx(s),...
     trades(d).sellqty(s),trades(d).sellpx(s))
  end
end