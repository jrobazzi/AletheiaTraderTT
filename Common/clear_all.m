% %# store breakpoints
tmp = dbstatus;
save('tmp.mat','tmp')
clc;clear;
clear all;
%close all;
%# reload breakpoints
load('tmp.mat')
dbstop(tmp)
%# clean up
clear tmp
delete('tmp.mat')