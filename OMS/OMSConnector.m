classdef OMSConnector < handle
  
  properties (Constant)
    REQSIZE = 50000;
    REPORTSIZE = 50000;
    ORDSIZE = 20000;
    TRADESIZE = 10000;
    
    OMS_STATUS_MANUAL = 1;
    OMS_STATUS_AUTO = 2;
    OMS_STATUS_REQPENDING = 3;
    OMS_STATUS_CANCELLING = 4;
    OMS_STATUS_REPORTPENDING = 5;
    OMS_STATUS_DELAY = 6;
    OMS_STATUS=...
      {'MANUAL','AUTO','REQPENDING','CANCELLING',...
      'REPORTPENDING','DELAY'};
    
    OMSREPORTS_ORDTYPE_LIMIT = 1;
    OMSREPORTS_ORDTYPE_STOP = 2;
    OMSREPORTS_ORDTYPE_IOC = 3;
  
    PROFILESIZE = 30000; % alterado por abend no profileposition graph
end
  
  properties
    Main
    Instance
    keys
    %Classes
    Symbol
    Position
    OMSRequests
    OMSReports
    OMSTrades
    %OMS INDEX
    active = false;
    nrequests = 0;
    nreports = 0;
    norders = 0;
    %REQUESTS OUTPUTS
    requests
    %REPORTS INPUTS
    reports
    
    orders
    iocidx
    limitidx
    stopidx
    
    reqpendingidx
    reqcancelidx
    reportpendingidx
    activeidx
    stoptriggeridx
    
    ordersprofile
    positionprofile
    resultprofile
    rlogprofile
  end
  
  methods
    function this = OMSConnector(Position,instance)
      this.Main = Position.Main;
      this.Instance = instance;
      this.Position = Position;
      this.Symbol = Position.Symbol;
      this.OMSRequests = FileIO.empty;
      this.OMSReports = FileIO.empty;
      if strcmp(this.Instance.Attributes.active,'true')
        this.active = true;
      end        
      if ~this.Position.simulated
        this.Instance.Attributes.IO = 'input';
        this.Instance.Attributes.table = 'omstrades';
        this.OMSTrades = FileIO(this.Main,this.Instance);
        if (this.Main.sim || this.Main.backtest || ~this.active)
          this.Instance.Attributes.IO = 'input';
          this.Instance.Attributes.table = 'omsrequests';
          this.OMSRequests = FileIO(this.Main,this.Instance);
        else
          this.Instance.Attributes.IO = 'output';
          this.Instance.Attributes.table = 'omsrequests';
          this.OMSRequests = FileIO(this.Main,this.Instance);
        end
        this.Instance.Attributes.IO = 'input';
        this.Instance.Attributes.table = 'omsreports';
        this.OMSReports = FileIO(this.Main,this.Instance);
        
        this.requests = zeros(this.REQSIZE,this.OMSRequests.cols_count);
        this.reports = zeros(this.REPORTSIZE,this.OMSReports.cols_count);
        
        this.orders = zeros(this.ORDSIZE,this.OMSReports.cols_count);
        this.iocidx = false(this.ORDSIZE,1);
        this.limitidx = false(this.ORDSIZE,1);
        this.stopidx = false(this.ORDSIZE,1);
        this.reqpendingidx = false(this.ORDSIZE,1);
        this.reqcancelidx = false(this.ORDSIZE,1); 
        this.reportpendingidx = false(this.ORDSIZE,1);
        this.activeidx = false(this.ORDSIZE,1);
        this.stoptriggeridx = false(this.ORDSIZE,1);
      else
        this.Instance.Attributes.IO = 'output';
        this.Instance.Attributes.table = 'omstrades';
        this.OMSTrades = FileIO(this.Main,this.Instance);
      end
      this.positionprofile = zeros(1,this.PROFILESIZE);
      this.resultprofile = zeros(1,this.PROFILESIZE);
      this.rlogprofile = zeros(1,this.PROFILESIZE);
    end

    %% LOAD TRADE HISTORY
    function LoadOMSTradeHistory(this,tradedate)
      query = sprintf(['SELECT d_id,d_orderid,d_requestid,'...
        'd_clordid,d_msgnum,d_tradeid,d_contrabroker,'...
        't_timestamp,d_tag,t_time,d_price,d_value '...
        'FROM dbaccounts.omstrades '...
        'WHERE s_source=''RT'' '...
        'AND s_tradedate>=''%s'' '...
        'AND s_tradedate<''%s'' '...
        'AND s_account=''%s'' '...
        'AND s_strategy=''%s'' '...
        'AND s_symbol like ''%s%%'' '...
        'AND s_oms = ''%s'' ;'],...
        this.Instance.Attributes.from,...
        datestr(tradedate,'yyyy-mm-dd'),...
        this.Instance.Attributes.account,...
        this.Instance.Attributes.strategy,...
        this.Symbol.symbol(1:3),...
        this.Instance.Attributes.oms);
      h = mysql( 'open', this.Main.db.dbaccounts.host,...
        this.Main.db.dbaccounts.user, this.Main.db.dbaccounts.password );
      [ buffer(:,1),buffer(:,2),buffer(:,3),...
      buffer(:,4),buffer(:,5),buffer(:,6),...
      buffer(:,7),buffer(:,8),buffer(:,9),...
      buffer(:,10),buffer(:,11),buffer(:,12) ] = mysql(query);
      mysql('close') ;
      this.OMSTrades.buffer=buffer;
    end
    
    %% ORDER REQUESTS
    function UpdateRequests(this)
      if this.active
        if ~isempty(this.OMSRequests.buffer)
          l = this.nrequests;
          n = size(this.OMSRequests.buffer,1);
          this.nrequests = this.nrequests+n;
          for r=1:n
            this.requests(l+r,:)=this.OMSRequests.buffer(r,:);
            RequestOrders(this,this.requests(l+r,:),false);
          end
          this.OMSRequests.buffer=[];
        end
      end
    end
    function success=NewIOCOrder(this,orderpri,contracts)
      success = false;
      col = this.OMSRequests.cols;
      t = this.Main.time;
      orderpri = round(orderpri/this.Symbol.ticksize)*this.Symbol.ticksize;
      contracts = round(contracts/this.Symbol.lotmin)*this.Symbol.lotmin;
      if this.nrequests < this.REQSIZE && contracts~=0
        this.nrequests = this.nrequests+1;
        tagid = this.OMSRequests.tagid;
        tagid = tagid(this.OMSRequests.tags.requestnewioc);
        this.requests(this.nrequests,col.id) = this.nrequests;
        this.requests(this.nrequests,col.orderid) = 0;
        this.requests(this.nrequests,col.tag) = tagid;
        this.requests(this.nrequests,col.time) = t;
        this.requests(this.nrequests,col.price) = orderpri;
        this.requests(this.nrequests,col.value) = contracts;
        this.RequestOrders(this.requests(this.nrequests,:),true);
        success = true;
      end
    end
    function success=NewLimitOrder(this,orderpri,contracts)
      success = false;
      col = this.OMSRequests.cols;
      t = this.Main.time;
      orderpri = round(orderpri/this.Symbol.ticksize)*this.Symbol.ticksize;
      contracts = round(contracts/this.Symbol.lotmin)*this.Symbol.lotmin;
      if this.nrequests < this.REQSIZE && contracts~=0
        this.nrequests = this.nrequests+1;
        tagid = this.OMSRequests.tagid;
        tagid = tagid(this.OMSRequests.tags.requestnewlimit);
        this.requests(this.nrequests,col.id) = this.nrequests;
        this.requests(this.nrequests,col.orderid) = 0;
        this.requests(this.nrequests,col.tag) = tagid;
        this.requests(this.nrequests,col.time) = t;
        this.requests(this.nrequests,col.price) = orderpri;
        this.requests(this.nrequests,col.value) = contracts;
        this.RequestOrders(this.requests(this.nrequests,:),true);
        success = true;
      end
    end
    function success=NewStopOrder(this,orderpri,contracts)
      success = false;
      col = this.OMSRequests.cols;
      t = this.Main.time;
      orderpri = round(orderpri/this.Symbol.ticksize)*this.Symbol.ticksize;
      contracts = round(contracts/this.Symbol.lotmin)*this.Symbol.lotmin;
      if this.nrequests < this.REQSIZE && contracts~=0
        this.nrequests = this.nrequests+1;
        tagid = this.OMSRequests.tagid;
        tagid = tagid(this.OMSRequests.tags.requestnewstop);
        this.requests(this.nrequests,col.id) = this.nrequests;
        this.requests(this.nrequests,col.orderid) = 0;
        this.requests(this.nrequests,col.tag) = tagid;
        this.requests(this.nrequests,col.time) = t;
        this.requests(this.nrequests,col.price) = orderpri;
        this.requests(this.nrequests,col.value) = contracts;
        this.RequestOrders(this.requests(this.nrequests,:),true);
        success = true;
      end
    end
    function success=CancelReplaceOrder(this,orderid,orderpri,contracts)
      success = false;
      col = this.OMSRequests.cols;
      t = this.Main.time;
      if this.nrequests < this.REQSIZE
        this.nrequests = this.nrequests+1;
        tagid = this.OMSRequests.tagid;
        tagid = tagid(this.OMSRequests.tags.requestreplace);
        this.requests(this.nrequests,col.id) = this.nrequests;
        this.requests(this.nrequests,col.orderid) = orderid;
        this.requests(this.nrequests,col.tag) = tagid;
        this.requests(this.nrequests,col.time) = t;
        this.requests(this.nrequests,col.price) = orderpri;
        this.requests(this.nrequests,col.value) = contracts;
        this.RequestOrders(this.requests(this.nrequests,:),true);
        success = true;
      end
    end
    function success=CancelOrder(this,orderid,orderpri,contracts)
      success = false;
      col = this.OMSRequests.cols;
      t = this.Main.time;
      if this.nrequests < this.REQSIZE
        this.nrequests = this.nrequests+1;
        tagid = this.OMSRequests.tagid;
        tagid = tagid(this.OMSRequests.tags.requestcancel);
        this.requests(this.nrequests,col.id) = this.nrequests;
        this.requests(this.nrequests,col.orderid) = orderid;
        this.requests(this.nrequests,col.tag) = tagid;
        this.requests(this.nrequests,col.time) = t;
        this.requests(this.nrequests,col.price) = orderpri;
        this.requests(this.nrequests,col.value) = contracts;
        this.RequestOrders(this.requests(this.nrequests,:),true);
        success = true;
      end
    end
    function RequestOrders(this,req,sendorder)
      reqcol = this.OMSRequests.cols;
      repcol = this.OMSReports.cols;
      tagid = this.OMSRequests.tagid;
      tags = this.OMSRequests.tags;
      switch req(reqcol.tag)
        case tagid(tags.requestnewioc)
          if sendorder
            this.norders = this.norders+1;
            orderid = this.norders;
            this.reqpendingidx(orderid) = true;
          else
            orderidx = this.orders(1:this.norders,repcol.requestid) == ...
                                              req(reqcol.id);
            if any(orderidx)
              orderid = find(orderidx,1);
            else
              this.norders = this.norders+1;
              orderid = this.norders;
              this.reqpendingidx(orderid) = true;
            end
          end
          this.orders(orderid,repcol.requestid) = req(reqcol.id);
          this.orders(orderid,repcol.tag) = tagid(tags.requestnewioc);
          this.orders(orderid,repcol.price) = req(reqcol.price);
          this.orders(orderid,repcol.value) = req(reqcol.value);
          this.orders(orderid,repcol.ordtype)=this.OMSREPORTS_ORDTYPE_IOC;
          this.iocidx(orderid) = true;
        case tagid(tags.requestnewlimit)
          if sendorder
            this.norders = this.norders+1;
            orderid = this.norders;
            this.reqpendingidx(orderid) = true;
          else
            orderidx = this.orders(1:this.norders,repcol.requestid) == ...
                                              req(reqcol.id);
            if any(orderidx)
              orderid = find(orderidx,1);
            else
              this.norders = this.norders+1;
              orderid = this.norders;
              this.reqpendingidx(orderid) = true;
            end
          end
          this.orders(orderid,repcol.requestid) = req(reqcol.id);
          this.orders(orderid,repcol.tag)=tagid(tags.requestnewlimit);
          this.orders(orderid,repcol.price) = req(reqcol.price);
          this.orders(orderid,repcol.value) = req(reqcol.value);
          this.orders(orderid,repcol.ordtype)=...
            this.OMSREPORTS_ORDTYPE_LIMIT;
          this.limitidx(orderid) = true;
        case tagid(tags.requestnewstop)
          if sendorder
            this.norders = this.norders+1;
            orderid = this.norders;
            this.reqpendingidx(orderid) = true;
          else
            orderidx = this.orders(1:this.norders,repcol.requestid) == ...
                                              req(reqcol.id);
            if any(orderidx)
              orderid = find(orderidx,1);
            else
              this.norders = this.norders+1;
              orderid = this.norders;
              this.reqpendingidx(orderid) = true;
            end
          end
          this.orders(orderid,repcol.requestid) = req(reqcol.id);
          this.orders(orderid,repcol.tag)=tagid(tags.requestnewstop);
          this.orders(orderid,repcol.price) = req(reqcol.price);
          this.orders(orderid,repcol.value) = req(reqcol.value);
          this.orders(orderid,repcol.ordtype)=this.OMSREPORTS_ORDTYPE_STOP;
          this.stopidx(orderid) = true;
        case tagid(tags.requestreplace)
          orderid = find(this.orders(1:this.norders,repcol.orderid) == ...
                                              req(reqcol.orderid));
          if ~isempty(orderid)
            this.reqpendingidx(orderid) = true;
          end
        case tagid(tags.requestcancel)
          orderid = find(this.orders(1:this.norders,repcol.orderid) == ...
                                              req(reqcol.orderid));
          if ~isempty(orderid)
            this.reqpendingidx(orderid) = true;
            this.reqcancelidx(orderid) = true;
          end
      end
      if sendorder
        if isempty(this.OMSRequests.buffer)
          this.OMSRequests.buffer = req;
        else
          this.OMSRequests.buffer(end+1,:) = req;
        end
      end
    end
    
    %% ORDER REPORTS
    function UpdateOrders(this)
      if ~isempty(this.OMSReports.buffer)
        l = this.nreports;
        this.nreports = this.nreports + size(this.OMSReports.buffer,1);
        this.reports(l+1:this.nreports,:)=this.OMSReports.buffer;
        this.OMSReports.buffer=[];
        col = this.OMSReports.cols;
        for r=l+1:this.nreports
          currorder = this.reports(r,:);
          if this.norders > 0
            if currorder(col.orderid)~=0
              %search by orderid
              orderidx =...
                this.orders(1:this.norders,col.orderid) == ...
                                              currorder(col.orderid);
            else
              orderidx=[];
            end
            %if not found 
            if ~any(orderidx)
              if currorder(col.requestid)~=0
                %search order by requestid
                orderidx =...
                  this.orders(1:this.norders,col.requestid) == ...
                                            currorder(col.requestid);
              else
                orderidx=[];
              end
            end
            %update/create new order
            if any(orderidx)
              this.orders(orderidx,:) = currorder;
              orderid = find(orderidx,1);
              this.OrderStateMachine(orderid,currorder);
            else
              this.norders = this.norders + 1;
              this.orders(this.norders,:) = currorder;
              this.activeidx(this.norders) = ...
                this.isOrderActive(currorder(col.tag));
            end
          else %if first order
            this.norders = 1;
            this.orders(this.norders,:) = currorder;
            this.activeidx(this.norders) = ...
                this.isOrderActive(currorder(col.tag));
          end
        end
        if ~this.Position.simulated
          this.UpdatePositionProfile();
        end
      end
    end
    function OrderStateMachine(this,orderid,currorder)
      col = this.OMSReports.cols;
      tagid = this.OMSReports.tagid;
      tags = this.OMSReports.tags;
      this.reqpendingidx(orderid) = false;
      switch currorder(col.tag)
        case tagid(tags.reportpending)
          this.reportpendingidx(orderid) = true;
          
        case tagid(tags.newlimit) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;
          
        case tagid(tags.newstoplimit) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;
          
        case tagid(tags.stoptrigger) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;
          this.stoptriggeridx(orderid) = true;
          
        case tagid(tags.newioc) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;
          
        case tagid(tags.replace) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;  
          
        case tagid(tags.partial) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;  
          
        case tagid(tags.filled) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = false; 
          
        case tagid(tags.cancelled) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = false;   
          
        case tagid(tags.cancelled) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = false; 
          
        case tagid(tags.rejected) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = false; 
          
        case tagid(tags.expired) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = false;   
          
        case tagid(tags.restated) 
          this.reportpendingidx(orderid) = false;
          this.activeidx(orderid) = true;   
         
        case tagid(tags.requestreject)
          this.reportpendingidx(orderid) = false;
      end
    end
    function active = isOrderActive(this,tag)
      active = false;
      if (tag >= 150 && tag <=156) || tag == 161
        active = true;
      end
    end
    function UpdatePositionProfile(this)
      if ~isempty(this.OMSReports)
      rcol = this.OMSReports.cols;
      q = this.Symbol.tickvalue/this.Symbol.ticksize; 
      nactive = sum(this.activeidx);
      if nactive > 0
        this.positionprofile = zeros(1,this.PROFILESIZE);
        this.resultprofile = zeros(1,this.PROFILESIZE);
        this.rlogprofile = zeros(1,this.PROFILESIZE);
        this.ordersprofile = this.orders(this.activeidx,:);
        this.ordersprofile(:,rcol.value) = 0;
        activeids = find(this.activeidx);
        
        for p=1:nactive
          currorder = this.orders(activeids(p),:);
          currpx = round(currorder(rcol.price)/this.Symbol.ticksize);
          if currorder(rcol.ordtype) == this.OMSREPORTS_ORDTYPE_LIMIT
            %limit order
            if currorder(rcol.value) > 0
              %long limit
              this.positionprofile(1:currpx) =...
                this.positionprofile(1:currpx)+...
                  currorder(rcol.value);
              this.resultprofile(1:currpx) =...
                this.resultprofile(1:currpx)+...
                ([1:currpx].*this.Symbol.ticksize...
                -currorder(rcol.price)).*currorder(rcol.value)*q;
              priceidx = ...
                this.ordersprofile(:,rcol.price) <= currorder(rcol.price);
              if any(priceidx)
                this.ordersprofile(priceidx,rcol.value) =...
                  this.ordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            elseif currorder(rcol.value) < 0
              %short limit
              this.positionprofile(currpx:end) =...
                this.positionprofile(currpx:end) + ...
                  currorder(rcol.value);
              this.resultprofile(currpx:end) =...
                this.resultprofile(currpx:end)+...
                ([currpx:this.PROFILESIZE].*this.Symbol.ticksize ...
                - currorder(rcol.price)).*currorder(rcol.value)*q;
              priceidx = ...
                this.ordersprofile(:,rcol.price) >= currorder(rcol.price);
              if any(priceidx)
                this.ordersprofile(priceidx,rcol.value) =...
                  this.ordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            end
          elseif currorder(rcol.ordtype) == this.OMSREPORTS_ORDTYPE_STOP
            %stop order
            if currorder(rcol.value) > 0
             %long stop
              this.positionprofile(currpx:end) =...
                this.positionprofile(currpx:end) + ...
                  currorder(rcol.value);
              this.resultprofile(currpx:end) =...
                this.resultprofile(currpx:end)+...
                ([currpx:this.PROFILESIZE].*this.Symbol.ticksize...
                - currorder(rcol.price)).*currorder(rcol.value)*q;
              
              priceidx = ...
                this.ordersprofile(:,rcol.price) >= currorder(rcol.price);
              if any(priceidx)
                this.ordersprofile(priceidx,rcol.value) =...
                  this.ordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            elseif currorder(rcol.value) < 0
              %short stop
              this.positionprofile(1:currpx) =...
                this.positionprofile(1:currpx) + ...
                  currorder(rcol.value);
               this.resultprofile(1:currpx) =...
                this.resultprofile(1:currpx)+...
                ([1:currpx].*this.Symbol.ticksize ...
                - currorder(rcol.price)).*currorder(rcol.value)*q;
              priceidx = ...
                this.ordersprofile(:,rcol.price) <= currorder(rcol.price);
              if any(priceidx)
                this.ordersprofile(priceidx,rcol.value) =...
                  this.ordersprofile(priceidx,rcol.value)+...
                    currorder(rcol.value);
              end
            end
          end
        end
        
        position = this.Position;
        pcol = this.OMSTrades.cols;
        if position.ntrades>0
          this.positionprofile = this.positionprofile +...
            position.contracts(position.ntrades);
          this.resultprofile = this.resultprofile +...
            position.resultclosed(position.ntrades);
          if position.contracts(position.ntrades)~=0
            this.resultprofile = this.resultprofile + ...
              ([1:this.PROFILESIZE].*this.Symbol.ticksize - ...
              position.avgprice(position.ntrades)).*...
              position.contracts(position.ntrades)*q;
          end
          this.ordersprofile(:,rcol.value) =...
            this.ordersprofile(:,rcol.value)+...
            position.contracts(position.ntrades);
        end
      else
        position = this.Position;
        pcol = this.OMSTrades.cols;
        this.positionprofile = zeros(1,this.PROFILESIZE);
        this.resultprofile = zeros(1,this.PROFILESIZE);
        if position.ntrades>0
          this.positionprofile = this.positionprofile +...
            position.contracts(position.ntrades);
          this.resultprofile = this.resultprofile +...
            position.resultclosed(position.ntrades);
          if position.contracts(position.ntrades)~=0
            this.resultprofile = this.resultprofile + ...
              ([1:this.PROFILESIZE].*this.Symbol.ticksize - ...
              position.avgprice(position.ntrades)).*...
              position.contracts(position.ntrades)*q;
          end
        end
      end
      end
    end
    
    %% OMS STATUS
    function status = UpdateStatus(this,autotrade)
      if any(this.reqcancelidx(1:this.norders) & ...
                  this.activeidx(1:this.norders))
        status = this.OMS_STATUS_CANCELLING;
      elseif any(this.reqpendingidx(1:this.norders))
        status = this.OMS_STATUS_REQPENDING;
      elseif any(this.reportpendingidx(1:this.norders))
        status = this.OMS_STATUS_REPORTPENDING;
      elseif autotrade
        status = this.OMS_STATUS_AUTO;
      else
        status = this.OMS_STATUS_MANUAL;
      end
    end
    
  end
  
end