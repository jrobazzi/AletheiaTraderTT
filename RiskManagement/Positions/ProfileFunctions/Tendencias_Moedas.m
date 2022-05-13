function Tendencias_Moedas( Position )
  pcol = Position.IO.cols;
  tags = Position.IO.tags;
  tagid = Position.IO.tagid;
  
  Position.reqorders(:,pcol.value) = 0;
  Position.reqtrade(pcol.value) = 0;
  %
  Position.reqorders(1:2,pcol.tag) = tagid(tags.reqstop);
  Position.reqorders(1:2,pcol.price) = 3072:3073;
  Position.reqorders(1:2,pcol.value) = -105;
  
  Position.reqorders(3:4,pcol.tag) = tagid(tags.reqstop);
  Position.reqorders(3:4,pcol.price) = 3077:3078;
  Position.reqorders(3:4,pcol.value) = -105;
  %}
  %% SETPOSITIONPROFILE
  %{
  symbol = Position.Symbol;
  S=round(3237/symbol.ticksize);
  P1=round(3215/symbol.ticksize);V1=-210;
  P2=round(3190.0/symbol.ticksize);V2=-450;
  P3=round(3169/symbol.ticksize);V3=-690;
  P4=round(3146/symbol.ticksize);V4=-930;
  
  Position.setpositionprofile(S:end)=0;
  Position.setpositionprofile(P1:S)=V1;
  Position.setpositionprofile(P2:P1)=V1;
  Position.setpositionprofile(P3:P2)=V2;
  Position.setpositionprofile(P4:P3)=V3;
  Position.setpositionprofile(1:P4)=V4;
  %}
  
end