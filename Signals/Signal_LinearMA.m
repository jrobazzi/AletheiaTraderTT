function signal = Signal_LinearMA(symbol,signal)

quotes = symbol.Main.quotes;
n = symbol.n;
fb=quotes.firstbar(end);
ob=quotes.openbar(n,end);
lb=quotes.lastbar(n,end);
newline = char(10);
filters = symbol.filters;

tauMA = [360 450 540 690 720 1080 1200];
ts=15;
taureversion = 1-exp(-(ts)./(tauMA.*60));
%taureversion = 0.02;
ndays = size(quotes.tradedates,2);
t=0;
if ob>0
    if ~signal.init
        %signal=InitSignal(symbol,signal);
        InitSignal();
        signal.init = true;
    end
    
    if fb~=0 && ob~=0 && lb~=0
        nquotes = size(quotes.time,2);
        nsig = size(signal.gamma,2);
        if nsig<nquotes
            signal = NewTradedateSignalVariables(symbol,signal);
            display([newline, 'new data points symbol = ', num2str(n), ' points = ', num2str(nquotes-nsig)])
        end
        %-----------------------------FILTER INIT-------------------------------
        nfilt = size(filters.reversionavgpx,1);
        % se ha novos dados no signal incializa espaco nos filtros com zeros
        if nfilt<nquotes
            display([newline,'new filter points symbol = ', num2str(n), ...
                ' quotes = ', num2str(nquotes), ...
                ' filters = ', num2str(nfilt)])
            sizediff = nquotes-nfilt;
            filters.reversionavgpx(end+1:end+sizediff) = zeros(1,sizediff);
            filters.reversionupprpx(end+1:end+sizediff) = zeros(1,sizediff);
            filters.reversionlowrpx(end+1:end+sizediff) = zeros(1,sizediff);
            filters.resid(end+1:end+sizediff,:) = ...
                zeros(sizediff,size(filters.resid,2));
            filters.avg(end+1:end+sizediff,:) = ...
                zeros(sizediff,size(filters.avg,2));
        end
        % se eh dia de rolagem e eh serie calcula pontos de rolagem
        currdate = quotes.tradedates(end);
        
        rollpoints = 0;
        calc_rollpoints();
        
        %-----------------------------------------------------------------------
        %display([newline,'novas barras Filters = ', num2str(signal.lastbar +1) , ...
        %    ' to ', num2str(lb) ])
        last_hist_sig = symbol.filters.sig(end,end);
        %-----------------------------FILTER---------------------------------
        % calcula filtros para todas as barras
        
        intraday_loop(signal.lastbar+1); % ponto inicial do loop é diferente no historico
        
        %----------------------------------------------------------------------
        if (~signal.lastbar == lb) 
            signal.lastbar = t;
        end
        symbol.filters.avg = filters.avg;
        symbol.filters.resid = filters.resid;
        symbol.filters.reversionupprpx = filters.reversionupprpx;
        symbol.filters.reversionlowrpx = filters.reversionlowrpx;
        symbol.filters.reversionavgpx = filters.reversionavgpx;
    end
