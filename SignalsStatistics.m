%
clear all
te = tic;
market='ALLMKT';
dstart = datenum(2004,01,01);
dend = datenum(2017,05,19);

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
query = sprintf(['SELECT COLUMN_NAME ',...
                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                  'AND TABLE_NAME = ''%s'';'],...
                  'dbmarketdata',...
                  'signals');
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
%
ntd = 0;

query = sprintf(['SELECT %s FROM dbmarketdata.signals '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND s_market =''DOL'' '...
  'AND (p_signal like ''Trend_100'' or '...
  'p_signal like ''ChannelGamma10TWAP'' or '...
  'p_signal like ''Rev_2'' or '...
  'p_signal like ''Rev_5'' or '...
  'p_signal like ''Trend_400'' or '...
  'p_signal like ''ChannelReversion'' or '...
  'p_signal like ''Convergence_1080_4_3'')  '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'';'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result] = mysql(query);
mysql('close')
dol = table(t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result);

query = sprintf(['SELECT %s FROM dbmarketdata.signals '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND s_market =''IND'' '...
  'AND (p_signal like ''Trend_100'' or '...
  'p_signal like ''Rev_2'' or '...
  'p_signal like ''Rev_5'' or '...
  'p_signal like ''Trend_400'' or '...
  'p_signal like ''ChannelReversion'' or '...
  'p_signal like ''Convergence_1080_4_3'')  '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'';'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result] = mysql(query);
mysql('close')
ind = table(t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result);
daily = [dol;ind];

%}
%{
query = sprintf(['SELECT %s FROM dbmarketdata.signals '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND s_market =''IND'' '...
  'AND (p_signal like ''Convergence_1080_4_3'' or '...
  'p_signal like ''Convergence_720_4_3'' or '...
  'p_signal like ''Convergence_1440_4_3'' or '...
  'p_signal like ''Convergence_540_4_3'' or '...
  'p_signal like ''Convergence_1080_3_3'' )  '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'';'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater] = mysql(query);
mysql('close')
daily = table(t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater);

toc(te)

%}
nSig = 0;signals = [];
[tradedates] = unique(daily.p_tradedate);
[sC,sIA,sIC] = unique(daily.p_signal);
[mC,mIA,mIC] = unique(daily.s_market);
for m=1:length(mC)
  currMkt = mC{m};
  currMktIdx = m == mIC;
  for s=1:length(sC)
    currSig = sC{s};
    currSigIdx = currMktIdx & s==sIC;
    if any(currSigIdx)
      nSig=nSig+1;
      signals.name{nSig} = sprintf('%s|%s',currMkt,currSig);
      signals.idx{nSig} = currSigIdx;
      str = strsplit(currSig,'_');
      period=0;stdref=0;spread=0;
      if length(str)>1
        if any(strfind(currSig,'Rev_')) || any(strfind(currSig,'Trend_'))
          period = str2double(str{2})*540;
        elseif strfind(currSig,'Convergence') 
          str = strsplit(currSig,'_');
          period = str2double(str{2});
          stdref = str2double(str{3});
          spread = str2double(str{4});
        end
      end
      signals.period(nSig) = period;
      signals.stdref(nSig) = stdref;
      signals.spread(nSig) = spread;
    end
  end
end

%
ntd = length(tradedates);
ld = max(tradedates);
signals.d_rlog = spalloc(ld,nSig,ntd*nSig);
signals.d_rlogAccum = spalloc(ld,nSig,ntd*nSig);
signals.d_rlogAccumMean = spalloc(ld,nSig,ntd*nSig);
signals.d_rlogAccumRisk = spalloc(ld,nSig,ntd*nSig);
signals.d_slippage = spalloc(ld,nSig,ntd*nSig);
signals.d_gamma = spalloc(ld,nSig,ntd*nSig);
signals.d_cost = spalloc(ld,nSig,ntd*nSig);
signals.d_mean = spalloc(ld,nSig,ntd*nSig);
signals.d_std = spalloc(ld,nSig,ntd*nSig);
signals.d_sharpe = spalloc(ld,nSig,ntd*nSig);
signals.d_positiveSharpeTime = spalloc(ld,nSig,ntd*nSig);
signals.d_bestPeriod = spalloc(ld,1,ntd);
signals.d_bestId = spalloc(ld,1,ntd);
signals.p_tradedates = spalloc(ld,1,ntd);
portifolio.d_rlog = spalloc(ld,1,ntd);
portifolio.d_rlogAccum = spalloc(ld,1,ntd);
portifolio.d_rlogAccumRisk = spalloc(ld,1,ntd);

for s=1:nSig
  idx = signals.idx{s};
  dates = daily.p_tradedate(idx);
  signals.p_tradedates(dates) = 1;
  vidx = idx & ~isnan(daily.d_rlog);
  if any(vidx)
    dates = daily.p_tradedate(vidx);
    signals.d_rlog(dates,s) = daily.d_rlog(vidx);
  end
  vidx = idx & ~isnan(daily.d_slippage);
  if any(vidx)
    dates = daily.p_tradedate(vidx);
    signals.d_slippage(dates,s) = daily.d_slippage(vidx);
  end
  vidx = idx & ~isnan(daily.d_cost);
  if any(vidx)
    dates = daily.p_tradedate(vidx);
    signals.d_cost(dates,s) = daily.d_cost(vidx);
  end
  vidx = idx & ~isnan(daily.d_gamma);
  if any(vidx)
    dates = daily.p_tradedate(vidx);
    signals.d_gamma(dates,s) = daily.d_gamma(vidx);
  end
end
ids = find(signals.p_tradedates);
signals.d_rlogAccum(ids,:) = ...
  cumsum(signals.d_rlog(ids,:))+cumsum(signals.d_cost(ids,:));
wdw = 10;
for i=wdw:length(ids)
  cid = ids(i);
  signals.d_rlogAccumMean(cid,:)=...
    sum(signals.d_rlogAccum(ids(i-wdw+1:i),:))/wdw;
  avgRet = mean(signals.d_rlog(ids(i-wdw+1:i),:));
  signals.d_mean(cid,:) = avgRet;
  stdRet = std(signals.d_rlog(ids(i-wdw+1:i),:));
  signals.d_std(cid,:) = stdRet;
  signals.d_sharpe(cid,:) = (avgRet./stdRet).*sqrt(252);
  signals.bestId(cid) = ...
    find(signals.d_sharpe(cid,:)==max(signals.d_sharpe(cid,:)),1,'first');
  if i==wdw
    portifolio.d_rlog(ids(i-wdw+1:i)) = signals.d_rlog(ids(i-wdw+1:i),signals.bestId(cid));
  else
    nanidx = isnan(signals.d_sharpe(ids(i-1),:));
    signals.d_sharpe(ids(i-1),nanidx)=-100;
    nanidx = isnan(signals.d_rlog(ids(i-1),:));
    signals.d_rlog(ids(i-1),nanidx)=0;
    %[~,sortidx] = sort(signals.d_sharpe(ids(i-1),:),'descend');
    %onidx = sortidx(1:20);
    %onidx = signals.d_rlogAccum(ids(i-1),:)>signals.d_rlogAccumMean(ids(i-1),:);
    %sharpeidx = signals.d_sharpe(ids(i-1),:)>0;
    %positiveidx = signals.d_rlogAccum(ids(i-1),:)>0;
    %onidx = sharpeidx & positiveidx;
    onidx = ones(size(signals.d_rlog(cid,:)));
    n = sum(onidx>0);
    onids = find(onidx);
    if any(onids)
      portifolio.d_rlog(cid) = sum(signals.d_rlog(cid,onids)./n);
    else
      portifolio.d_rlog(cid) = 0;
    end
    %figure(2000);plot(ids(1:i-1),signals.d_rlogAccum(ids(1:i-1),:));hold on;
    %plot(ids(1:i-1),signals.d_rlogAccumMean(ids(1:i-1),:));hold off;
    %drawnow;
  end
  try
    signals.d_bestPeriod(cid) = signals.period(signals.bestId(cid));
  catch
    disp('err');
  end
end
%}
%
maxrisk=-0.15;
signals.d_positiveSharpeTime(ids,:) = signals.d_sharpe(ids,:)>0;
for s=1:nSig
  [mmax,uw,uwTime,worstUw] = underwater(signals.d_rlogAccum(ids,s));
  figure(8)
  hist(uwTime,30);title('Underwater Days');
  figure(9)
  hist(worstUw,30);title('Worst Underwater');
  signals.maxunderwater(s) = min(uw);
  signals.d_positiveSharpeTime(ids,s) = ...
    signals.d_positiveSharpeTime(ids,s).*signals.d_sharpe(ids,s);
  signals.d_positiveSharpeTime(:,s) = ...
    cumsum(signals.d_positiveSharpeTime(:,s));
  signals.riskFactor(s) = abs(maxrisk)./abs(signals.maxunderwater(s));
end

portifolio.d_rlogAccum(ids) = cumsum(portifolio.d_rlog(ids));
[mmax,uw] = underwater(portifolio.d_rlogAccum(ids));
portifolio.maxunderwater = min(uw);
portifolio.riskFactor = abs(maxrisk)./abs(portifolio.maxunderwater);
portifolio.d_rlogAccumRisk(ids) = ...
  portifolio.d_rlogAccum(ids).*portifolio.riskFactor;

%
ids = find(signals.p_tradedates);
figure(1);cla;figure(2);cla;figure(3);cla;figure(4);cla;drawnow;
names = {};
nnames = 0;
for s=1:nSig
  %if signals.d_rlogAccum(ids(end),s)>0
    signals.d_rlogAccumRisk(ids,s) = ...
      signals.d_rlogAccum(ids,s)*signals.riskFactor(s);
    figure(1);ax1=subplot(1,4,1:3);hold on;
    stairs(ids,signals.d_rlogAccumRisk(ids,s));datetick('x')
    figure(2);hold on;stairs(ids,cumsum(signals.d_slippage(ids,s)));
    figure(3);hold on;stairs(ids,cumsum(abs(signals.d_gamma(ids,s))));
    onids = find(signals.d_sharpe(ids,s)>0);
    offids = find(signals.d_sharpe(ids,s)<0);
    figure(4);hold on;
    %stairs(ids(onids),signals.d_sharpe(ids(onids),s),'b');
    %stairs(ids(offids),signals.d_sharpe(ids(offids),s),'r');
    stairs(ids,signals.d_sharpe(ids,s));
    nnames = nnames +1;
    names{nnames} = strrep(signals.name{s},'_','');
  %end
end
figure(4);
xlabel('Time');ylabel('Sharpe');title('Sharpe x Time')
figure(1);
subplot(1,4,1:3); 
stairs(ids,portifolio.d_rlogAccumRisk(ids),'k','LineWidth',2);
xlabel('Time');ylabel('Log Ret');title('Log Ret x Time')
[C,IA,IC] = unique(signals.period);
for i=1:length(C)
  rw = find(IC==i);
  d_ret(i) = max(signals.d_rlogAccumRisk(ids(end),rw));
  if d_ret(i)<0
    d_ret(i)=0;
  end
end
figure(1)
ax2=subplot(1,4,4);hold on;
%plot(signals.period,signals.d_rlogAccumRisk(ids(end),:),'k*');
bar(C,d_ret);
xlabel('Period');ylabel('Log Ret');title('Log Ret x Period')
linkaxes([ax1 ax2],'y');
bids = signals.d_bestPeriod>0 & signals.d_bestPeriod<6000;
[counts,centers]=hist(signals.d_bestPeriod(bids),1000);
figure(5);bar(centers,counts/sum(counts));
xlabel('Period');ylabel('Frequency');title('Best Sharpe x Period')
figure(6);plot(std(signals.d_rlog(ids,:)),mean(signals.d_rlog(ids,:)).*sqrt(252),'k*');
xlabel('Std');ylabel('Mean');title('Mean  x Var')

figure(7);bar(1:nSig,signals.d_positiveSharpeTime(ids(end),:));
xlabel('Period');ylabel('Frequency');title('Positive Sharpe Time x Period')

toc(te)
%}

totalSharpe = (mean(signals.d_rlog(ids,:))./std(signals.d_rlog(ids,:))).*sqrt(252);
totalSharpe=totalSharpe';
maxuw = 100.*signals.maxunderwater';
period = signals.period';
sigStd = signals.stdref';
spread = signals.spread';
sigNames = signals.name';
annualRlog = mean(signals.d_rlog(ids,:))*252*100;
annualRlog = annualRlog';
tbl = table(sigNames,period,sigStd,spread,totalSharpe,annualRlog,maxuw,'RowNames',sigNames);
writetable(tbl,strcat(market,'Backtest.xlsx'))
