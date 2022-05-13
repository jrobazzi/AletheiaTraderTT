clear all
host = 'BDKPTL03';
period = 300;
nbars = 100;
figure(1); grid on;
SID = 27238;
tic
%select number of symbols
query = 'select max(i_id) from dbconfig.symbols;';
h = mysql( 'open', host,'traders', 'kapitalo' );
nsymbols = mysql(query);
mysql('close')
intraday = cell(1,nsymbols);
toc
%initialize intraday
tic
query = sprintf(['select s.i_id,i.t_ts,i.p_time,i.d_open,i.d_close,',...
  'i.d_max,i.d_min,i.d_trades,i.d_volume,',...
  'i.d_avg,i.d_buyQty,i.d_buyAvg,i.d_sellQty,i.d_sellAvg ',...
  'from dbconfig.symbols s, dbmarketdata.intraday i ',...
  'where s.s_symbol=i.p_symbol ',...
  'and s.s_exchange=i.p_exchange ',...
  'and i.p_period=%i ',...
  'and i.p_tradedate>=''2017-06-01'' ',...
  'and s.x_logtrades=1 ',...
  'order by i.p_time;'],period);
h = mysql( 'open', host,'traders', 'kapitalo' );
[symbolid,newts,id(:,1),id(:,2),id(:,3),id(:,4),id(:,5),id(:,6),id(:,7),...
  id(:,8),id(:,9),id(:,10),id(:,11),id(:,12)] = mysql(query);
mysql('close')
ts = max(newts);
toc
tic
[C,IA,IC] = unique(symbolid);
for i=1:length(C)
  intraday{C(i)} = nan(nbars,12);
  ids = find(IC==i);
  if length(ids)>nbars
    ids = ids(end-nbars+1:end);
  end
  nids = length(ids);
  intraday{C(i)}(end-nids+1:end,:) = id(ids,:); 
end
toc
mysql('close')
h = mysql( 'open', host,'traders', 'kapitalo' );
while 1
  ti = tic;
  clear id;
  query = sprintf(['select s.i_id,i.t_ts,i.p_time,i.d_open,i.d_close,',...
  'i.d_max,i.d_min,i.d_trades,i.d_volume,',...
  'i.d_avg,i.d_buyQty,i.d_buyAvg,i.d_sellQty,i.d_sellAvg ',...
  'from dbconfig.symbols s, dbmarketdata.intraday i ',...
  'where s.s_symbol=i.p_symbol ',...
  'and s.s_exchange=i.p_exchange ',...
  'and i.p_period=%i ',...
  'and i.t_ts>=''%s'' ',...
  'and s.x_logtrades=1;'],period,datestr(ts,'yyyy-mm-dd hh:MM.ss'));
  [symbolid,newts,id(:,1),id(:,2),id(:,3),id(:,4),id(:,5),id(:,6),id(:,7),...
    id(:,8),id(:,9),id(:,10),id(:,11),id(:,12)] = mysql(query);
  ts = max(ts,max(newts));
  for i=1:length(symbolid)
    if isempty(intraday{symbolid(i)})
      intraday{symbolid(i)} = nan(nbars,12);
    end
    if intraday{symbolid(i)}(end,1) == id(i,1)
      intraday{symbolid(i)}(end,:) = id(i,:);
    elseif intraday{symbolid(i)}(end,1) < id(i,1)
      intraday{symbolid(i)}(1:end-1,:) = intraday{symbolid(i)}(2:end,:);
      intraday{symbolid(i)}(end,:) = id(i,:);
    end
  end
  pause(0.001);
  fprintf('DOLQ17: %2.0f\n',toc(ti)*1000)
  candle(intraday{SID}(:,4), intraday{SID}(:,5), ...
    intraday{SID}(:,3), intraday{SID}(:,2));
  drawnow;
end

