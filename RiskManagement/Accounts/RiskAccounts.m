classdef RiskAccounts < handle
  
  properties
    Main
    Instance
    Strategies
    
    account
    simulated = 'true'
  end
  
  methods
    function this = RiskAccounts(Main,Instance)
      if nargin > 0
        this.Main = Main;
        this.Instance = Instance;
        this.account = this.Instance.Attributes.account;
        this.simulated = this.Instance.Attributes.simulated;
        
        this.Strategies = RiskStrategies.empty;
        fields = fieldnames(this.Instance);
        for f = 1:length(fields)
          if strcmp('riskstrategies',fields(f))
            init_strategies_count = size(this.Instance.riskstrategies,2);
            for s=1:init_strategies_count
              strategy = this.Instance.riskstrategies(s);
              if iscell(strategy)
                  strategy = cell2mat(strategy);
              end
              strategy.Attributes.account = this.account;
              strategy.Attributes.simulated = this.simulated;
              strategy.Attributes.db = this.Instance.Attributes.db;
              
              st=length(this.Strategies);
              this.Strategies(st+1) = RiskStrategies(this,strategy);
              ns = length(this.Main.Strategies);
              this.Main.Strategies(ns+1) = this.Strategies(st+1);
            end
          end
        end
      end
    end
  end
end