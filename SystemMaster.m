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


F_high = 10E6;
F_low = 2;

F_high = 100;
F_low = 0.01;

F_high = 15900;
F_low = 673;

samples = 100000;
df = ((F_high-F_low)/samples);


df = round(F_high)-round(F_low);
df = df/samples;
a = linspace(F_low, F_high, samples);

%Log exploration:
f_log_h= 8;
f_log_l= -1;
a = logspace(f_log_l, f_log_h, 1000);
%a =linspace(f_log_l, f_log_h, 1000)

%a = np.linspace(df, frequencies)
w = a;
bandwidth = F_high-F_low;



zenith_ang = 0; %Degrees
distance = 430000; %Meters
orbit_package = {zenith_ang, distance};

pointing_err = 0;
jitter = 0;
pointing_package = {pointing_err, jitter};

link_package = link_block(); 
tia_outputs = tia_block(link_package, bandwidth, w, df);
adc_outputs = adc_block(tia_outputs);
final_signal = adc_outputs{1};
final_noise = adc_outputs{2};
[angle_uncertainty] = quad_block(final_signal, final_noise)



