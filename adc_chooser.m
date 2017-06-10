%Go HERE: D:\References\Datasheets Technical documents\adc


%%ADC Selection Tool.
%Takes input of ADC and expected signal levels.
%Gives ADC SNR. Allows for easy decision making if this ADC is below noise floor. 
%All values are in Vrms, not Vp-p.
%Noise is in V/rt(Hz)
clear all
global v_ref;
%%
%ADC SPECS:



ADC_name = 'LTC2500';
v_ref = 5;
SINAD = 104; %dB;
ENOB = -1; %Note, use either SINAD, OR ENOB. Not both. Flag enob w/ -1
DOWNSAMPLE_FACTOR = 64;

ADC_name = 'LTC2344';
v_ref = 5;
SINAD = 95; %dB;
ENOB = -1; %Note, use either SINAD, OR ENOB. Not both. Flag enob w/ -1
DOWNSAMPLE_FACTOR = 0;


%%
%SIMULATION PARAMETERS:
%Most of these values should be taken from other simulations present in
%this package (system_scratchpad). They are hard coded here to make it play better with other
%non-this systems. 

v_signal = 1.7133e-04; %Worst case (far) visibility. 0.5mRad beam div ...
                        %1000km, 500k Rf. Responsivity=0.62W/A. 
%v_signal = 9.7830e-04; %Best case. Scenario=2. Same as above^ 
    
v_tia_noise_hz = 3.1E-6/sqrt(5E3); %From LT spice, validated experimentally. Rf=500k, ADA4530 opamp. 
v_shot_noise_hz = 7.7964e-08; %From background light, beacon, dark current, through Rf=500k.
v_noise_other = 0; %Just in case

v_noise_hz = sqrt(v_tia_noise_hz^2 + v_shot_noise_hz^2 + v_noise_other);


%%
%RUN SIMULATION
if( ENOB == -1)
    %Using this equation:https://en.wikipedia.org/wiki/Effective_number_of_bits
    ENOB = (SINAD-1.76)/6.02;
end
vpd = v_ref*2^(-ENOB);
df = DOWNSAMPLE_FACTOR; 
df_gain = 10^(6/20)*(df/4); %df gives 6dB snr per 4x downsample. 
if(df_gain == 0)
    df_gain = 1;
end

noise_power_adc = vpd/(12^0.5)/df_gain; %Per rt Hertz.

noises = [v_noise_hz, noise_power_adc];
snr_total = 20*log10(v_signal/sqrt( noise_power_adc^2 + v_noise_hz^2)/20); %Voltage dB. 2X
snr_adc = 20*log10((v_signal/noise_power_adc)/20); %Voltage dB. 20log10();

snr_total
snr_adc

n = 10;
o = ones(n,1)';
l = linspace(1,4,n);
figure    
loglog(l,o*v_signal,'d');
hold on;
loglog(l,o*v_tia_noise_hz);
loglog(l,o*v_shot_noise_hz);    
loglog(l,o*noise_power_adc);
legend('SIGNAL','TIA NOISE', 'SHOT NOISE','ADC NOISE');
title(['ADA4500', ', Rf: 500k', ', ADC: ', ADC_name]);
ylabel('V/rt(Hz) Voltage Noise');
xlabel('Scalars');


adc_max_sig = db2mag((mag2db(v_ref)-1))
adc_floor = adc_max_sig/db2mag(adc_snr)
snr_adc2 = adc_floor 