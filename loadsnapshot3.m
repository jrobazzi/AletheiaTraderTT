tic
%% CONFIG
exchangeList = '''XBMF'',''XBOV''';
marketsList = '''DAP'',''DI1'',''DDI'',''FRP'',''DOL'',''WDO'',''IND'',''WIN''';
tags = {'s_quoteType','d_pointValue','s_optionType','t_strikeDate','d_strikePrice','d_impVol','d_delta','d_openInterest','t_liquidation','d_lastM2m','s_contractType','t_lastTrade','d_yieldDays','s_sessionPhase','d_bidQty','d_bestBid','d_last','d_bestAsk','d_askQty','d_open','d_max','d_min','d_m2m','d_contracts','d_auctionPrice','d_auctionVolume','d_auctionImbalance','s_auctionSide','d_lowerLimit','d_upperLimit'};
tagsList = '''s_quoteType'',''d_pointValue'',''s_optionType'',''t_strikeDate'',''d_strikePrice'',''d_impVol'',''d_delta'',''d_openInterest'',''t_liquidation'',''d_lastM2m'',''s_contractType'',''t_lastTrade'',''d_yieldDays'',''s_sessionPhase'',''d_bidQty'',''d_bestBid'',''d_last'',''d_bestAsk'',''d_askQty'',''d_open'',''d_max'',''d_min'',''d_m2m'',''d_contracts'',''d_auctionPrice'',''d_auctionVolume'',''d_auctionImbalance'',''s_auctionSide'',''d_lowerLimit'',''d_upperLimit''';
dict = 't_ts,s_source,p_exchange,p_symbol,p_tag,s_market,t_time,d_value,s_value';
host = 'BDKPTL03';
desk = 'Kapitalo 5.1';
date = '2017-03-01';
bps = 499000;

%% INITIALIZE SNAPSHOT
if ~exist('ts','var')
  %get symbols list
  h = mysql( 'open', host,'traders', 'kapitalo' );
  query = sprintf(['select s_exchange,s_symbol,s_market from dbconfig.symbols '...
    'where s_exchange in (%s) and s_market in (%s) and s_contracttype IN (''FUT'',''SOPT'') and t_lastTrade>=''%s'';'],...
    exchangeList,marketsList,datestr(date,'yyyy-mm-dd'));
  [result.s_exchange,result.s_symbol,result.s_market] = mysql(query);
  mysql('close')
  symbolsList = '';
  nsymbols = length(result.s_exchange);
  for s=1:length(result.s_exchange)
    exch = cell2mat(result.s_exchange(s));
    symb = cell2mat(result.s_symbol(s));
    mkt = cell2mat(result.s_market(s));
    symbolsRow.(exch).(symb) = s;
    %symbolsName{s} = sprintf('%s|%s',exch,symb);
    symbolsName{s} = symb;
    symbolsList = strcat(symbolsList,sprintf('''%s'',',symb));
  end
  symbolsList(end)=[];
  
  %initialize snapshot
  snapshot = table(result.s_exchange,result.s_symbol,result.s_market,...
    'VariableNames',{'p_exchange','s_symbol','s_market'},...
    'RowNames',symbolsName);
  for t=1:length(tags)
    if tags{t}(1) == 'd' || tags{t}(1) == 't'
      snapshotTag = table(zeros(nsymbols,1),'VariableNames',tags(t));
    elseif tags{t}(1) == 's'
      snapshotTag = table(cell(nsymbols,1),'VariableNames',tags(t));
    end
    snapshot = [snapshot snapshotTag];
  end
  clear result
  ts = datenum(1970,01,01);
end
%% UPDATE SNAPSHOT
datestr(ts,'yyyy-mm-dd hh:MM:ss.fff')
query = sprintf(['SELECT * FROM dbmarketdata.snapshot '...
    'WHERE s_market in (%s) and s_contracttype IN (''FUT'',''SOPT'') and p_tag in (%s) and t_ts>''%s'';'],...
    marketsList,tagsList,datestr(ts,'yyyy-mm-dd hh:MM:ss.fff'));
h = mysql( 'open', host,'traders', 'kapitalo' );
[result.t_ts,result.s_source,result.p_exchange,result.p_symbol,result.p_tag,result.s_market,result.s_contractType,result.t_time,result.d_value,result.s_value] = ...
mysql(query);
mysql('close')
for i=1:length(result.t_ts)
  exch = cell2mat(result.p_exchange(i));
  symb = cell2mat(result.p_symbol(i));
  tag = cell2mat(result.p_tag(i));
  if any(strcmp(snapshot.Properties.RowNames,symb))
    if result.t_ts(i) > ts
      ts = result.t_ts(i);
    end
    if tag(1) == 'd'
      %snapshot.(exch).(symb).(tag) = result.d_value(i);
      snapshot{symb,tag} = result.d_value(i);
    elseif tag(1) == 's'
      snapshot{symb,tag} = result.s_value(i);
    elseif tag(1) == 't'
      snapshot{symb,tag} = result.t_time(i);
    end
  end
end

%% CHARTS

di1idx = strcmp(snapshot.s_market,'DI1') & ...
          strcmp(snapshot.s_contractType,'FUT') &...
          snapshot.d_last~=0 & snapshot.d_bestBid~=0 ...
          & snapshot.d_bestAsk~=0;
%snapshot.p_symbol(di1idx)
figure(100)
ax1 = subplot(4,1,[1:3]);
plot(snapshot.t_lastTrade(di1idx),snapshot.d_last(di1idx),'k*')
hold on
%plot(snapshot.t_lastTrade(di1idx),snapshot.d_m2m(di1idx),'k*')
plot(snapshot.t_lastTrade(di1idx),snapshot.d_bestAsk(di1idx),'rv')
plot(snapshot.t_lastTrade(di1idx),snapshot.d_bestBid(di1idx),'b^')
hold off
datetick('x')
ax2 = subplot(4,1,4);
bar(snapshot.t_lastTrade(di1idx),snapshot.d_contracts(di1idx));
datetick('x')
linkaxes([ax1 ax2],'x')
%{
doloptidx = strcmp(snapshot.s_market,'DOL') & ...
          strcmp(snapshot.s_contractType,'SOPT') & ...
          strcmp(snapshot.s_optionType,'VE') &...
          snapshot.d_delta>0.00 & snapshot.d_delta<1;
strikedate = snapshot.t_strikeDate(doloptidx);
strikeprice = snapshot.d_strikePrice(doloptidx);
delta = snapshot.d_delta(doloptidx);
impVol = snapshot.d_impVol(doloptidx);
figure(2)
sDates = unique(strikedate);
sStrikes = 2000:1:5000;
sDeltas = griddata(strikedate,strikeprice,delta,sDates,sStrikes);
contourf(sDates,sStrikes,sDeltas);
colormap gray
datetick('x')

figure(3)
sImpVol = griddata(strikedate,strikeprice,impVol,sDates,sStrikes);
%mesh(sDates,sStrikes,sImpVol);
contourf(sDates,sStrikes,sImpVol);
colormap gray
datetick('x')
%}


%}
loadboletaskptl
toc
