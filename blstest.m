s = 95:0.1:105;
sig = 0.1;
[atmcall,atmput] = blsprice(s,1,0,1,sig);
[itmcall,otmput] = blsprice(s,1+4*sig,0,1,sig);
[otmcall,itmput] = blsprice(s,1-4*sig,0,1,sig);

figure
plot(s,atmcall)