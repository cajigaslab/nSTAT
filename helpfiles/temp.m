t=linspace(0,10,1000); f=1;

x = sin(2*pi*f*t) + .5*rand(1,length(t));

a=1;
b=[1 1]/2;

Noder=10;
a=1;
b=ones(1,Noder)/Noder;

xnew  = filtfilt(b,a,x);

close all;
plot(t,x); hold on;
plot(t,xnew,'r-.');
