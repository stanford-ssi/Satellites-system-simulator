%%
%system_scratchpad II
%for finding a larger Rf.

Rf = 1E6; %000E3;
GBP = 2E6; %2Mhz
Cin = 100E-12;

f3b = sqrt(GBP/(2*pi*Rf*Cin))
%Limited by bandwidth, no longer by the voltage rails.  
