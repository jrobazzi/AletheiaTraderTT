classdef RiskStrategies < handle
  
  properties
    Main
    Instance
    Account
    Positions
    
    strategy
  end
  
  methods
    function this = RiskStrategies(Account,Instance)
       if nargin > 0
        this.Main = Account.Main;
        this.Account = Account;
        this.Instance = Instance;
        this.strategy = this.Instance.Attributes.strategy;
        this.Positions = RiskPositions.empty;
        fields = fieldnames(this.Instance);
        for f = 1:length(fields)
          if strcmp('riskpositions',fields(f))
            init_positions_count = size(this.Instance.riskpositions,2);
            for s=1:init_positions_count
              position = this.Instance.riskpositions(s);
              if iscell(position)
                  position = cell2mat(position);
              end
              position.Attributes.account=this.Instance.Attributes.account;
              position.Attributes.simulated=...
                this.Instance.Attributes.simulated;
              position.Attributes.db = this.Instance.Attributes.db;
              position.Attributes.strategy = ...
                this.Instance.Attributes.strategy;
              %find symbol
              name = '';
              fnames = fieldnames(position.Attributes);
              for k=1:length(fnames)
                fname = fnames(k);
                if iscell(fname)
                  fname = cell2mat(fname);
                end
                if strcmp(fname,'serie')
                  name = strcat(position.Attributes.serie,'_');
                  name = strcat(name,position.Attributes.name);
                  break;
                elseif strcmp(fname,'symbol')
                  name = position.Attributes.symbol;
                  break;
                end
              end
              symbol = ExchangeSymbols.empty;
              for i=1:length(this.Main.Symbols)
                if strcmp(name,this.Main.Symbols(i).name)
                  symbol = this.Main.Symbols(i);
                  break;
                end
              end
              if ~isempty(symbol)
                npos=length(symbol.Positions)+1;
                position.Attributes.npos = npos;
                symbol.Positions(npos) = ...
                  RiskPositions(this.Account,this,symbol,position);
                p=length(this.Positions)+1;
                this.Positions(p) = symbol.Positions(npos);
                p=length(this.Main.Positions)+1;
                this.Main.Positions(p) = symbol.Positions(npos);
              end
            end
          end
        end
       end
    end
  end
  
end