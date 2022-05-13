classdef FileIO <  handle
  %FileIO Class holds output files write access permitions
  properties
    Main
    Instance
    isinput = false;
    isoutput = false;

    keys
    folder_path
    file_path
    file_handle
    dict_file_path

    fields
    dictionary
    cols
    columns
    columns_type
    cols_count
    tags
    tagid
    tags_count

    byte_count=0
    lastrow_count=0
    row_count=0
    new_row_count=0
    tablefile
    
    buffer = []
    lastid = 0
  end
    
  methods
    function this = FileIO(Main,instance)
      if nargin > 1
        this.Main = Main;
        this.Instance = instance;
        this.keys = instance.Attributes;
        this.cols_count = 0;
        this.row_count = 0;
        if this.Main.charting
          instance.Attributes.IO = 'input';
        end
        if strcmp(instance.Attributes.IO,'input')
          this.isinput = true;
          this.Main.AddInputs(this);
        elseif strcmp(instance.Attributes.IO,'output')
          this.isoutput = true;
          this.Main.AddOutputs(this);
        end
        %initialize fields
        this.InitFields();
        this.InitTags();
      end
    end
    %file initialization functions
    function InitFields(this)
      h = mysql( 'open', this.Main.db.dbconfig.host, ...
              this.Main.db.dbconfig.user, this.Main.db.dbconfig.password );
      query = sprintf(['SELECT COLUMN_NAME ',...
                        'FROM INFORMATION_SCHEMA.COLUMNS ',...
                        'WHERE TABLE_SCHEMA = ''%s'' ',...
                        'AND TABLE_NAME = ''%s'' ORDER BY ORDINAL_POSITION ASC;'],...
                        this.keys.db,...
                        this.keys.table);
      [ this.fields ] = mysql(query);
      mysql('close') 
      %create dictionary
      for f=1:length(this.fields)
        column = strsplit(cell2mat(this.fields(f)),'_');
        if size(column,2)>1
          if ~strcmp(column{1},'s')
            this.cols_count = this.cols_count +1;
            this.cols.(column{2:end}) = this.cols_count;
            this.dictionary{this.cols_count} = this.fields{f};
            this.columns{this.cols_count} = column{2:end};
            this.columns_type{this.cols_count} = column{1};
          end
        end
      end
    end
    function InitTags(this)
      h = mysql( 'open', this.Main.db.dbconfig.host, ...
              this.Main.db.dbconfig.user, this.Main.db.dbconfig.password );
      query = sprintf(['SELECT id,tag ',...
                          'FROM %s.tags ',...
                          'WHERE `table` = ''%s'';'],...
                          this.Main.db.dbconfig.schema,...
                          this.keys.table);
      [ this.tagid,temptags ] = mysql(query);
      for t = 1:length(this.tagid)
        this.tags.(temptags{t}) = t;
      end
      this.tags_count = length(this.tags);
      mysql('close') 
    end
    
    function InitHistory(this,tradedate)
      seriesht = false;
      fnames = fieldnames(this.keys);
      for f = 1:length(fnames)
        if strcmp(fnames(f),'name')
          seriesht = true;
          serie = strsplit(this.keys.name,'_');
          %generate folder path based on DB sequence
          h = mysql( 'open', this.Main.db.dbconfig.host, ...
                  this.Main.db.dbconfig.user, this.Main.db.dbconfig.password );
          query = sprintf(['select tradedate,symbol from %s.series ',...
                            'where tradedate < ''%s'' ',...
                            'and serie =''%s'' ',...
                            'and name =''%s'' ',...
                            'order by tradedate desc ',...
                            'limit %i;'],...
                            this.Main.db.dbconfig.schema,...
                            datestr(tradedate,'yyyy-mm-dd'),...
                            serie{1},...
                            serie{2},...
                            this.keys.history);
          [ histdates, symbols ] = mysql(query);
          mysql('close') 
          break;
        end
      end
      if ~seriesht
        %generate folder path based on DB sequence
        h = mysql( 'open', this.Main.db.dbconfig.host, ...
                this.Main.db.dbconfig.user, this.Main.db.dbconfig.password );
        query = sprintf(['select tradedate from %s.tradedate ',...
                          'where tradedate < ''%s'' ',...
                          'order by tradedate desc ',...
                          'limit %i;'],...
                          this.Main.db.dbconfig.schema,...
                          datestr(tradedate,'yyyy-mm-dd'),...
                          this.keys.history);
        [ histdates ] = mysql(query);
        mysql('close') 
      end
      db = this.Instance.Attributes.db;
      this.folder_path = this.Main.db.(db).folder;
      this.folder_path = strcat(this.folder_path,this.keys.table);
      this.folder_path = strcat(this.folder_path,'/');
      histcount = length(histdates);
      for d=histcount:-1:1
        if toc(this.Main.dottime)>1
          fprintf('.');
          this.Main.dottime = tic;
        end
        historydate = histdates(d);
        db = this.Instance.Attributes.db;
        hist_folder_path = this.Main.db.(db).folder;
        hist_folder_path = strcat(hist_folder_path,this.keys.table);
        hist_folder_path = strcat(hist_folder_path,'/');
        for f=1:length(this.fields)
          column = strsplit(cell2mat(this.fields(f)),'_');
          if size(column,2)>1
            if strcmp(column{1},'s')
              if strcmp(column{2},'tradedate')
                hist_folder_path = strcat(hist_folder_path,...
                    datestr(historydate,'yyyy-mm-dd'));
              elseif strcmp(column{2},'marketdata')
                if strcmp(this.keys.marketdata,'auto')
                  md = this.MarketDataPriority(historydate,...
                    this.Main.marketdata);
                  hist_folder_path = strcat(hist_folder_path, md);
                else
                  % Romeu
                  hist_folder_path = strcat(hist_folder_path, this.keys.marketdata);
                end
              elseif strcmp(column{2},'symbol')
                if seriesht
                  hist_folder_path = strcat(hist_folder_path, symbols{d});
                else
                  hist_folder_path = ...
                    strcat(hist_folder_path, this.keys.symbol);
                end
              else
                hist_folder_path = strcat(hist_folder_path,...
                                    this.keys.(column{2}));
              end
              hist_folder_path = strcat(hist_folder_path,'/');
            end
          end
        end
        folder_s = strsplit(hist_folder_path,'/');
        %folder path
        hist_folder_path = '';
        for f = 1:length(folder_s)-2
          hist_folder_path = strcat(hist_folder_path,folder_s(f));
          hist_folder_path = strcat(hist_folder_path,'/');
        end
        %file path
        hist_file_path = hist_folder_path;
        hist_file_path = ...
          strcat(hist_file_path,folder_s(length(folder_s)-1));
        hist_file_path = strcat(hist_file_path,'.bin');
        %create dictionary
        hist_dict_file_path = hist_folder_path;
        hist_dict_file_path = strcat(hist_dict_file_path,...
                                      folder_s(length(folder_s)-1));
        hist_dict_file_path = strcat(hist_dict_file_path,'.csv');
        %cell2mat paths
        hist_dict_file_path = cell2mat(hist_dict_file_path);
        hist_file_path = cell2mat(hist_file_path);
        %read dictionary
        if exist(hist_file_path,'file')
          %{
          fdict = fopen(hist_dict_file_path,'r');
          hist_dictionary = strsplit(fgetl(fdict),',');
          fclose(fdict);
          hist_cols_count = length(hist_dictionary);
          for c=1:hist_cols_count
            column = strsplit(cell2mat(hist_dictionary(c)),'_');
            hist_cols.(column{2:end}) = c;
          end
          if exist(hist_file_path,'file')
          %}
            %read history
            filehandle = fopen(hist_file_path,'r');
            histbuffer = this.ReadHistory(filehandle,this.cols_count);
            hl = size(histbuffer,1);
            this.buffer(end+1:end+hl,:) = histbuffer;
            fclose(filehandle);
          %end
        else
          fprintf('\nHistory not found %s\n',hist_file_path);
        end
      end
    end
    function histbuffer = ReadHistory(this,filehandle,colscount)
      histbuffer = [];
      fseek(filehandle,0,'eof');
      bytecount = ftell(filehandle);
      rowcount = floor(bytecount/(colscount*8));
      if (rowcount>0)
        fseek(filehandle,0,'bof');
        %Load all fdata                                                      
        histbuffer = fread(filehandle,[colscount rowcount],'double')';
      end
    end
    
    function OpenFileIO(this,tradedate)
      %initialize file paths
      this.InitPaths(tradedate);
      %initialize dictionary
      this.InitDictionary();
      if this.isinput
        if ~this.InitIO()
          fprintf('Input not found %s!\n',this.file_path);
        end
      elseif this.isoutput
        if ~this.InitIO()
          fprintf('Output file locked %s!\n',this.file_path);
        end
      end
    end
    function InitPaths(this,tradedate)
      db = this.Instance.Attributes.db;
      this.folder_path = this.Main.db.(db).folder;
      this.folder_path = strcat(this.folder_path,this.keys.table);
      this.folder_path = strcat(this.folder_path,'/');
      md = [];
      if strcmp(this.keys.table,'mdpricemarket') ||...
          strcmp(this.keys.table,'mdquotes') ||...
          strcmp(this.keys.table,'mdtrades')
        if strcmp(this.keys.marketdata,'auto')
          md = this.MarketDataPriority(tradedate,this.Main.marketdata);
        else 
            % Romeu
            md=this.keys.marketdata; 
        end
      end
      for f=1:length(this.fields)
        column = strsplit(cell2mat(this.fields(f)),'_');
        if size(column,2)>1
          if strcmp(column{1},'s')
            if strcmp(column{2},'tradedate')
              this.folder_path = strcat(this.folder_path,...
                  datestr(tradedate,'yyyy-mm-dd'));
            elseif strcmp(column{2},'marketdata')
              this.folder_path = strcat(this.folder_path,md);
            else
              this.folder_path = strcat(this.folder_path,...
                                  this.keys.(column{2}));
            end
            this.folder_path = strcat(this.folder_path,'/');
          end
        end
      end
      folder_s = strsplit(this.folder_path,'/');
      %folder path
      this.folder_path = '';
      for f = 1:length(folder_s)-2
        this.folder_path = strcat(this.folder_path,folder_s(f));
        this.folder_path = strcat(this.folder_path,'/');
      end
      %file path
      this.file_path = this.folder_path;
      this.file_path = strcat(this.file_path,folder_s(length(folder_s)-1));
      this.file_path = strcat(this.file_path,'.bin');
      %create dictionary
      this.dict_file_path = this.folder_path;
      this.dict_file_path = strcat(this.dict_file_path,...
                                    folder_s(length(folder_s)-1));
      this.dict_file_path = strcat(this.dict_file_path,'.csv');
      %cell2mat paths
      this.dict_file_path = cell2mat(this.dict_file_path);
      this.folder_path = cell2mat(this.folder_path);
      this.file_path = cell2mat(this.file_path);
    end
    function md = MarketDataPriority(this,tradedate,marketdata)
      md = '';
      for m=1:length(marketdata)
        md = marketdata(m);
        if iscell(md)
          md = cell2mat(md);
        end
        md_path = strcat(this.folder_path,'RT/');
        md_path = strcat(md_path,datestr(tradedate,'yyyy-mm-dd'));
        md_path = strcat(md_path,'/');
        md_path = strcat(md_path,md);
        md_path = strcat(md_path,'/');
        if exist(md_path,'dir')
          return; 
        end
      end
      md = [];
    end
    function success = InitDictionary(this)
      success = false;
      if ~exist(this.folder_path,'dir')
        mkdir(this.folder_path);
      end
      %read dictionary
      if exist(this.dict_file_path,'file') && this.isinput
        fdict = fopen(this.dict_file_path,'r');
        this.dictionary = strsplit(fgetl(fdict),',');
        fclose(fdict);
        this.cols_count = length(this.dictionary);
        this.cols = [];
        this.columns = [];
        this.columns_type = [];
        for c=1:this.cols_count
          column = strsplit(cell2mat(this.dictionary(c)),'_');
          this.cols.(column{2:end}) = c;
          this.columns{c} = column{2:end};
          this.columns_type{c} = column{1};
        end
        success = true;
      else
        %create dictionary
        this.cols_count = 0;
        for f=1:length(this.fields)
          column = strsplit(cell2mat(this.fields(f)),'_');
          if size(column,2)>1
            if ~strcmp(column{1},'s')
              this.cols_count = this.cols_count +1;
              this.cols.(column{2:end}) = this.cols_count;
              this.dictionary{this.cols_count} = this.fields{f};
              this.columns{this.cols_count} = column{2:end};
              this.columns_type{this.cols_count} = column{1};
            end
          end
        end
        %write dictionary
        fdict = fopen(this.dict_file_path,'w');
        dict_str = strjoin(this.dictionary,',');
        fprintf(fdict,'%s',dict_str);
        fclose(fdict);
        success = true;
      end
    end
    function success = InitIO(this)
      success = false;
      if this.isinput
        if exist(this.folder_path,'dir')
          if exist(this.file_path,'file')
            this.file_handle = fopen(this.file_path,'r');
            success = true;
          end
        end
      elseif this.isoutput
        if ~exist(this.folder_path,'dir')
          mkdir(this.folder_path);
        end
        if this.Main.sim
            this.file_handle = fopen(this.file_path,'w');
        else
          this.ReadOutput();
          this.file_handle = fopen(this.file_path,'a+');
        end
        success = true;
      end
    end
    
    %realtime functions
    function [time, nread] = ReadOutput(this)
      nread = 0;
      time = 0;
      %load first buffer
      this.file_handle = fopen(this.file_path,'r');
      if ~isempty(this.file_handle)
        if this.file_handle>=0
          fseek(this.file_handle,0,'eof');
          this.byte_count = ftell(this.file_handle);
          this.row_count = floor(this.byte_count/(this.cols_count*8));
          this.new_row_count = this.row_count;
          this.lastrow_count = this.row_count;
          fseek(this.file_handle,0,'bof');
          this.buffer = fread(this.file_handle,...
            [this.cols_count this.new_row_count],'double')';
          nread = this.new_row_count;
          if ~isempty(this.buffer)
            newidx = this.buffer(:,this.cols.id)>this.lastid;
            this.buffer = this.buffer(newidx,:);
            if ~isempty(this.buffer)
              time = max(this.buffer(:,this.cols.time));
              lid = max(this.buffer(:,this.cols.id));
              this.lastid = max(this.lastid,lid);
            end
          end
          fclose(this.file_handle);
        end
      end
    end
    function [time, nread] = ReadNew(this)
      nread = 0;
      time = 0;
      if ~isempty(this.file_handle)
        if this.file_handle>=0
          fseek(this.file_handle,0,'eof');
          this.byte_count = ftell(this.file_handle);
          this.row_count = floor(this.byte_count/(this.cols_count*8));
          this.new_row_count = this.row_count - this.lastrow_count;
          if (this.new_row_count>0)
            fseek(this.file_handle,...
              (this.lastrow_count)*this.cols_count*8, 'bof');
            if ~isempty(this.buffer)
              this.buffer = fread(this.file_handle,...
                [this.cols_count this.new_row_count],'double')';
            else
              this.buffer(end+1:end+this.new_row_count,:) = ...
                fread(this.file_handle,...
                [this.cols_count this.new_row_count],'double')';
            end
            nread = this.new_row_count;
            this.lastrow_count = this.lastrow_count + nread;
            if ~isempty(this.buffer)
              newidx = this.buffer(:,this.cols.id)>this.lastid;
              this.buffer = this.buffer(newidx,:);
              if ~isempty(this.buffer)
                time = max(this.buffer(:,this.cols.time));
                lid = max(this.buffer(:,this.cols.id));
                this.lastid = max(this.lastid,lid);
              end
            end
          end
        end
      end
    end
    
    %simulation functions
    function [ti, tf] = ReadAll(this)
      ti = 0;tf = 0;
      if ~isempty(this.file_handle)
        if this.file_handle>=0
          fseek(this.file_handle,0,'eof');
          this.byte_count = ftell(this.file_handle);
        end
      else
        this.byte_count = 0;
      end
      this.row_count = floor(this.byte_count/...
                            (this.cols_count*8));
      this.lastrow_count = 0;
      this.new_row_count = this.row_count;
      if (this.new_row_count>0)
        fseek(this.file_handle,(this.lastrow_count)*this.cols_count*8,...
          'bof');
        %Load all fdata                                                      
        this.tablefile = fread(this.file_handle,...
          [this.cols_count this.new_row_count],'double')';
        ti = min(this.tablefile(:,this.cols.time));
        tf = max(this.tablefile(:,this.cols.time));
      end
    end
    function [time, nread] = ReadUntil(this,lasttime)
      nread = 0;
      time = 0;
      if ~isempty(this.tablefile)
        this.row_count = ...
          find(this.tablefile(:,this.cols.time) <= lasttime,1,'last');
        this.new_row_count = this.row_count - this.lastrow_count;
        if (this.new_row_count>0)
          nread = this.new_row_count;
          newids = this.lastrow_count+1:this.row_count;
          if isempty(this.buffer)
            this.buffer = this.tablefile(newids,:);
          else
            this.buffer(end+1:end+nread,:) = this.tablefile(newids,:);
          end
          this.lastrow_count = this.lastrow_count + nread;
          if ~isempty(this.buffer)
            time = max(this.buffer(:,this.cols.time));
            lid = max(this.buffer(:,this.cols.id));
            this.lastid = max(this.lastid,lid);
          end
        end
      end
    end
    
    %output functions
    function nwrite = WriteOutputs(this)
      nwrite = 0;
      if ~isempty(this.buffer)
        newidx = this.buffer(:,this.cols.id)>this.lastid;
        if any(newidx)
          this.buffer = this.buffer(newidx,:);
          nwrite = size(this.buffer,1);
          fwrite(this.file_handle,this.buffer','double');
          lid = max(this.buffer(:,this.cols.id));
          this.lastid = max(this.lastid,lid);
        end
        this.buffer = [];
      end
    end
    
    function Close(this)
      if ~isempty(this.file_handle)
        fclose(this.file_handle);
      end
    end
  end
end