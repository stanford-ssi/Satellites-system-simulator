%%NOTE:
%Hesitant to use the ads1299 because its meant for eegs and has
%weird biasing inputs and is designed for super low frequency operation.
%assuming that both ltc2500 and the 4 sampling ltc2344 work for noise
%floor reasons, it still might make a lot more sense to use the
%ltc2500 because of the built-in anti-aliasing.



%%ADC Selection Tool.
%Takes input of ADC and expected signal levels.
%Gives ADC SNR. Allows for easy decision making if this ADC is below noise floor. 
%All values are in Vrms, not Vp-p.
%Noise is in V/rt(Hz)
clear all
global v_ref;

total_current = 7.5876e-08 %Scenario 0
total_current = 7.7324e-08 %Scenario 2

%%
%SIMULATION PARAMETERS:
%Most of these values should be taken from other simulations present in
%this package (system_scratchpad). They are hard coded here to make it play better with other
%non-this systems. 

v_signal = 1.7133e-04; %Worst case (far) visibility. 0.5mRad beam div ...
                        %1000km, 500k Rf. Responsivity=0.62W/A. 
%v_signal = 9.7830e-04; %Best case. Scenario=2. Same as above^ 

v_signal = v_signal*10; %10x gain from inverter or ADC driver

v_tia_noise_hz = 3.1E-6/sqrt(5E3); %From LT spice, validated experimentally. Rf=500k, ADA4530 opamp. 
v_shot_noise_hz = 7.7964e-08; %From background light, beacon, dark current, through Rf=500k.
v_noise_other = 0; %Just in case

v_noise_hz = sqrt(v_tia_noise_hz^2 + v_shot_noise_hz^2 + v_noise_other);

snr_preadc = mag2db(v_signal/v_noise_hz);

sample_rate = 4E3; %4kSps per channel for the FFT.
buffer_size = 32; %32 Samples per digital processing step.
fft_bin_width = sample_rate/buffer_size
fft_gain = 10*log10(buffer_size/2)
%NOTE: fft_gain is how many db below rms-quantization floor you can see a
%signal.
%rms_quant noise is what is spec'd on a system's snr.
%steps: 1.) take snr. S is full signal range. use to find N.
%       2.) take n, subtract fft_gain, that's the fft noise floor.
%       3.) take known beacon_s and find SNR vs beacon/fft_noise_floor.
       


%%
%ADC SPECS:
ADC_name = 'ADS1299';
i = 1
v_ref = 4.5;
adc_snr = 121;
dBF = -2;
adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor(i) = adc_max_sig/db2mag(adc_snr);
fft_floor(i) = mag2db(adc_floor(i))-fft_gain;
snr_adc(i) = mag2db(v_signal)-fft_floor(i);



ADC_name = 'LTC2344';
i =2;
v_ref = 4.096;
adc_snr = 95;
dBF = -1;
adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor(i) = adc_max_sig/db2mag(adc_snr);
fft_floor(i) = mag2db(adc_floor(i))-fft_gain;
snr_adc(i) = mag2db(v_signal)-fft_floor(i);

ADC_name = 'LTC2344';
i =3;
v_ref = 2.048;
adc_snr = 83.3;
dBF = -1;
adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor(i) = adc_max_sig/db2mag(adc_snr);
fft_floor(i) = mag2db(adc_floor(i))-fft_gain;
snr_adc(i) = mag2db(v_signal)-fft_floor(i);


ADC_name = 'LTC2500';
i=4
v_ref = 5;
adc_snr = 104;
dBF = -1;
adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor(i) = adc_max_sig/db2mag(adc_snr);
fft_floor(i) = mag2db(adc_floor(i))-fft_gain;
snr_adc(i) = mag2db(v_signal)-fft_floor(i);

ADC_name = 'ADA131A02';
i = 5;
v_ref = 2.442;
adc_snr = 115;
dBF = -20;
adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor(i) = adc_max_sig/db2mag(adc_snr);
fft_floor(i) = mag2db(adc_floor(i))-fft_gain;
snr_adc(i) = mag2db(v_signal)-fft_floor(i);



adc_floor
snr_adc

%%
%RUN SIMULATION
ENOB=-1
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


adc_max_sig = db2mag((mag2db(v_ref)-dBF)); %Typically reference adc signals are applied at 1dB (1dBF) below the max voltage to avoid the worst of the distortion.
adc_floor = adc_max_sig/db2mag(adc_snr)
snr_adc2 = mag2db(v_signal/adc_floor) 