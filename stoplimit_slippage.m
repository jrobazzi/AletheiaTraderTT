
te = tic;
dstart = datenum(2016,07,01);
dend = datenum(2016,12,30);
dbname = 'dbaccounts';
tablename = 'omsreports';
account = 'MASTERKPTL';
strategy = 'Channel';
market = 'DOL';

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
query = sprintf(['SELECT COLUMN_NAME ',...
                  'FROM INFORMATION_SCHEMA.COLUMNS ',...
                  'WHERE TABLE_SCHEMA = ''%s'' ',...
                  'AND TABLE_NAME = ''%s'';'],...
                  dbname,tablename);
[ fields ] = mysql(query);
mysql('close') 
cols_count=0;
resultstr = '';
querystr = '';
%create dictionary
for f=1:length(fields)
  column = strsplit(cell2mat(fields(f)),'_');
  if size(column,2)>1
    if ~strcmp(column{1},'s')
      cols_count = cols_count +1;
      cols.(column{2:end}) = cols_count;
      dictionary{cols_count} = fields{f};
      columns{cols_count} = column{2:end};
      columns_type{cols_count} = column{1};
    end
    resultstr = strcat(resultstr,tablename);
    resultstr = strcat(resultstr,'.');
    resultstr = strcat(resultstr,column{2:end});
    if f<length(fields)
      resultstr = strcat(resultstr,',');
    end
    querystr = strcat(querystr,fields{f});
    if f<length(fields)
      querystr = strcat(querystr,',');
    end
  end
end

h = mysql( 'open', 'localhost','traders', 'kapitalo' );
query = sprintf(['select %s '...
                'from %s.%s ',...
                'where s_source=''RT'' ',...
                'and s_tradedate >= ''%s'' '...
                'and s_account=''%s'' '...
                'and s_strategy=''%s'' '...
                'and s_symbol like ''%s%%'' ;'],...
                querystr,dbname,tablename,...
                datestr(dstart,'yyyy-mm-dd'),...
                account,strategy,market);
              
[omsreports.source,omsreports.tradedate,omsreports.account,...
  omsreports.strategy,omsreports.symbol,omsreports.oms,...
  omsreports.id,omsreports.orderid,omsreports.requestid,...
  omsreports.clordid,omsreports.msgnum,omsreports.ordtype,...
  omsreports.timestamp,omsreports.tag,omsreports.time,...
  omsreports.price,omsreports.value]=mysql(query);
mysql('close') 
toc(te)
%}

triggeredids = find(omsreports.tag == 153);
for o=1:length(triggeredids)
  id = triggeredids(o);
  orderid = omsreports.orderid(id);
  creationid = find(omsreports.tag == 152 & omsreports.orderid == orderid);
  creationpx(o) = omsreports.price(creationid);
  creationqty(o) = omsreports.value(creationid);
  
  executionids = find((omsreports.tag == 156 | omsreports.tag == 157) &...
    omsreports.orderid == orderid);
  leavesqty = creationqty(o);
  execpx(o)=0;
  for e=1:length(executionids)
    eid = executionids(e);
    execqty = leavesqty-omsreports.value(eid);
    if execpx(o)==0
      execpx(o) = omsreports.price(eid);
    else
      if (creationqty(o)-omsreports.value(eid))~=0
      execpx(o) = (omsreports.price(eid)*execqty +...
        execpx(o)*(creationqty(o)-leavesqty))/...
        (creationqty(o)-omsreports.value(eid));
      else
        execpx(o)=0;
        break;
      end
    end
    leavesqty = omsreports.value(eid);
  end
end
eid = execpx~=0 ;
slippagepts = (execpx-creationpx).*sign(creationqty);
slippageloss = (execpx(eid)-creationpx(eid)).*creationqty(eid).*50;
sum(slippageloss)
figure
hist(slippagepts(eid))
figure
plot(cumsum(slippageloss))
