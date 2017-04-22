clear all
close all
%Helpful References:
%http://www.ti.com/lit/an/sboa060/sboa060.pdf
% Walks through the noise calculations of a tia^

%% System Parameters:
recieved_optical_signal = 22E-6;%Opals prediction.
recieved_optical_signal = 1E-6;%Opal's prediction w/ airmass=10;

albedo_irradiance = 1E-6; %Noise levels caused by Earth's irradiance and background light.
albedo_irradiance = 0;

    %Todo; Fix. Totally made up number;
optical_noise = 1E-12; %Laser noise. Atmo-noise. Anything the link budget says we've got.
    %Todo; Fix. Also totally made up
global verbose;
verbose = 1;




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

time = linspace(1,1000);
signal_tx = sin(time);
noise_tx = 0;
signal_power = rms(signal_tx);
noise_power = rms(noise_tx);
ground_sigs = {time, signal_tx, noise_tx, signal_power...
    noise_power};

notch_bw = 11E-9;%11nm. From Opals paper on their optical filter.
optics_package = {notch_bw};

zenith_ang = 0; %Degrees
distance = 430000; %Meters
orbit_package = {zenith_ang, distance};

pointing_err = 0;
jitter = 0;
pointing_package = {pointing_err, jitter};

link_package = link_block(ground_sigs, orbit_package,  pointing_package, optics_package); 
beacon_signal_power = link_package{1}; %All in W/m^2
beacon_noise_power = link_package{2};
background_offset_power = link_package{3}; 


tia_outputs = tia_block(link_package, bandwidth, w, df);



%ground_telescope(w); %Handles ground modulation
%atmo_sigs = link_block(ground_sigs, w);
% tia_outputs = tia_block(atmo_sigs, bandwidth, w, df);
% tia_sig = tia_outputs{1};
% tia_noise = tia_outputs{2};
% %signal_processing_block(sigs, w);
% 
% %%
%Converts SNR into an angle
SNR = logspace(-5,10,1000);
%SNR = get_snr(tia_sig, tia_noise, df);
%mag2db(SNR) %Sanity check component. from Theory of tracking accuracy of
%laser systems. eq 62
spot_size = 0.001; %.2mm
var_x = SNR.^-1.*(1-8./SNR)./(1+8./SNR).^2;
dx = spot_size.^2*var_x %denormalized variance. eq 3b
fc = 0.015 %focal distance assuming simple telescope (it's not)
var_theta_II = asin(dx/fc);

display =1;
if(display ==1)
    figure
    hold on;
    o = ones(length(SNR),1)';
    target_angle = 1E-7; %0.1uRad;
    plot(mag2db(SNR),log10(var_theta_II));
    plot(mag2db(SNR),log10(target_angle*o));
    title('SNR of Quad VS. Angular Variance');
    ylabel('Variance, Rad');
    xlabel('SNR, linear');
    legend('Var vs SNR','Target Variance');

end

if(verbose ==1)
    'Angle Variance: '
    var_theta_II
end
    %target_theta = 1E-6;
%tg = ones(1,length(SNR))*target_theta; figure semilogy(mag2db(SNR),
%var_theta_II); title('SNR vs Angular Determination'); xlabel('SNR (dB)')
%ylabel('Radians')
% 
% %'yo?'
