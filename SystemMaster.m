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

ground_sigs = {time, signal_tx, noise_tx, signal_power...
    noise_power};


zenith_ang = 0; %Degrees
distance = 430000; %Meters
orbit_package = {zenith_ang, distance};

pointing_err = 0;
jitter = 0;
pointing_package = {pointing_err, jitter};

link_package = link_block(ground_sigs, orbit_package,  pointing_package, optics_package); 
tia_outputs = tia_block(link_package, bandwidth, w, df);
adc_outputs = adc_block(tia_outputs);
final_signal = adc_outputs{1};
final_noise = adc_outputs{2};
[angle_uncertainty] = quad_block(final_signal, final_noise)



%ground_telescope(w); %Handles ground modulation
%atmo_sigs = link_block(ground_sigs, w);
% tia_outputs = tia_block(atmo_sigs, bandwidth, w, df);
% tia_sig = tia_outputs{1};
% tia_noise = tia_outputs{2};
% %signal_processing_block(sigs, w);
% 
% %%
% %Converts SNR into an angle
% SNR = logspace(-5,10,1000);
% %SNR = get_snr(tia_sig, tia_noise, df);
% %mag2db(SNR) %Sanity check component. from Theory of tracking accuracy of
% %laser systems. eq 62
% spot_size = 0.001; %.2mm
% var_x = SNR.^-1.*(1-8./SNR)./(1+8./SNR).^2;
% dx = spot_size.^2*var_x %denormalized variance. eq 3b
% fc = 0.015 %focal distance assuming simple telescope (it's not)
% var_theta_II = asin(dx/fc);
% 
% display =1;
% if(display ==1)
%     figure
%     hold on;
%     o = ones(length(SNR),1)';
%     target_angle = 1E-7; %0.1uRad;
%     plot(mag2db(SNR),log10(var_theta_II));
%     plot(mag2db(SNR),log10(target_angle*o));
%     title('SNR of Quad VS. Angular Variance');
%     ylabel('Variance, Rad');
%     xlabel('SNR, linear');
%     legend('Var vs SNR','Target Variance');
% 
% end
% 
% if(verbose ==1)
%     'Angle Variance: '
%     var_theta_II
% end
    %target_theta = 1E-6;
%tg = ones(1,length(SNR))*target_theta; figure semilogy(mag2db(SNR),
%var_theta_II); title('SNR vs Angular Determination'); xlabel('SNR (dB)')
%ylabel('Radians')
% 
% %'yo?'
