%
clear all
te = tic;
dstart = datenum(2012,01,01);
dend = datenum(2017,04,24);

h = mysql( 'open', 'BDKPTL03','traders', 'kapitalo' );
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

ntd = 0;
query = sprintf(['SELECT %s FROM dbmarketdata.signals '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'' '...
  'ORDER BY p_tradedate;'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'BDKPTL03','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result] = mysql(query);
mysql('close')
daily = table(p_tradedate,t_ts,s_source,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater);
toc(te)
%}


nSig = 0;signals = [];
[tradedates] = unique(p_tradedate);
[sC,sIA,sIC] = unique(p_signal);
[mC,mIA,mIC] = unique(s_market);
for m=1:length(mC)
  currMkt = mC{m};
  if strcmp(currMkt,'IND')
    currMktIdx = m == mIC;
    for s=1:length(sC)
      currSig = sC{s};
      if strfind(currSig,'Convergence_')
        str = strsplit(currSig,'_');
        %if str2double(str{4})==3
          nSig=nSig+1;
          signals.period(nSig) = str2double(str{2});
          %signals.std(nSig) = str2double(str{3});
          %signals.spread(nSig) = str2double(str{4});
          signals.number.(currSig) = nSig;
          signals.names{nSig} = currSig;
          currSigIdx = currMktIdx & s==sIC;
          signals.idx{nSig} = currSigIdx;
        %end
      end
    end
  end
end

ntd = length(tradedates);
signals.d_rlog = spalloc(ntd,nSig,ntd*nSig);
signals.d_slippage = spalloc(ntd,nSig,ntd*nSig);
signals.d_gamma = spalloc(ntd,nSig,ntd*nSig);
signals.d_cost = spalloc(ntd,nSig,ntd*nSig);
signals.d_sharpe = spalloc(ntd,nSig,ntd*nSig);
signals.d_best = spalloc(ntd,1,ntd);
for s=1:nSig
  idx = signals.idx{s};
  dates = p_tradedate(idx);
  signals.d_rlog(dates,s) = d_rlog(idx);
  signals.d_slippage(dates,s) = d_slippage(idx);
  signals.d_cost(dates,s) = d_cost(idx);
  signals.d_gamma(dates,s) = d_gamma(idx);
end
ids = find(signals.d_rlog(:,1));
wdw = 126;
for i=wdw:length(ids)
  cid = ids(i);
  avgRet = mean(signals.d_rlog(ids(i-wdw+1:i),:));
  stdRet = std(signals.d_rlog(ids(i-wdw+1:i),:));
  signals.d_sharpe(cid,:) = (avgRet./stdRet).*sqrt(252);
  bestid = find(signals.d_sharpe(cid,:)==max(signals.d_sharpe(cid,:)),1,'first');
  signals.d_best(cid) = signals.period(bestid);
  %signals.d_best(cid) = bestid;
end
for s=1:nSig
  [mmax,uw] = underwater(signals.d_rlog(ids,s));
  signals.maxunderwater(s) = min(uw);
end

figure(1);plot(ids,cumsum(signals.d_rlog(ids,:)));
figure(2);plot(ids,cumsum(signals.d_slippage(ids,:)));
figure(3);plot(ids,cumsum(abs(signals.d_gamma(ids,:))));
figure(4);plot(ids,signals.d_sharpe(ids,:));
bids = find(signals.d_best);
[counts,centers]=hist(signals.d_best(bids),100);
figure(5);bar(centers,counts)