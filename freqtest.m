
tau=0.0194434438537431;
sysd_filt = tf([tau 0],[1 tau-1],15)
set(sysd_filt,'variable','z^-1')
sysd_dev = tf([1],[1],15)
sysd_dev = sysd_dev - sysd_filt;
set(sysd_dev,'variable','z^-1')


sysd_ma = tf(...
  [0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 ...
  0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05],...
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ],...
  60);
set(sysd_ma,'variable','z^-1')

sysd_filt
sysd_dev
%sysd_ma

bode(sysd_filt)
hold on
bode(sysd_ma)
hold off