%{
clear all
lastdate = '2017-06-09';
te = tic;
query = sprintf(['SELECT data,fatorrisco,valor FROM dbkptl.ct_retornos ',...
  'where data<=''%s'' order by data;'],lastdate);
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[data,fatorrisco,valor] = mysql(query);
mysql('close')
factors = table(data,fatorrisco,valor);

[fName,fa,fc] = unique(factors.fatorrisco);
fId = containers.Map(fName,1:length(fName));
[t , ta, tc] = unique(factors.data);
n = size(t,1);
nf = size(fa,1);
r = sparse(max(t),nf); %factors returns
ridx = sparse(max(t),nf); %factors returns

for f=1:nf
  fidx = fc==f;
  if any(fidx)
    tempdata = factors.data(fidx);
    tempret = factors.valor(fidx);
    [mu,sig] = normfit(tempret(tempret~=0));
    tempsig = tempret./sig;
    outlieridx = tempsig>=20;
    if any(outlieridx)
      tempdata(outlieridx)=[];
      tempret(outlieridx)=[];
      %figure;bar(r(find(r(:,f)),f));title(fName(f));drawnow;
    end
    r(tempdata,f) = tempret;
    ridx(tempdata,f) = 1;
  end
end
fprintf('Factors loaded (%f)...\n',toc(te));
%}
%
fator = 'IBOV Index';
%fator = 'WTI Oil [01]';
ibovid = fId(fator);
ibovidx = ridx(:,ibovid);
alpha = zeros(nf,1);
beta = zeros(nf,1);
r2 = zeros(nf,1);
for f=1:nf
  idx = ridx(:,f) & ibovidx;
  x = r(idx,ibovid);
  y = r(idx,f);
  vidx = ~isnan(x) & ~isnan(y);
  if any(vidx)
    p = polyfit(x(vidx),y(vidx),1);
    alpha(f) = p(1);
    beta(f) = p(2);
    c = corrcoef(x(vidx),y(vidx));
    r2(f) = c(1,2)^2;
    %{
    fatorrisco = fName{f};
    [yfit] = polyval(p,x);
    figure(1);
    plot(x,y,'ko',x,yfit,'r');title(fatorrisco);
    drawnow
    query = sprintf(['INSERT IGNORE INTO dbkptl.alphabeta ',...
      '(fatorrisco,fator,alpha,beta,r2) VALUES ',...
      '(''%s'',''%s'',%f,%f,%f);'],fatorrisco,fator,p(2),p(1),r2);
    h = mysql( 'open', 'localhost','traders', 'kapitalo' );
    mysql(query);
    mysql('close')
    %}
  end
end
%}
%
te=tic;
fundo = 'KAPITALO ZETA MASTER FIM';
query = sprintf(['SELECT dte_data,dbl_plpactual ',...
  'FROM dbkptl.tbl_cotaspl ',...
  'where  str_fundo = ''%s'' ',...
  'and dte_data<=''%s'' ',...
  'order by dte_data;'],fundo,lastdate);
h = mysql( 'open', 'localhost','traders', 'kapitalo' );
[data,aum] = mysql(query);
mysql('close')
fund = table(data,aum);
aum = sparse(max(t),1); %net equity
aum(fund.data)=fund.aum;
fprintf('Fund loaded (%f)...\n',toc(te));

te=tic;
periods(1,1:3) = {'ALL';datenum('2010-01-01');datenum(lastdate)};
periods(2,1:3) = {'2010S1';datenum('2010-01-01');datenum('2010-07-01')};
periods(3,1:3) = {'2010S2';datenum('2010-07-01');datenum('2011-01-01')};
periods(4,1:3) = {'2011S1';datenum('2011-01-01');datenum('2011-07-01')};
periods(5,1:3) = {'2011S2';datenum('2011-07-01');datenum('2012-01-01')};
periods(6,1:3) = {'2012S1';datenum('2012-01-01');datenum('2012-07-01')};
periods(7,1:3) = {'2012S2';datenum('2012-07-01');datenum('2013-01-01')};
periods(8,1:3) = {'2013S1';datenum('2013-01-01');datenum('2013-07-01')};
periods(9,1:3) = {'2013S2';datenum('2013-07-01');datenum('2014-01-01')};
periods(10,1:3) = {'2014S1';datenum('2014-01-01');datenum('2014-07-01')};
periods(11,1:3) = {'2014S2';datenum('2014-07-01');datenum('2015-01-01')};
periods(12,1:3) = {'2015S1';datenum('2015-01-01');datenum('2015-07-01')};
periods(13,1:3) = {'2015S2';datenum('2015-07-01');datenum('2016-01-01')};
periods(14,1:3) = {'2016S1';datenum('2016-01-01');datenum('2016-07-01')};
periods(15,1:3) = {'2016S2';datenum('2016-07-01');datenum('2017-01-01')};
periods(16,1:3) = {'2017S1';datenum('2017-01-01');datenum(lastdate)};
  
mesas={'KAPITALO 1','KAPITALO 1.1','KAPITALO 1.2','KAPITALO 1.3', 'KAPITALO 1.4','KAPITALO 1.5',...
  'KAPITALO 3','KAPITALO 4','KAPITALO 5','KAPITALO 5.1','KAPITALO 7','KAPITALO 8','KAPITALO 9','KAPITALO 10'};
