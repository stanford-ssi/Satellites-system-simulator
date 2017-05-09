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
global calib_power;
global calib_spot;
calib_spot = 0.004/2; %4mm diameter
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
Rf = 200E3;
verbose = 0;

%%
%========================================================
%PGA mode vs pure ADC Testground
    dark_curr = 4E-9;% 4nA
    bandwidth = 5E3;
    responsivity = .72; 
    link_package = link_block(); 
    link_package{1} = link_package{1}/4;
    link_package{2} = link_package{2}/4;
    link_package{3} = link_package{3}/4;
    link_package{4} = link_package{4}/4;
    total_optical = (link_package{1}+link_package{2}+link_package{3});
    q = 1.60217662E-19; %TODO, HOW to actually do shot noise. This is an educated guess.
    ns = ( 2*q*(dark_curr + ((total_optical)*responsivity))*bandwidth)^0.5 *Rf ;
       
    %% 
    %Pure ADC, LTC 2500;
    enob_adc = 16.8172;
    vpd = v_ref*2^(-enob_adc);
    
    noise_tia = 12.945E-6;
    noise_tia = 24.9E-6;
    
    noise_shot = ns;
    noise_adc = vpd/(12^0.5); % %LTC2500-df256 spec'd this for 4ksps.
    signal = link_package{1}*Rf*0.72;
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2);
    max_v = total_optical*Rf*0.72+dark_curr*Rf;
    snr_pure = mag2db(signal/noise)
    %%
    %With pure Teensy
    enob_adc = 14.5;
    vpd = v_ref*2^(-enob_adc);
    
    
    noise_tia = 24.9E-6;
    noise_shot = ns;
    noise_adc = vpd/(12^0.5);
    noise_filter = 535E-9; %@5kHz From Analog Filter wizard http://www.analog.com/designtools/en/filterwizard/
    
    
    signal = link_package{1}*Rf*0.72;
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2+noise_filter^2);
    snr_Teensy = mag2db(signal/noise)
    
    %%
    %With PGA's and Filters (and Blackjack)
    enob_adc = 14.5;
    vpd = v_ref*2^(-enob_adc);
    
    
    pga_gain = 250;
    noise_tia = pga_gain * 24.9E-6;
    noise_shot = pga_gain * ns;
    noise_adc = vpd/(12^0.5);
    noise_filter = pga_gain * 535E-9; %@5kHz From Analog Filter wizard http://www.analog.com/designtools/en/filterwizard/
    noise_pga = sqrt((8.7E-9*5)^2 + (12E-9)^2)*bandwidth; %Staggered because it's actually two 50*5 pga's http://cds.linear.com/docs/en/datasheet/6910123fa.pdf
    
    
    signal = link_package{1}*Rf*0.72*pga_gain;
    noise = sqrt(noise_tia^2+noise_shot^2+noise_adc^2+noise_filter^2+noise_pga^2);
    max_v = ((link_package{1}+link_package{2}+link_package{3})*Rf*0.72+dark_curr*Rf)*pga_gain;
    snr_filters = mag2db(signal/noise)


