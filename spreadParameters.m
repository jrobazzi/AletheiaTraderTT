sigref = 4;inspread=3;outspread=1.5;
inLong=-sigref; outLong=0; inLongExp = inspread; outLongExp = 1/outspread;
inShort=sigref; outShort=0; inShortExp = inspread; outShortExp = 1/outspread;

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
figure(1000)
plot(xLong,inLongRef,'b');
hold on
plot(xLong,outLongRef,'m');
plot(xShort,inShortRef,'r');
plot(xShort,outShortRef,'c');
%hold off
xlabel('Std');ylabel('Delta');title('Delta x Std')
figure(2000)
plot(xLong,outLongRef-inLongRef,'b',...
  xShort,inShortRef-outShortRef,'r');hold on;
xlabel('Std');ylabel('Spread');title('Spread x Std')