for m=1:length(mesas)
  mesa = mesas{m};
  %
  fprintf('loading mesa:%s\n',mesa);
  query = sprintf(['SELECT data,fatorrisco,valor ',...
    'FROM dbkptl.rt_relatorio ',...
    'where  fundo = ''%s'' ',...
    'and  mesa = ''%s'' ',...
    'and  estrategia = ''#N/D'' ',...
    'and  tipo = ''Exposure'' ',...
    'and data <= ''%s'' ',...
    'order by data;'],fundo,mesa,lastdate);
  h = mysql( 'open', 'localhost','traders', 'kapitalo' );
  [data,fatorrisco,valor] = mysql(query);
  mysql('close')
  exposure = table(data,fatorrisco,valor);
  fprintf('Mesa loaded (%f)...\n',toc(te));
  
  w = sparse(max(t),nf); %portifolio exposures
  pr = sparse(max(t),nf); %portifolio returns
  praccum = sparse(max(t),nf); %portifolio returns
  
  [ufactor, ufactora, ufactori] = unique(exposure.fatorrisco);
  for i=1:length(ufactor)
    fidx = strcmp(exposure.fatorrisco,ufactor{i});
    if isKey(fId,ufactor{i})
      factorid = fId(ufactor{i});
      w(exposure.data(fidx),factorid) =exposure.valor(fidx);
      if any(isnan(w(:,factorid))) || any(isinf(w(:,factorid)))
        disp('error');
      end
      w(aum==0,factorid)=0;
      w(aum~=0,factorid)= w(aum~=0,factorid)./aum(aum~=0);
      if any(isnan(w(:,factorid))) || any(isinf(w(:,factorid)))
        disp('error');
      end
      ids = find(ridx(:,factorid));
      pr(ids(2:end),factorid) = ...
        r(ids(2:end),factorid).*w(ids(1:end-1),factorid);
      praccum(:,factorid) = cumprod(1+pr(:,factorid))-1;
      
      securityselection = zeros(nf,1);
      factortiming = zeros(nf,1);
      riskpremia = zeros(nf,1);
  
      for p=1:size(periods,1)
        plott=periods{p,2}:periods{p,3};
        if any(w(plott,factorid))
          fprintf('Calc. mesa:%s, period:%s, factor:%s\n',mesa,periods{p,1},fName{factorid});
          ids = find(ridx(periods{p,2}:periods{p,3},factorid));
          ids = plott(ids);
          plott=ids;
          %shift 1
          active = cov(w(ids(1:end-1),factorid),r(ids(2:end),factorid));
          active = full(active(1,2))/0.0001;
          passive = ...
            mean(w(ids(1:end-1),factorid))*mean(r(ids(2:end),factorid));
          passive = full(passive)/0.0001;
          query = sprintf(['insert ignore into dbkptl.activepassive ',...
            '(shift,periodo,fundo,mesa,estrategia,tipo,fatorrisco,active,passive) ',...
            'values (1,''%s'',''%s'',''%s'',''#N/D'',''Exposure'',''%s'',%2.6f,%2.6f);'],...
          periods{p,1},fundo,mesa,ufactor{i},full(active),full(passive));
          connected=false;
          while (~connected)
            try
              h = mysql( 'open', 'localhost','traders', 'kapitalo' );
              connected=true;
            catch
              disp('err');
              pause(0.1);
            end
          end
          mysql(query);
          mysql('close');
          %shift 0
          active = cov(w(ids,factorid),r(ids,factorid));
          active = full(active(1,2))/0.0001;
          passive = mean(w(ids,factorid))*mean(r(ids,factorid));
          passive = full(passive)/0.0001;
          query = sprintf(['insert ignore into dbkptl.activepassive ',...
            '(shift,periodo,fundo,mesa,estrategia,tipo,fatorrisco,active,passive) ',...
            'values (0,''%s'',''%s'',''%s'',''#N/D'',''Exposure'',''%s'',%2.6f,%2.6f);'],...
          periods{p,1},fundo,mesa,ufactor{i},full(active),full(passive));
          connected=false;
          while (~connected)
            try
              h = mysql( 'open', 'localhost','traders', 'kapitalo' );
              connected=true;
            catch
              disp('err');
              pause(0.1);
            end
          end
          mysql(query);
          mysql('close');
          
          securityselection(factorid) = alpha(i)*mean(w(ids));
          temp = cov(w(ids(1:end-1),factorid),r(ids(2:end),ibovid));
          factortiming(factorid) = beta(factorid)*full(temp(1,2))/0.0001;
          riskpremia(factorid) =...
            beta(factorid)*mean(w(ids,factorid))*mean(r(ids,ibovid));
          
          %{
          figure(1);
          ax(1) = subplot(4,1,1);
          bar(plott,w(plott,factorid));
          title(sprintf('%s-%s',ufactor{i},periods{p,1}));
          datetick('x')
          ax(2) = subplot(4,1,2);
          plot(plott,cumprod((1+r(plott,factorid)))-1);
          title(sprintf('%s-%s',ufactor{i},periods{p,1}));
          datetick('x')
          ax(3) = subplot(4,1,3);
          bar(plott,10000.*pr(plott,factorid));
          title(sprintf('%s-%s',ufactor{i},periods{p,1}));
          datetick('x')
          ax(4) = subplot(4,1,4);
          plot(plott,10000.*praccum(plott,factorid));
          title(sprintf('%s-%s',ufactor{i},periods{p,1}));
          datetick('x')
          linkaxes(ax,'x');
          %}
        end
      end
      
    end
  end
  
end
fprintf('DONE!!!!!');
%}

%S = corrcoef(r,'rows','pairwise');
%[coeff1,score1,latent,tsquared,explained,mu1] = pca(r,'algorithm','als');
