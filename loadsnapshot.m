clear all
te = tic;
dstart = datenum(2016,01,01);
dend = datenum(2017,02,06);

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
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

clear snapshot
figure(1)
cla
hold on
ntd = 0;
for t=round(dstart):round(dend)
  td = tic;
  
  query = sprintf(['SELECT %s FROM dbmarketdata.daily '...
    'WHERE s_market in (''DOL'') '...
    'AND p_exchange=''XBMF'''...
    'AND p_tradedate=''%s'';'],...
    str_query,datestr(t,'yyyy-mm-dd'));
  h = mysql( 'open', 'localhost','traders', 'kapitalo' );
  [result.t_ts,result.s_source,result.p_tradedate,result.p_exchange,result.p_symbol,result.s_market,result.s_contract,result.s_contractType,result.s_optionType,result.s_m2mType,result.s_lastM2mType,result.s_symbolVoice,result.s_channels,result.s_currency,result.t_strikeDate,result.t_lastTrade,result.t_liquidation,result.t_deliveryDate,result.t_time,result.d_open,result.d_max,result.d_min,result.d_close,result.d_closeQty,result.d_lastClose,result.d_last,result.d_avg,result.d_bestBid,result.d_bidQty,result.d_bestAsk,result.d_askQty,result.d_trades,result.d_contracts,result.d_openInterest,result.d_volumeBRL,result.d_volumeUSD,result.d_pointvalue,result.d_m2m,result.d_lastM2m,result.d_m2mReturn,result.d_m2mValue,result.d_dM2m,result.d_dM2mValue,result.d_strikeprice,result.d_exercBRL,result.d_exercUSD,result.d_exercTrades,result.d_exercContracts,result.d_delta,result.d_impVol,result.d_yieldDays,result.d_totalDays,result.d_busDays,result.d_margin,result.d_marginMM,result.d_futSeq,result.d_lowerLimit,result.d_upperLimit,result.d_tickSize] = mysql(query);
  mysql('close')
  
  
  if ~isempty(result.p_tradedate)
    ntd = ntd + 1;
    tradedates(ntd) = result;
    
    ffidx = tradedates(end).d_futSeq == 1;
    price = tradedates(end).d_m2m(ffidx);
    strikedate = tradedates(end).t_strikeDate(ffidx);
    sdidx = tradedates(end).t_strikeDate == strikedate;

    callidx = sdidx & strcmp(tradedates(end).s_optionType,'CE');
    putidx = sdidx & strcmp(tradedates(end).s_optionType,'VE');

    cstrikes = tradedates(end).d_strikeprice(callidx);
    cstrikedate = tradedates(end).d_yieldDays(callidx);
    cprice = tradedates(end).d_m2m(callidx);
    clear cvol pvol cgamma pgamma
    nc=0;
    for i=1:length(cstrikes)
      if cprice(i)==0.001
        cprice(i)=0;
      end
      cvol(i) = ...
        blsimpv(price, cstrikes(i), 0.1415,...
        cstrikedate(i)/252, cprice(i), [], 0, [], {'call'}); 
      if ~isnan(cvol(i))
      [cgamma(i)] = ...
        blsgamma(price, cstrikes(i), 0.1415,...
        cstrikedate(i)/252, cvol(i));
      else
        cgamma(i)=nan;
      end
    end

    pstrikes = tradedates(end).d_strikeprice(putidx);
    pstrikedate = tradedates(end).d_yieldDays(putidx);
    pprice = tradedates(end).d_m2m(putidx);

    for i=1:length(pstrikes)
      if pprice(i)==0.001
        pprice(i)=0;
      end
      pvol(i) = ...
        blsimpv(price, pstrikes(i), 0.1415,...
        pstrikedate(i)/252, pprice(i), [], 0, [], {'put'}); 
      if ~isnan(pvol(i))
      [pgamma(i)] = ...
        blsgamma(price, pstrikes(i), 0.1415,...
        pstrikedate(i)/252, pvol(i));
      else
        pgamma(i)=nan;
      end
    end
    figure(2)
    plot(cstrikes,cgamma,'b*');
    hold on
    plot(pstrikes,pgamma,'r*');
    hold off
    drawnow
  %}
  end
  toc(td)
end
toc(te)


