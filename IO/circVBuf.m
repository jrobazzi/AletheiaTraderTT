classdef circVBuf < handle
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% properties

    %% --------------------------------------------------------------------     
    properties (SetAccess = private, GetAccess = public)
                            % buffer (initialized in constructor)
        vecSz int64 = 0 % size of vector to store (only change in constructor)
        bufSz int64 = 0 % max number of vectors to store (only change in constructor)
        
        fst int64   = nan % first index == position of oldest/first value in circular buffer
        new int64   = nan %   new index == position of first new value added in last append()
        lst int64   = nan %  last index == position of newest/last value in circular buffer
        
        newCnt int64= 0   % number of new values added lately (last append call).
        timenow
        
        AppendType = 0
        append % function pointer to append0,1,2 or 3 
        
        cols
        cols_count
        tags
        tagid
        tags_count
    end
    properties
      data
      lastid = 0;
    end
    properties (Dependent)
      alldata
      newdata
      length
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% constructor/destructor
    methods     

        %% ----------------------------------------------------------------
        function this = circVBuf(bufSize,cols_count,cols,tags,tagid)
            appendType = 0;
            assert(isa(bufSize,'int64'))                
            %mustBeA(bufSize, 'int64')
            assert(isa(cols_count,'int64'))
            %mustBeA(cols_count, 'int64')
            
            this.setup(bufSize, cols_count, appendType);
            if nargin >2
            this.cols = cols;
            this.tags = tags;
            this.tagid = tagid;
            this.cols_count = cols_count;    
            this.tags_count = length(tags);
            this.timenow = 0;
            end
        end
        
        %% ----------------------------------------------------------------        
        function delete(this)
            this.data = []; 
        end
        
        %% ----------------------------------------------------------------
        function r = get.alldata(this)
          r = this.data(this.fst:this.lst,:);
        end
        function r = get.newdata(this)
          r = this.data(this.new:this.lst,:);
        end
        function r = alltag(this,tagpos,column)
          tagidx = this.alldata(:,this.cols.tag) == this.tagid(tagpos);
          r = this.alldata(tagidx,column);
        end
        function r = newtag(this,tagpos,column)
          tagidx = this.newdata(:,this.cols.tag) == this.tagid(tagpos);
          r = this.newdata(tagidx,column);
        end
        function r = get.length(this)
          r = size(this.fst:this.lst,1);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% public 
    methods (Access=public)
        
        %% ----------------------------------------------------------------
        function setup(this,bufSize,column_count,appendType)
            assert(isa(bufSize,'int64'))
            %mustBeA(bufSize, 'int64')
            assert(isa(column_count,'int64'))
            %mustBeA(column_count, 'int64')
            
            % buffer initialized once here
            this.bufSz = int64(bufSize); % fixed values         
            this.vecSz = int64(column_count); % fixed values
            
            this.AppendType = appendType;
            this.append = @this.append0;
            
            if(appendType == 0) % double buffered
              this.data  = nan(bufSize*2, column_count, 'double');
              this.append = @this.append0;    
              
            elseif(appendType == 1) % simple copy-all
              this.data  = nan(bufSize, column_count, 'double');
              this.append = @this.append1;   
              
            elseif(appendType == 2) % double buffered
              this.data  = nan(bufSize*2, column_count, 'double');
              this.append = @this.append2;    
              
            elseif(appendType == 3) % double buffered
              this.data  = nan(bufSize*2, column_count, 'double');
              this.append = @this.append3;
            else
              error('append type unkown')
            end
            
            this.clear();
        end
        
        %% ----------------------------------------------------------------        
        function clear(this)
            if(this.AppendType == 0) % moving first/last index, double buffered
                this.fst = this.bufSz+1;
                this.lst = this.bufSz;
            elseif(this.AppendType == 1) % always copy all
                this.fst = int64(1);
                this.lst = int64(0);                
            elseif(this.AppendType == 2 || this.AppendType == 3) % copy all on circle
                this.fst = int64(1);
                this.lst = int64(0);
            else
                error('AppendType not supported.');
            end
            this.new = this.fst;            
            this.newCnt = int64(0);               
        end        
        
        %% ----------------------------------------------------------------     
        function cpSz = append0(this,vec)
            %assert(isa(vec,'double')) % disabled because it consumes time   
            
            % preload values == increase performance !?
            f = this.fst;
            l = this.lst;
            if ~isempty(this.cols) && ~isempty(vec)
              this.lastid = max(max(vec(:,this.cols.id)),this.lastid);
              this.timenow = vec(end,this.cols.time);
            end
            % preload values == increase performance !?
            vSz  = size(vec,1);
            bSz  = this.bufSz;
            
            % calc number of vectors to add to buffer and start position in vec            
            cpSz  = min(vSz, bSz);         % do not copy more vectors than buffer size
            cpSz1 = min(cpSz, (bSz*2 -l)); % no. vectors added on the right side (beginning with pos lst) 
            cpSz2 = cpSz -cpSz1;           % no. vectors added on left side (beginning with pos 1)
            
            vSt = max(1, vSz-cpSz+1);      % start position in input vector array (we might have to skip values if vSz>bSz)
 
            % add data after lst
            this.data(l+1    :l+cpSz1    ,:) = vec(vSt:vSt+cpSz1-1,:);
            this.data(l+1-bSz:l+cpSz1-bSz,:) = vec(vSt:vSt+cpSz1-1,:);
            
            % cpSz2: number of vectors to add at buffer begin
            if(cpSz2 == 0)
                % add |bbbbbbb|: cpSz1==7, cpSz2==0
                % |AAAaaaaaaaaaaAAAAAAA|  -->  |AAABBBBBBBaaabbbbbbb|
                %     f--------l                          f--------l 
                %     4        13                         11       20
                this.fst = min(bSz+1, f+cpSz1); % until buffer is completly filled the first time min() is required
                this.lst = l +cpSz1;
            else % called only on buffer cycle (performance irrelevant)
                % add |bbbbbbbb|: cpSz1==7, cpSz2==2
                % |AAAaaaaaaaaaaAAAAAAA|  -->  |bbABBBBBBBBBabbbbbbb|
                %     f--------l                  f--------l 
                %     4        13                 3        12               
                this.data(    1:cpSz2,    :) = vec(vSt+cpSz1:vSt+cpSz-1,:); % copy bb
                this.data(bSz+1:cpSz2+bSz,:) = vec(vSt+cpSz1:vSt+cpSz-1,:); % copy BB
                
                this.fst = cpSz2 +1;
                this.lst = cpSz2 +bSz;            
            end
      
            % new in buffer            
            this.new = this.lst -cpSz +1;
            this.newCnt = cpSz;
        end
    end
    
end

