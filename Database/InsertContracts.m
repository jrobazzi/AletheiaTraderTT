clear all

tags.asset = 20:22;
tags.expiration = 54:61;
tags.creation = 38:45;
tags.symbol = 106:121;
tags.isin = 126:141;
tags.description = 179:193;
delimitter = ',';

contracts_folder = 'Z:\BMF\ContratosCadastradosDescompactados\';
contracts_files = dir(contracts_folder);
tic
for f = length(contracts_files):-1:3
    filename = contracts_files(f).name;
    filepath = strcat(contracts_folder,filename);
    fdatestr = filename(3:8);
    filedate = datenum(fdatestr,'yymmdd');
    fid = fopen(filepath,'r');
    
    symbolslist_qry = ['INSERT IGNORE INTO db.`symbols/list` '...
        '(asset,expiration,creation,symbol,isin,description) VALUES '];
    symbolsdate_qry = ['INSERT IGNORE INTO db.`symbols/tradedate` '...
                        '(tradedate,symbol) VALUES '];
    
    symbolsdate.tradedate = datestr(filedate,'yyyy-mm-dd');
    tline = fgetl(fid);
    while ischar(tline)
        symbolslist.asset = tline(tags.asset);
        symbolslist.expiration = datestr(datenum(tline(tags.expiration),'yyyymmdd'),'yyyy-mm-dd');
        symbolslist.creation = datestr(datenum(tline(tags.creation),'yyyymmdd'),'yyyy-mm-dd');
        symbolslist.symbol = tline(tags.symbol);
        symbolslist.isin = tline(tags.isin);
        symbolslist.description = tline(tags.description);
        
        value_str = joinvalues(symbolslist);
        disp(value_str);
        
        symbolslist_qry(end+1:end+length(value_str)) = value_str;
        symbolslist_qry(end+1) = ',';
        
        symbolsdate.symbol = tline(tags.symbol);
        
        value_str = joinvalues(symbolsdate);
        symbolsdate_qry(end+1:end+length(value_str)) = value_str;
        symbolsdate_qry(end+1) = ',';
        
        tline = fgetl(fid);
    end
    fclose(fid);
    
    symbolslist_qry(end) = ';';
    symbolsdate_qry(end) = ';';
    conn = mysql( 'open', 'localhost', 'traders', 'qazxc123' );
    mysql(symbolslist_qry)
    mysql(symbolsdate_qry)
    mysql(conn,'close');
end
toc
