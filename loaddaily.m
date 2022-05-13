clear all
te = tic;
dstart = datenum(2013,01,01);
dend = datenum(2017,05,02);

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

ntd = 0;
query = sprintf(['SELECT %s FROM dbmarketdata.signals '...
  'WHERE p_exchange = ''XBMF'' '...
  'AND p_tradedate>=''%s'' '...
  'AND p_tradedate<=''%s'' '...
  'ORDER BY p_tradedate;'],...
  str_query,datestr(dstart,'yyyy-mm-dd'),datestr(dend,'yyyy-mm-dd'));
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[t_ts,s_source,p_tradedate,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,s_contractType,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater,d_position,d_buyQty,d_sellQty,d_buyAvg,d_sellAvg,d_points,d_result] = mysql(query);
mysql('close')
daily = table(p_tradedate,t_ts,s_source,p_exchange,p_symbol,p_signal,p_period,p_time,s_market,d_gamma,d_gammaDir,d_delta,d_capacity,d_rlog,d_slippage,d_cost,d_rlogAccum,d_gammaAccum,d_slippageAccum,d_costAccum,d_rlogNetAccum,d_rlogAccumMax,d_rlogUnderwater);
toc(te)
%}
[C,ia,ic] = unique(daily.p_tradedate);
daily = sortrows(daily,'p_tradedate');
markets = unique(daily.s_market);

tradedates = unique(daily.p_tradedate);
tradedates = sort(tradedates);
%dret.date = datestr(tradedates','yyyy/mm/dd');
dret.date = tradedates;

ns=1;
for m=1:length(markets)
  currmkt = markets{m};
  signals = unique(daily.p_signal);
  for s=1:length(signals)
    currsig = signals{s};
    name{ns} = strcat(currsig,currmkt);
    dret.(name{ns}) = zeros(size(tradedates));
    sigidx = strcmp(daily.s_market,currmkt) & strcmp(daily.p_signal,currsig);
    dret.(name{ns})(ic(sigidx)) = daily.d_rlog(sigidx);
    matrix.d_rlog(ic(sigidx),ns) = daily.d_rlog(sigidx);
    matrix.d_capacity(ic(sigidx),ns) = daily.d_capacity(sigidx);
    matrix.d_gammaAccum(ic(sigidx),ns) = daily.d_gammaAccum(sigidx);
    matrix.d_rlogUnderwater(ic(sigidx),ns) = daily.d_rlogUnderwater(sigidx);
    matrix.d_rlogAccumMax(ic(sigidx),ns) = daily.d_rlogAccumMax(sigidx);
    ns = ns+1;
  end
end
rettable = struct2table(dret);
%}
%
chidx = strcmp(daily.p_signal,'Trend_100') &...
       strcmp(daily.s_market,'DOL') ;
lfidx = strcmp(daily.p_signal,'ChannelGamma10TWAP') &...
       strcmp(daily.s_market,'DOL') ;
svidx = strcmp(daily.p_signal,'Rev_2') &...
       strcmp(daily.s_market,'DOL') ;
     
t = daily.p_tradedate(chidx)';
channel = (daily.d_rlog(chidx));
longfly = (daily.d_rlog(lfidx));
shortvol = (daily.d_rlog(svidx));

wchstep = 0.05;
wchannel = 0:wchstep:1-wchstep;
nw=length(wchannel);
maxi = 1;
maxj = 1;
maxsh=0;
figure(1)
cla
title('Channel/LongFly/ShortVol Efficient Frontier');
xlabel('Standard Deviation');ylabel('Avg Return');
hold on
for i=1:nw
  maxw = 1-wchannel(i);
  wstep = maxw/(nw-1);
  temp = 0:wstep:maxw;
  wlongfly(i,:) = 0:wstep:maxw;
  for j=1:nw
    wshortvol(i,j) = 1-wlongfly(i,j)-wchannel(i);
    pf(i,j,:) = channel.*wchannel(i) +...
                longfly.*wlongfly(i,j) +...
                shortvol.*wshortvol(i,j);
    cpf(i,j,:) = cumsum(pf(i,j,:));
    mu(i,j) = mean((pf(i,j,:)))*sqrt(252);
    sig(i,j) = std((pf(i,j,:)))*sqrt(252);
    %{
    m = mean(pf(i,j,:));
    semiidx = pf(i,j,:)<m;
    semiamp = pf(i,j,:);
    semiamp(semiidx) = semiamp(semiidx)*2;
    semisig(i,j) = (sum((semiamp-m).^2)/(length(semiamp)-1))^0.5;
    semisig(i,j) = semisig(i,j)*sqrt(252);
    sig(i,j) = semisig(i,j);
    %}
    sh(i,j) = (mu(i,j)/sig(i,j))*sqrt(252);
    if maxsh<sh(i,j)
      maxsh=sh(i,j);
      maxi = i;
      maxj = j;
    end
    plot(sig(i,j),mu(i,j),'k*');
  end