end

    function InitSignal()
        %INIT VARIABLES
        %quotes = symbol.Main.quotes;
        %n = symbol.n;
        signal = symbol.InitSignalVariables(signal);
        %tauMA = [20 60 120 270 540 720 1080 1440 1620 1800 2160];
        bandDays = 30;
        %ts = 15;
        nfreq = length(tauMA);
        %taureversion = 1-exp(-(2*pi*ts^2)./(tauMA.*3600));
        %taureversion = 0.02;
        sigreversion = ones(ndays,1)*0.007;
        %reversionupprpx = zeros(size(quotes.rlog(n,:)));
        filters.reversionupprpx = zeros(size(quotes.rlog(n,:)));
        %reversionlowrpx = zeros(size(quotes.rlog(n,:)));
        filters.reversionlowrpx = zeros(size(quotes.rlog(n,:)));
        %reversionavgpx = zeros(size(quotes.rlog(n,:),2),nfreq);
        filters.avg = zeros(size(quotes.rlog(n,:),2),nfreq);
        %reversionresid = zeros(size(quotes.rlog(n,:),2),nfreq);
        filters.resid = zeros(size(quotes.rlog(n,:),2),nfreq);
        reversionresidUp = zeros(ndays,nfreq);
        reversionresidDn = zeros(ndays,nfreq);
        filters.reversionupprpx(1) = quotes.close(n,1)*exp(sigreversion(1));
        filters.reversionlowrpx(1) = quotes.close(n,1)*exp(-sigreversion(1));
        filters.avg(1,:) = quotes.close(n,1);
        sig = zeros(ndays,nfreq);
        filters.reversionavgpx = zeros(size(quotes.rlog(n,:),2),1);
        %% TRADEDATES LOOP
        tdot = tic;
        for d=1:ndays
            fb=quotes.firstbar(d);
            ob=quotes.openbar(n,d);
            lb=quotes.lastbar(n,d);
            if fb~=0 && ob~=0 && lb~=0
                %remove roll return
                currdate = quotes.tradedates(d);
                
                rollpoints = 0;
                calc_rollpoints();
                %
                if d>1
                    h = 1/2;
                    %figure(100);cla;
                    for m = 1:nfreq
                        lfb = fb-(tauMA(m)*4*30);
                        if lfb<1
                            lfb=1;
                        end
                        sig(d,m) = std(filters.resid(lfb:fb-1,m));
                        if m==1
                            %figure(1000+m);histfit(symbol.filters.resid(lfb:fb-1,m));
                            %xlabel('Residual');ylabel('Frequency');title('PDF');
                        end
                        a(m) = sig(d,m)/(tauMA(m)^h);
                        %figure(100);hold on; loglog(log(tauMA),log(a(m).*(tauMA.^h)));
                    end
                    %figure(100);hold on;
                    %xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
                    %loglog(log(tauMA),log(sig(d,:)),'k*');
                    %loglog(log(tauMA),log(mean(a).*(tauMA.^h)),'k','LineWidth',1.5');
                    %hold off;
                    %drawnow;
                end
                %}
                if toc(tdot)>1
                    tdot=tic;
                    fprintf('.');
                end
                if d>bandDays+1
                    bandinit = quotes.openbar(n,d-bandDays);
                    if d>1
                        reversionresidUp(d,:) = max(filters.resid(bandinit:t,:));
                        reversionresidDn(d,:) = min(filters.resid(bandinit:t,:));
                    else
                        reversionresidUp(1,:) = 0.01;
                        reversionresidDn(1,:) = -0.01;
                    end
                else
                    t=signal.lastbar;
                    bandinit = quotes.openbar(n,1);
                    reversionresidUp(d,:) = max(filters.resid(1:t,:));
                    reversionresidDn(d,:) = min(filters.resid(1:t,:));
                end
                %% INTRADAY LOOP
                last_hist_sig = sig(d,end);
                    %---------------------------FILTER-------------------------------
                    
                    intraday_loop(signal.lastbar);
                    
                    %-----------------------------------------------------------------
                signal.lastbar = lb;
            end
        end
        if d>1
            h = 1/1.7;
            figure(100);cla;
            for m = 1:nfreq
                lfb = fb-(tauMA(m)*4*30);
                if lfb<1
                    lfb=1;
                end
                sig(d,m) = std(filters.resid(lfb:fb-1,m));
                if m==1
                    figure(1000+m);histfit(filters.resid(lfb:fb-1,m));
                    xlabel('Residual');ylabel('Frequency');title('PDF');
                end
                a = sig(d,m)/(tauMA(m)^h);
                figure(100);hold on; loglog(tauMA,a.*(tauMA.^h));
            end
            figure(100);hold on;
            xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
            loglog(tauMA,sig(d,:),'k*');
            hold off;
            drawnow;
        end
        %{
  if d>1
    h = 1/1.7;
    %figure(100);cla;
    for m = 1:nfreq
      lfb = fb-(tauMA(m)*4*30);
      if lfb<1
        lfb=1;
      end
      sigPeriod(m) = std(symbol.filters.resid(1:signal.lastbar,m));
      if m==1
      figure(1000+m);histfit(symbol.filters.resid(1:signal.lastbar,m));
      xlabel('Residual');ylabel('Frequency');title('PDF');
      end
      a = sigPeriod(m)/(tauMA(m)^h);
      figure(100);hold on; plot(tauMA,a.*(tauMA.^h));
    end
    figure(100);hold on;
    xlabel('Period');ylabel('Std Dev');title('Std Dev x Period');
    plot(tauMA,sigPeriod(:),'k*');
    hold off;
    drawnow;
  end
        %}
        figure(500)
        plot(reversionresidUp(1:end,end));hold on
        plot(reversionresidDn(1:end,end));hold off
        figure(501)
        hist(reversionresidUp(1:end,end),30);hold on
        hist(reversionresidDn(1:end,end),30);hold off
        figure(502)
        %ntd = length(quotes.tradedates);
        plot(1:ndays,sig(1:ndays,:));
        xlabel('Days');ylabel('Std Dev');title('Std Dev x Days');
        drawnow;
        %}
        fbs = quotes.firstbar;
        lbs = quotes.lastbar(n,:);
        signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
        signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
        signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
        signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
        %FILTERS
        %symbol.filters.reversionavg = reversionavg;
        symbol.filters.tau = tauMA;
        symbol.filters.sig = sig;
        symbol.filters.avg = filters.avg;
        symbol.filters.resid = filters.resid;
        symbol.filters.residUp = reversionresidUp;
        symbol.filters.residDn = reversionresidDn;
        symbol.filters.sigreversion = sigreversion;
        symbol.filters.reversionupprpx = filters.reversionupprpx;
        symbol.filters.reversionlowrpx = filters.reversionlowrpx;
        symbol.filters.reversionavgpx = filters.reversionavgpx;
    end

    function intraday_loop(loop_start)
        
        for t=loop_start:lb
            if t==ob
                filters.avg(t,:) = rollpoints+...
                    filters.avg(t-1,:).*(1-taureversion)+...
                    quotes.close(n,t).*(taureversion);
                filters.reversionavgpx(t) = filters.avg(t,end);
            elseif quotes.volume(n,t)~=0
                filters.avg(t,:) = ...
                    filters.avg(t-1,:).*(1-taureversion)+...
                    quotes.close(n,t).*(taureversion);
                filters.reversionavgpx(t) = filters.avg(t,end);
            else
                filters.avg(t,:) = filters.avg(t-1,:);
                filters.reversionavgpx(t) = filters.reversionavgpx(t-1);
            end
            filters.reversionupprpx(t) = ...
                filters.avg(t,end)*(1+4*last_hist_sig);
            filters.reversionlowrpx(t) = ...
                filters.avg(t,end)*(1-4*last_hist_sig);
            avgp=filters.avg(t,:);
            filters.resid(t,:) = ...
                (quotes.close(n,t)-avgp)./avgp;
        end
    end

    function calc_rollpoints()
        
        if symbol.isserie
            currdateidx = currdate == symbol.seriedates;
            if any(currdateidx)
                if symbol.serieroll(currdateidx)
                    if ob>1
                        rollpoints = quotes.close(n,ob)-quotes.close(n,ob-1);
                    else
                        rollpoints = 0;
                    end
                end
            end
        end
        
    end

end


