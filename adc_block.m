function adc_outputs = adc_block( signal_levels)
%These are all static voltage levels
%or Vrms of each input. 
input_signal = signal_levels{1};
input_noise = signal_levels{4}; %{4}: Purely noise from TIA.
background_irradiance = signal_levels{3};

global verbose;
global v_ref;
global safety_factor;
global snr_target;
needed_signal = snr_target;
%safety_factor = 2; 
%Multiplies the max signal by
%this to set the max sampling range.
%safety_factor*total_signal = highest voltage we can measure
%to prevent railing.  

%ADC definition.
%v_ref = 3.3;
%adc_vals = ltc25000();
adc_vals = mk66_avg32();
adc_vals = ltc2500_df256();
enob_adc = adc_vals{1};
thd_adc = adc_vals{2};
adc_name = adc_vals{3};
adc_noise = adc_vals{4};
adc_DF = adc_vals{5};

%%
%Calculation of TIA noise floor 
%compared to ADC's noise floor
    vpd = v_ref*2^(-enob_adc);
    adc_floor = vpd/(adc_DF/2); %The divide by DF/2 is for downsample process gain.
    needed_tia_floor = db2mag(10)*adc_floor; %TIA noise floor should be 10db higher than ADCS
    %If tia noise is greater than above NTF; adc noise won't matter or
    %contribute to the noise of the system.
    
    %Steps: FIND needed NOISE_FLOOR for TIA
    %Iterate on Rf in LTSpice to find RF that  gives that. Use it
    %Calculate System noise with that value
    %double check that calib laser works.
    %Check SNR value is above what we need.
    

%%
%No PGA's, just take it straight:
    vpd = v_ref*2^(-enob_adc);
    enob_pure = log2(input_signal/vpd);
    needed_gain = needed_signal/input_signal;
    SINAD = 6.02.*enob_pure + 1.76;
    snr_pure = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10)) +mag2db(adc_DF/2);
    
%%Input signal simulation assuming PGA maximizing dynamic range.
%
    total_inp_voltage = input_signal + background_irradiance + input_noise;
    signal_dr = total_inp_voltage.*safety_factor; %Safety factor to prevent railing. 
    pga_gain = mag2db(v_ref ./ signal_dr);
    sim_vpd = signal_dr.*(2.^-enob_adc);
    enob_signal = log2( input_signal ./ sim_vpd );
    sqnr_signal = 20*log10(2.^enob_signal); %https://en.wikipedia.org/wiki/Signal-to-quantization-noise_ratio 
    simmed_ratio = background_irradiance/input_signal;
    sim_quant_noise = sim_vpd/(12^0.5);

%Simulation from TIA signals. Probably not what you want.
voltage_per_division = v_ref*(2.^-enob_adc);
%V/1bit;
enob_signal = log2(input_signal/(voltage_per_division));

%%Varying BG Irradiance Sensitivity Study
    %%Goal: find exactly how much of a design challenge
    %BG irradiance poses to our design. If we float our 
    %signal ontop of a very large offset, we'll lose some
    %dynamic range. How much does it effect us? 

    background_ranges = logspace(-5,4)*input_signal; %Background ranges from 
    %1E-5 smaller to 1E2 larger than our input signal.

    %Assume we've got some amount of a gain stage
    %that boosts our voltages to as high as we could without railing.
    total_inp_voltage = input_signal + background_ranges;%input_noise -no noise in this study.
    dynamic_range = total_inp_voltage.*safety_factor; %Safety factor to prevent railing. 
    gains = v_ref ./ dynamic_range;
    
    voltage_per_division = dynamic_range.*(2.^-enob_adc);
    enob_swept = log2( input_signal ./ voltage_per_division );
    %%
    %
    if(verbose)
        figure
        semilogx(background_ranges./input_signal, enob_swept);
        hold on;
        semilogx(background_ranges./input_signal, ones(length(background_ranges),1)'.* enob_adc, '.');
        title(['ENOB of Signal, BG Sensitivity Study, ', adc_name] );
        ylabel('ENOB of Signal w/ Safety factor');    
        xlabel('Ratio of BG irradiance to signal irradiance');
        legend('Signal ENOB', 'Ideal ADC ENOB');
     
        %http://www.analog.com/media/en/training-seminars/tutorials/MT-003.pdf
         %Based on Equations here^
         SINAD = 6.02.*enob_swept + 1.76;
         SNR = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );
         %under 'digital signals': https://en.wikipedia.org/wiki/Signal-to-noise_ratio
         snr_bits = 20*log10(2.^enob_swept);
         snr_np = mag2db( (input_signal.^2 ./ (voltage_per_division)));
         figure
         semilogx(background_ranges./input_signal, SNR);
         hold on;
         semilogx(background_ranges./input_signal, snr_bits);
         semilogx(background_ranges./input_signal, snr_np);
         semilogx(background_ranges./input_signal, mag2db(gains), '-.');
         semilogx(simmed_ratio, sqnr_signal, '*');
         semilogx(simmed_ratio, pga_gain, '*');
         title(['SNR of Signal, BG Sensitivity Study, ', adc_name]);
         ylabel('SNR of Signal w/ Safety Factor and Harmonic Distortion');
         xlabel('Ratio of BG irradiance to signal irradiance');
         legend('SNR with THD', 'SNR of Uniform Distribution','SNR via SigRms^2/One Quant Level','PGA gain required (dB)','Op Point SQNR', 'Op Point PGA Gain');
    
         
    end
