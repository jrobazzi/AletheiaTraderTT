classdef CSnapshot < handle
  %CSNAPSHOT Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    host = 'BDKPTL03';
    snapshot,tagids,tags,tag,symbol,ts
  end
  
  methods
    function this = CSnapshot()
      %select number of symbols
      query = 'select max(i_id) from dbconfig.symbols;';
      h = mysql( 'open', this.host,'traders', 'kapitalo' );
      nsymbols = mysql(query);
      mysql('close')
      %select tags
      query = 'select i_id,s_tag from dbconfig.tag order by i_id;';
      h = mysql( 'open', this.host,'traders', 'kapitalo' );
      [this.tagids,this.tags] = mysql(query);
      mysql('close')
      ntags=length(this.tagids);
      this.snapshot = nan(nsymbols,ntags);
      for i=1:ntags
        this.tag.(this.tags{i}) = this.tagids(i);
      end
      this.Initialize();
    end
    
    function Initialize(this)
      query = ['select t1.i_id,t2.i_id,t3.t_ts,t3.d_value ',...
        'from dbconfig.symbols t1,dbconfig.tag t2, dbmarketdata.snapshot t3 ',...
        'where t1.s_symbol=t3.p_symbol ',...
        'and t1.s_exchange=t3.p_exchange ',...
        'and t3.p_tag=t2.s_tag ',...
        'and t1.x_logbestoffers=1;'];
      h = mysql( 'open', this.host,'traders', 'kapitalo' );
      [symbolid,tagid,newts,value] = mysql(query);
      this.ts = max(newts);
      for i=1:length(symbolid)
        lia = ismember(this.tagids,tagid(i));
        if ~isempty(lia)
          this.snapshot(symbolid(i),lia)=value(i);
        end
      end
    end
    
    function Update(this)
      query = sprintf(['select t1.i_id,t2.i_id,t3.t_ts,t3.d_value ',...
      'from dbconfig.symbols t1,dbconfig.tag t2, dbmarketdata.snapshot t3 ',...
      'where t1.s_symbol=t3.p_symbol ',...
      'and t1.s_exchange=t3.p_exchange ',...
      'and t3.p_tag=t2.s_tag ',...
      'and t3.t_ts>=''%s'';'],datestr(this.ts,'yyyy-mm-dd hh:MM:ss'));
      [symbolid,tagid,newts,value] = mysql(query);
      this.ts=max(max(newts),this.ts);
      for i=1:length(symbolid)
        lia = ismember(this.tagids,tagid(i));
        if ~isempty(lia)
          this.snapshot(symbolid(i),lia)=value(i);
        end
      end
    end
  end
  
end

