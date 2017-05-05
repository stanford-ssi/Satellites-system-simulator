clear 
%Don't set clear all. wipes debug points
close all
%Helpful References:
%http://www.ti.com/lit/an/sboa060/sboa060.pdf
% Walks through the noise calculations of a tia^

%% System Parameters:

global verbose
verbose = 1;

global scenario
scenario = 0;
%0 == worst case, default, conservative.
%1 == typical behavior
%2 == Optimistic. 



verbose = 0;
%%
link_package = link_block(); 
%%
tia_outputs = tia_block(link_package);
%%
adc_outputs = adc_block(tia_outputs);
%%
final_signal = adc_outputs{1};
final_noise = adc_outputs{2};
verbose=1
%[angle_uncertainty] = quad_block(final_signal, final_noise)

%%
% System Design:
verbose = 0;
scenario = 0;
link_package = link_block(); 
sigs_worst = tia_block(link_package);

scenario = 2;
link_package = link_block(); 
sigs_best = tia_block(link_package);

calib_power = 0.001; %1mW;
calib_package = { calib_power, 0, link_package{3} + link_package{1} + link_package{2}};
sigs_calib = tia_block(calib_package);
%%
signal_sys_block(sigs_best,sigs_worst, sigs_calib);

