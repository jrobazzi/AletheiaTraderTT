clc
dbfolder = 'C:\DB\';
source = 'RT';
tables = {'riskpositions','omstrades','omsreports','omsrequests'};
original = '235765\Trading_Moedas_Channel\';
replace = 'MASTERKPTL\Channel\';
for t=1:length(tables)
  currfolder = strcat(dbfolder,tables{t});
  currfolder = strcat(currfolder,'\');
  currfolder = strcat(currfolder,source);
  currfolder = strcat(currfolder,'\');
  tradedates = dir(currfolder);
  for td=3:length(tradedates)
    datefolder=strcat(currfolder,tradedates(td).name);
    datefolder=strcat(datefolder,'\');
    accounts = dir(datefolder);
    for a=3:length(accounts)
      accountfolder = strcat(datefolder,accounts(a).name);
      accountfolder = strcat(accountfolder,'\');
      strategies = dir(accountfolder);
      for s=3:length(strategies)
        strategyfolder = strcat(accountfolder,strategies(s).name);
        strategyfolder = strcat(strategyfolder,'\');
        k = strfind(strategyfolder,original);
        if ~isempty(k)
          newfolder = strrep(strategyfolder,original,replace)
          copyfile(strategyfolder,newfolder);
        end        
      end
    end
  end
end