%%The ENOB for two different domains given our simulated values.    
%%SNR from ENOB calcs found here; %http://www.analog.com/media/en/training-seminars/tutorials/MT-003.pdf
%%Fully-Coupled. BG irradiance included:
    total_inp_voltage = input_signal + background_irradiance +  input_noise;
    dynamic_range = total_inp_voltage.*safety_factor; %Safety factor to prevent railing. 
    voltage_per_division = dynamic_range.*(2.^-enob_adc);
    enob_full_coupled = log2( input_signal ./ voltage_per_division );
    SINAD = 6.02.*enob_full_coupled + 1.76;
    snr_full_coupled = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );
%%AC-Coupled. BG irradiance removed. 
    dynamic_range = input_signal * safety_factor;
    voltage_per_division = dynamic_range*(2.^-enob_adc);
    enob_ac_coupled = log2(input_signal /voltage_per_division);
    SINAD = 6.02.*enob_ac_coupled + 1.76;
    snr_ac_coupled = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );

if(verbose)
    %Plots of AC coupled vs full Coupled signal SNRs. 
     a = linspace(1,10);
     o = ones(length(a),1)';
     figure
     hold on;
     subplot(1,2,1);
     hold on;
     plot(a,o.*snr_ac_coupled);
     plot(a,o.*snr_full_coupled);
     ylabel('SNR');
     xlabel('Scalars. Dimensionless');
     legend('AC Coupled', 'Background Coupled'); 
     axis([1 10 30 100]);
     subplot(1,2,2);
     hold on;
     plot(a,o.*snr_ac_coupled);
     plot(a,o.*snr_full_coupled);
     ylabel('SNR');
     xlabel('Scalars. Dimensionless');
     legend('AC Coupled', 'Background Coupled'); 
     title(['AC v DC Coupling, ',adc_name]);
     
end
 
total_inp_voltage = input_signal + background_irradiance + input_noise;
    signal_dr = total_inp_voltage.*safety_factor; %Safety factor to prevent railing. 
    pga_gain = mag2db(v_ref ./ signal_dr);
    sim_vpd = signal_dr.*(2.^-enob_adc);
    enob_signal = log2( input_signal ./ sim_vpd );
    sqnr_signal = 20*log10(2.^enob_signal); %https://en.wikipedia.org/wiki/Signal-to-quantization-noise_ratio 
    simmed_ratio = background_irradiance/input_signal;
    sim_quant_noise = sim_vpd/(12^0.5);

output_signal = input_signal*pga_gain;
output_noise =  ((input_noise*pga_gain).^2 + (sim_quant_noise).^2).^0.5;

if(verbose)
   'PGA Gain:'
   pga_gain
   'ENOB Signal:'
   enob_signal
   'SNR to this point:'
   full_snr = snr(output_signal, output_noise);
   full_snr
   'Background Irradiance Ratio:'
   simmed_ratio
end

adc_outputs = {output_signal, output_noise, pga_gain, enob_signal};



end
