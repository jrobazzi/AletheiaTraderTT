function [movmax,undwater,uwTime,worstUw] = underwater(ret)
  movmax = zeros(size(ret));
  undwater = movmax;
  movmax(1) = ret(1);
  uwPer = 0;tLastUw=1;
  maxUwPer=0;maxUw=0;
  for i=2:length(movmax)
    if ret(i)>movmax(i-1)
      movmax(i) = ret(i);
      
      uwPer=uwPer+1;
      uwTime(uwPer) = i-tLastUw;
      tLastUw=i;
      
      maxUwPer=maxUwPer+1;
      worstUw(maxUwPer)=maxUw;
      maxUw=0;
    else
      movmax(i) = movmax(i-1);
    end
    undwater(i) = ret(i)-movmax(i);
    if undwater(i)<maxUw
      maxUw=undwater(i);
    end
  end
end