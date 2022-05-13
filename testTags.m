clear all
host = 'BDKPTL03';
tic
%select number of symbols
query = 'select max(i_id) from dbconfig.symbols;';
h = mysql( 'open', host,'traders', 'kapitalo' );
nsymbols = mysql(query);
mysql('close')
%select tags
query = 'select i_id,s_tag from dbconfig.tag order by i_id;';
h = mysql( 'open', host,'traders', 'kapitalo' );
[tagids,tags] = mysql(query);
mysql('close')
ntags=length(tagids);
snapshot = nan(nsymbols,ntags);
toc
tic
query = ['select t1.i_id,t2.i_id,t3.t_ts,t3.d_value ',...
  'from dbconfig.symbols t1,dbconfig.tag t2, dbmarketdata.snapshot t3 ',...
  'where t1.s_symbol=t3.p_symbol ',...
  'and t1.s_exchange=t3.p_exchange ',...
  'and t3.p_tag=t2.s_tag ',...
  'and t1.x_logtrades=1;'];
h = mysql( 'open', host,'traders', 'kapitalo' );
[symbolid,tagid,newts,value] = mysql(query);
mysql('close')
ts = max(newts);
toc
tic
for i=1:length(symbolid)
  lia = ismember(tagids,tagid(i));
  if ~isempty(lia)
    snapshot(symbolid(i),lia)=value(i);
  end
end
toc

maxdelay = 0;
mysql('close')
h = mysql( 'open', host,'traders', 'kapitalo' );
while 1
  ti = tic;
  ts=max(max(newts),ts);
  query = sprintf(['select t1.i_id,t2.i_id,t3.t_ts,t3.d_value ',...
  'from dbconfig.symbols t1,dbconfig.tag t2, dbmarketdata.snapshot t3 ',...
  'where t1.s_symbol=t3.p_symbol ',...
  'and t1.s_exchange=t3.p_exchange ',...
  'and t3.p_tag=t2.s_tag ',...
  'and t3.t_ts>=''%s'';'],datestr(ts,'yyyy-mm-dd hh:MM:ss'));
  [symbolid,tagid,newts,value] = mysql(query);
  for i=1:length(symbolid)
    lia = ismember(tagids,tagid(i));
    if ~isempty(lia)
      snapshot(symbolid(i),lia)=value(i);
    end
  end
  pause(0.001)
  maxdelay = max(maxdelay,toc(ti));
  fprintf('WINQ17: %2.2f, %i, %2.0f,%2.0f\n',snapshot(62281,9),snapshot(62281,44),maxdelay*1000,toc(ti)*1000)
end
