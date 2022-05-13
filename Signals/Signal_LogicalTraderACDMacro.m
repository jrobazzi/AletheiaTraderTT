function signal = Signal_LogicalTraderACDMacro(symbol,signal)
  if ~signal.init
    signal=InitSignal(symbol,signal);
    signal.init = true;
  end
  
end

function signal = InitSignal(symbol,signal)
  %INIT VARIABLES
  quotes = symbol.Main.quotes;
  n = symbol.n;
  signal = symbol.InitSignalVariables(signal);
  score = zeros(size(quotes.tradedates));
  cumScore = zeros(size(quotes.tradedates));
  %% TRADEDATES LOOP
  tdot = tic;
  for d=1:length(quotes.tradedates)
    if d>30
      cumScore(d) = sum(score(d-30:d));
    else
      cumScore(d) = sum(score(1:d));
    end
    fb=quotes.firstbar(d);
    ob=quotes.openbar(n,d);
    lb=quotes.lastbar(n,d);
    openingbars=80;
    finalchannelid = ob+openingbars;
    channelup=max(quotes.max(n,ob:finalchannelid));
    channeldn=min(quotes.min(n,ob:finalchannelid));
    channel = channelup-channeldn;
    Aup = 0;AupON = 0;Adn = 0;AdnON = 0;Ashift=channel/2;
    Cup = 0;CupON = 0;Cdn = 0;CdnON = 0;Cshift=channel;
    close = 0;
    
    
    %figure(1)
    %plot(quotes.close(n,ob:lb));
    
    %% INTRADAY LOOP
    for t=finalchannelid:lb
      %---------------------------FILTER-------------------------------
      lstp = quotes.close(n,t);
      if lstp>channelup+Ashift && ~AupON
        AupON = t;
      end
      if lstp<channeldn-Ashift && ~AdnON
        AdnON = t;
      end
      if lstp>channelup+Cshift && ~CupON
        CupON = t;
      end
      if lstp<channeldn-Cshift && ~CdnON
        CdnON = t;
      end
      %-----------------------------------------------------------------
    end
    if quotes.close(n,lb) > channelup
      close = 1;
    elseif quotes.close(n,lb) < channeldn
      close = -1;
    end
    if AupON==0
      Aup=0;
    elseif t-AupON>openingbars/2
      Aup=1;
    elseif AupON~=lb
      Aup=-1;
    end
    if AdnON==0
      Adn=0;
    elseif t-AdnON>openingbars/2
      Adn=1;
    elseif AdnON~=lb
      Adn=-1;
    end
    if CupON==0
      Cup=0;
    elseif t-CupON>openingbars/2
      Cup=1;
    elseif CupON~=lb
      Cup=-1;
    end
    if CdnON==0
      Cdn=0;
    elseif t-CdnON>openingbars/2
      Cdn=1;
    elseif CdnON~=lb
      Cdn=-1;
    end
    if Aup==1 && Adn==0 && Cup==1 && Cdn==0 && close==1
      score(d) = 2; %LOGICAL TRADER FIG 4.1
    elseif Aup==0 && Adn==1 && Cup==0 && Cdn==1 && close==-1
      score(d) = -2; %LOGICAL TRADER FIG 4.2
    elseif Aup==1 && Adn==0 && Cup==0 && Cdn==0 && close==1
      score(d) = 2; %LOGICAL TRADER FIG 4.5
    elseif Aup==0 && Adn==1 && Cup==0 && Cdn==0 && close==-1
      score(d) = -2; %LOGICAL TRADER FIG 4.6
    elseif Aup==1 && Adn==1 && Cup==1 && Cdn==0 && close==1
      score(d) = 4; %LOGICAL TRADER FIG 4.7
    elseif Aup==1 && Adn==1 && Cup==0 && Cdn==1 && close==-1
      score(d) = -4; %LOGICAL TRADER FIG 4.8
    elseif Aup==1 && Adn==1 && Cup==1 && Cdn==0 && close==1
      score(d) = 4; %LOGICAL TRADER FIG 4.9
    elseif Aup==1 && Adn==1 && Cup==0 && Cdn==1 && close==-1
      score(d) = -4; %LOGICAL TRADER FIG 4.10
    elseif Aup==1 && Adn==1 && Cup==0 && Cdn==-1 && close==0
      score(d) = 3; %LOGICAL TRADER FIG 4.15  
    elseif Aup==1 && Adn==1 && Cup==-1 && Cdn==0 && close==0
      score(d) = -3; %LOGICAL TRADER FIG 4.16 
    elseif Aup==-1 && Adn==1 && Cup==0 && Cdn==1 && close==-1
      score(d) = -3; %LOGICAL TRADER FIG 4.17
    elseif Aup==1 && Adn==-1 && Cup==1 && Cdn==0 && close==1
      score(d) = 3; %LOGICAL TRADER FIG 4.18
    elseif Aup==-1 && Adn==1 && Cup==0 && Cdn==0 && close==0
      score(d) = -1; %LOGICAL TRADER FIG 4.19
    elseif Aup==1 && Adn==-1 && Cup==0 && Cdn==0 && close==1
      score(d) = 1; %LOGICAL TRADER FIG 4.20
    elseif Aup==-1 && Adn==0 && Cup==0 && Cdn==0 && close==-1
      score(d) = -1; %LOGICAL TRADER FIG 4.21
    elseif Aup==0 && Adn==-1 && Cup==0 && Cdn==0 && close==1
      score(d) = 1; %LOGICAL TRADER FIG 4.22
    elseif Aup==1 && Adn==1 && Cup==0 && Cdn==-1 && close==1
      score(d) = 2; %LOGICAL TRADER FIG 4.25
    elseif Aup==1 && Adn==1 && Cup==-1 && Cdn==0 && close==-1
      score(d) = -2; %LOGICAL TRADER FIG 4.26
    end
    
  end
  signal.lastbar = lb;
  fbs = quotes.firstbar;
  lbs = quotes.lastbar(n,:);
  signal.dret = exp(signal.rlogaccum(lbs)-signal.rlogaccum(fbs))-1;
  signal.dretunderwater = exp(signal.rlogunderwater(lbs))-1;
  signal.sharpe = sharpe(exp(signal.rlogaccum)-1,0);
  signal.maxdrawdown = min(exp(signal.rlogunderwater)-1);
  symbol.filters.ACDscore = cumScore;
  ret = quotes.close(quotes.lastbar)./quotes.close(quotes.lastbar(1)) -1;
  scale = cumScore(end)/ret(end);
  figure(1)
  %bar(score)
  plot(cumScore)
  hold on
  plot(scale.*ret)
  hold off
end

