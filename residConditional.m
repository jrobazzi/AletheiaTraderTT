%
clear all
load('resid.mat')
period=1080;
perioddays = period/540;
annualf = 1/sqrt(perioddays/252);
annualf = 1;
fut = period*4*2;
past = period*4*30;
%5
zscore = nan(size(resid));
zscore(1:past) = resid(1:past)./std(resid(1:past));
for i=past+period+1:period:length(resid)
  zscore(i-period:i) = resid(i-period:i)./std(resid(i-past:i));
end
lstid = find(isnan(zscore),1);
if ~isempty(lstid)
  zscore(lstid:end) = resid(lstid:end)./std(resid(lstid-past:lstid));
end
resid = zscore;
%}
posidx= (resid>0);
posmax = max(resid(posidx));
nbins = 50;
posbinsize = posmax/nbins;
posbins = 0:posbinsize:posmax;
for i=1:length(posbins)-1
  binidx = resid>posbins(i) & resid<=posbins(i+1);
  binavg = (posbins(i)+posbins(i+1))/2;
  posprob(i) = sum(resid<=posbins(i+1))/length(resid);
  idxdiff = [0;diff(binidx)];
  idsend = find(idxdiff==-1);
  for j=1:length(idsend)
    endid = idsend(j)+fut;
    if endid>length(resid)
      endid = length(resid);
    end
    binidx(idsend(j):endid)=true;
  end
  nextvec = binavg-resid(binidx);
  [nextvec,~] = sort(nextvec);
  nvec = length(nextvec);
  fiveperc = round(nvec*0.05);
  posrisk(i) = nextvec(fiveperc);
  posexp(i) = mean(binavg-resid(binidx))*annualf;
  posstd(i) = std(binavg-resid(binidx))*annualf;
  %figure(10000);histfit(binavg-resid(binidx),4*nbins)
end
negidx= (resid<0);
negmax = min(resid(negidx));
negbinsize = negmax/nbins;
negbins = 0:negbinsize:negmax;
for i=1:length(negbins)-1
  binidx = resid<negbins(i) & resid>=negbins(i+1);
  binavg = (negbins(i)+negbins(i+1))/2;
  negprob(i) = sum(resid>=negbins(i+1))/length(resid);
  idxdiff = [0;diff(binidx)];
  idsend = find(idxdiff==-1);
  for j=1:length(idsend)
    endid = idsend(j)+fut;
    if endid>length(resid)
      endid = length(resid);
    end
    binidx(idsend(j):endid)=true;
  end
  
  nextvec = resid(binidx)-binavg;
  [nextvec,~] = sort(nextvec);
  nvec = length(nextvec);
  fiveperc = round(nvec*0.05);
  negrisk(i) = nextvec(fiveperc);
  negexp(i) = mean(resid(binidx)-binavg)*annualf;
  negstd(i) = std(resid(binidx)-binavg)*annualf;
end
%}
figure(100);cla;
[counts,centers] = hist(resid,50);
counts = counts./sum(counts);
counts = counts./max(counts);
bar(centers,counts.*max(max(negexp),max(posexp)))
hold on
plot(posbins(2:end),posexp,'r',negbins(2:end),negexp,'b','LineWidth',2)
hold off
xlabel('resid');ylabel('E[r_l_o_g | resid]');
figure(1000);cla;
[counts,centers] = hist(resid,50);
counts = counts./sum(counts);
counts = counts./max(counts);
bar(centers,counts.*max(max(negrisk),max(posrisk)))
hold on
plot(posbins(2:end),posrisk,'r',negbins(2:end),negrisk,'b','LineWidth',2)
hold off
xlabel('resid');ylabel('E[r_l_o_g | resid]');
figure(101);cla;
[counts,centers] = hist(resid,50);
counts = counts./sum(counts);
counts = counts./max(counts);
bar(centers,counts.*max(max(negstd),max(posstd)))
hold on
plot(posbins(2:end),negstd,'r',negbins(2:end),posstd,'b','LineWidth',2)
hold off
xlabel('resid');ylabel('std | resid');
figure(102)
plot(posstd,posexp,'rv',negstd,negexp,'b^')
xlabel('std | resid');ylabel('E[r_l_o_g | resid]');
figure(103)
plot(posprob,posexp./posstd,'r',...
  negprob,negexp./negstd,'b',...
  posprob,1./(posprob)-1,'k',...
  negprob,1./(negprob)-1,'k')
xlabel('profit prob | resid');ylabel('odds | resid');
figure(104)
posdelta = (posexp./posstd)-(1./(posprob)-1);
posdelta(posdelta<0) = 0;
posdelta = posdelta/max(posdelta);
negdelta = (negexp./negstd)-(1./(negprob)-1);
negdelta(negdelta<0) = 0;
negdelta = negdelta/max(negdelta);
plot(posprob,posdelta,'r',...
  negprob,negdelta,'b')
xlabel('profit prob | resid');ylabel('delta | resid');
figure(105);cla;
[counts,centers] = hist(resid,50);
counts = counts./sum(counts);
counts = counts./max(counts);

sigref = 4;spread=3;
inLong=-sigref; outLong=0; inLongExp = spread; outLongExp = 1/spread;
inShort=sigref; outShort=0; inShortExp = spread; outShortExp = 1/spread;

xLong = inLong:0.001:outLong; 
inLongRef = (1-(abs(xLong-inLong)./abs(outLong-inLong))).^inLongExp;
outLongRef = (1-(abs(xLong-inLong)./abs(outLong-inLong))).^outLongExp;

xShort = outShort:0.001:inShort; 
inShortRef = -((abs(xShort-outShort)./abs(inShort-outShort))).^inShortExp;
outShortRef = -((abs(xShort-outShort)./abs(inShort-outShort))).^outShortExp;
if ~isreal(inLongRef) || ~isreal(outLongRef) || ...
    ~isreal(inShortRef) ||~isreal(outShortRef) 
  disp('err');
end

bar(centers,counts.*max(max(posdelta),max(negdelta)))
hold on
plot(posbins(2:end),-posdelta,'k',...
  negbins(2:end),negdelta,'k','LineWidth',2)
plot(xLong,inLongRef,'b','LineWidth',2);
plot(xLong,outLongRef,'m','LineWidth',2);
plot(xShort,inShortRef,'r','LineWidth',2);
plot(xShort,outShortRef,'c','LineWidth',2);
hold off
xlabel('resid');ylabel('delta | resid');

figure(106)
autocorr(resid)