end
i=maxi;
j=maxj;
sigx = 0:0.01:max(max(sig));
P = polyfit([0,sig(i,j)],[0,mu(i,j)],1);
yfit = P(1)*sigx+P(2);
plot(sigx,yfit,'r')
hold off

figure(3)
cla
id = find(sh==max(max(sh)));
bestpfl = squeeze(cpf(maxi,maxj,:))*2;
[mmax,undw] = underwater(bestpfl);
bestp = channel.*wchannel(maxi) +...
        longfly.*wlongfly(maxi,maxj) +...
        shortvol.*wshortvol(maxi,maxj);
plot(t,bestpfl,t,mmax,...
  t,cumsum(channel),t,cumsum(longfly),t,cumsum(shortvol),t,cumsum(bestp));
title('Channel/LongFly Optimum');xlabel('Time');ylabel('Log Return');
datetick('x')
fprintf('S1:%2.4f,S2:%2.4f,S3:%2.4f',...
  wchannel(maxi),wlongfly(maxi,maxj),wshortvol(maxi,maxj));
%{
wchannel = 0:0.1:1;
wlongfly = 1-wchannel;
for i=1:length(wchannel)
  pf(i,:) = channel.*wchannel(i) + longfly.*wlongfly(i);
  cpf(i,:) = cumsum(pf(i,:));
  P = polyfit(t,cpf(i,:),1);
  yfit(i,:) = P(1)*t+P(2);
  mu(i) = mean((pf(i,:)))*sqrt(252);
  sig(i) = std((pf(i,:)))*sqrt(252);
  sh(i) = (mu(i)/sig(i))*sqrt(252)
end
figure(1)
plot(sig,mu,'k*');title('Channel/LongFly Efficient Frontier');xlabel('Standard Deviation');ylabel('Avg Return');
figure(2)
plot(wchannel,sh);title('Channel/LongFly vs Sharpe');xlabel('Channel Weight');ylabel('Sharpe');
figure(3)
id = find(sh==max(sh));
plot(t,yfit(id,:),t,cpf(id,:),t,cumsum(channel),t,cumsum(longfly));
title('Channel/LongFly Optimum');xlabel('Time');ylabel('Log Return');
datetick('x')
%}


%{
%writetable(rettable,'backtest.xlsb');
window = 126;
for t=window:length(matrix.d_rlog)
  sharpetime(t,:) = sharpe(cumsum(matrix.d_rlog(t-window+1:t,:)));
  corrmat = corrcoef(matrix.d_rlog(t-window+1:t,:));
  corrtime(t,:) = corrmat(:,1);
end
figure
plot(sharpetime(:,1))
figure
plot(matrix.d_capacity)
figure
plot(matrix.d_gammaAccum)
figure
plot(corrtime)
%}
%{
rlogAccumMax = matrix.d_rlogAccumMax(:,18);
nT2recovery = 0;
lastRecovery = 1;
for i=2:length(rlogAccumMax)
  if rlogAccumMax(i)>rlogAccumMax(i-1)
    nT2recovery = nT2recovery+1;
    t2recovery(nT2recovery) = i-lastRecovery;
    lastRecovery = i;
  end
end
nT2recovery = nT2recovery+1;
t2recovery(nT2recovery) = i-lastRecovery;
figure(100)
hist(t2recovery,50)
%}
%}