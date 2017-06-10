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
global tx_divergance_angle;
global spot_diam; %size of spot on quad cell in meters 
spot_diam = 0.00025;
global focal_dist; %Focal distance
focal_dist = 10E-3; 

tx_divergance_angle = 0.5E-3; %500uRad
%tx_divergance_angle = 1.1E-3; %1.1mRad
global LT_SPICE; %Whether to use LT-spice sims for TIA. (You probably should)
global Rf;
global v_ref;
global safety_factor;
global Cf; %updated Automatically in TIA block.
LT_SPICE = 0;
safety_factor = 2;
v_ref = 5;
verbose = 0;

%%


opamp = 'ADA4530';
Rf = 200E3;
noise_tia = 2E-6;

opamp = 'ADA4530';
Rf = 20E3;
noise_tia = 821E-9;

opamp = 'OPA657';
Rf = 400E3; %
noise_tia = 4*12.5E-6;

opamp = 'ADA4530';
Rf = 200E3;
noise_tia = 2E-6;

opamp = 'ADA4530';
Rf = 100E3; %
noise_tia = 1.48E-6;




opamp = 'ADA4530';
Rf = 6.28E3;
noise_tia = 643E-9;

opamp = 'OPA657';
Rf = 500E3; %
noise_tia = 5*12.5E-6;

opamp = 'ADA4530';
Rf = 5E6; %
noise_tia = 6.5E-6;

opamp = 'ADA4530';
Rf = 500E3; %
noise_tia = 3.1E-6;

opamp = 'OPA657';
Rf = 500E3; %
noise_tia = 14.9E-3; %5*12.5E-6;

opamp = 'OPA657';
Rf = 100E3; %
noise_tia = 12.5E-6;

opamp = 'OPA657';
Rf = 5E6; %
noise_tia = 15E-3; 
responsivity = 0.62

opamp = 'OPA657';
Rf = 500E3; %
noise_tia = 12.5E-6;
responsivity = 0.62
filtered_tia_noise = 3.9E-6; 

opamp = 'ADA4530';
Rf = 500E3; %
noise_tia = 3.1E-6;
filtered_tia_noise = 432E-9; 

%========================================================
%PGA mode vs pure ADC Testground
    dark_curr = 4E-9;% 4nA
    bandwidth = 5E3;
%   responsivity = .72; 
    link_package = link_block(); 
    link_package{1} = link_package{1}/4;
    link_package{2} = link_package{2}/4;
    link_package{3} = link_package{3}/4;
    link_package{4} = link_package{4}/4;
    total_optical = (link_package{1}+link_package{2}+link_package{3});
    
%   total_optical = 10E-6;
%   link_package{1} = 10E-6;
    
    
    q = 1.60217662E-19; %TODO, HOW to actually do shot noise. This is an educated guess.
    ns = ( 2*q*(dark_curr + ((total_optical)*responsivity))*bandwidth)^0.5 *Rf ;
       
 
    %Pure ADC, LTC 2500;
    enob_adc = 16.8172;
    vpd = v_ref*2^(-enob_adc);
    
    
    df = 64; 
    
    noise_shot = ns;
    noise_adc = vpd/(12^0.5)/df; % %LTC2500-df256 spec'd this for 4ksps.
    
    signal = link_package{1}*Rf*responsivity
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    max_v = total_optical*Rf*responsivity+dark_curr*Rf;
    snr_pure = mag2db(signal/noise)
    
    n = 10;
    o = ones(n,1)';
    l = linspace(1,4,n);
    figure    
    loglog(l,o*signal,'d');
    hold on;
    loglog(l,o*noise_tia);
    loglog(l,o*noise_shot);    
    loglog(l,o*noise_adc);
    legend('SIGNAL','TIA NOISE', 'SHOT NOISE','ADC NOISE');
    title([opamp, ', Rf:', num2str(Rf), ', ADC: LTC2500']);
    ylabel('Vrms Voltage Noise');
    xlabel('Scalars');

%%

    
    %and again, but with DSP cutoff. 
    signal = link_package{1}*Rf*responsivity;
    noise_tia = filtered_tia_noise; %Vrms for the 937-1064 bw.
    noise_shot= noise_shot*125/bandwidth;
    noise_adc= noise_adc*125/bandwidth;
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    max_v = total_optical*Rf*responsivity+dark_curr*Rf;
    snr_dsp = mag2db(signal/noise)
    
    n = 10;
    o = ones(n,1)';
    l = linspace(1,4,n);
    figure    
    loglog(l,o*signal,'d');
    hold on;
    loglog(l,o*noise_tia);
    loglog(l,o*noise_shot);    
    loglog(l,o*noise_adc);
    legend('SIGNAL','TIA NOISE', 'SHOT NOISE','ADC NOISE');
    title(['Post DSP Values for ', opamp, ', Rf:', num2str(Rf), ', ADC: LTC2500']);
    ylabel('Vrms Voltage Noise');
    xlabel('Scalars');

    angle_tia = noise_to_angle(signal,noise_tia,spot_diam,focal_dist);
    angle_shot = noise_to_angle(signal,noise_shot,spot_diam,focal_dist);
    angle_adc = noise_to_angle(signal,noise_adc,spot_diam,focal_dist);
    if(verbose == 1)
        'Noise Angles mRad'
        angles = [angle_tia, angle_shot, angle_adc]
    end
    
 %%  
    %Converts SNR into an angle
    beacon_power = logspace(-10, -7, 1000); 
    signal = beacon_power.*Rf.*responsivity;
    noise_tia = filtered_tia_noise; %Vrms for the 937-1064 bw.
    noise_shot= ns*125/bandwidth;
    noise_adc = vpd/(12^0.5)*125/bandwidth;
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    max_v = total_optical*Rf*responsivity+dark_curr*Rf;
    snr_dsp = (signal./noise)    
    SNR = snr_dsp;   
    
    
   
    std_theta_II = noise_to_angle(signal,noise_adc,spot_diam,focal_dist);
    
    figure
    semilogy(10*log10(SNR),std_theta_II);
    title('SNR vs Theta Standard Deviation');
    xlabel('SNR');
    ylabel('Radians');

    
    figure
    loglog(beacon_power, std_theta_II);
    %semilogx(beacon_power, var_theta_II);
    title('Beacon Power vs Angular Determination of our designed system');
    xlabel('Optical Power, Watts');
    ylabel('Radians');

    figure
    loglog(beacon_power, mag2db(SNR));
    %semilogx(beacon_power, var_theta_II);
    title('Beacon Power vs SNR');
    xlabel('Optical Power, Watts');
    ylabel('SNR');

    