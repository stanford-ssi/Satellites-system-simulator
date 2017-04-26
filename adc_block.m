function adc_outputs = adc_block( signal_levels)
%These are all static voltage levels
%or Vrms of each input. 
input_signal = signal_levels{1};
background_irradiance = signal_levels{3};
input_noise = signal_levels{3};
input_signal = input_signal(1);
background_irradiance = background_irradiance(1);
input_noise = input_noise(1);

global verbose;

safety_factor = 2; 
%Multiplies the max signal by
%this to set the max sampling range.
%safety_factor*total_signal = highest voltage we can measure
%to prevent railing. 

%ADC definition.
v_ref = 3.3;
adc_vals = ltc25000();
enob_adc = adc_vals{1};
thd_adc = adc_vals{2};

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

    voltage_per_division = dynamic_range.*(2.^-enob_adc);
    enob_swept = log2( input_signal ./ voltage_per_division );
    if(verbose)
        figure
        semilogx(background_ranges./input_signal, enob_swept);
        hold on;
        semilogx(background_ranges./input_signal, ones(length(background_ranges),1)'.* enob_adc, '.');
        title('ENOB of Signal, BG Sensitivity Study');
        ylabel('ENOB of Signal w/ Safety factor');    
        xlabel('Ratio of BG irradiance to signal irradiance');
        legend('Signal ENOB', 'Ideal ADC ENOB');
     
        %http://www.analog.com/media/en/training-seminars/tutorials/MT-003.pdf
         %Based on Equations here^
         SINAD = 6.02.*enob_swept + 1.76;
         SNR = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );
         figure
         semilogx(background_ranges./input_signal, SNR);
         hold on;
         title('SNR of Signal, BG Sensitivity Study');
         ylabel('SNR of Signal w/ Safety Factor and Harmonic Distortion');
         xlabel('Ratio of BG irradiance to signal irradiance');
        
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
     title('AC vs Full Coupling of Expected Signal');
     ylabel('ENOB');
     xlabel('Scalars. Dimensionless');
     legend('AC Coupled', 'Background Coupled'); 
     axis([1 10 30 100]);
     subplot(1,2,2);
     hold on;
     plot(a,o.*snr_ac_coupled);
     plot(a,o.*snr_full_coupled);
     ylabel('ENOB');
     xlabel('Scalars. Dimensionless');
     legend('AC Coupled', 'Background Coupled'); 
 end
 

if(verbose)
    'TIA signal enob'
    enob_signal
    'Offset Signal Enob'
    enob_high_dynamic_range
    'AC Coupled Signal Enob'
    enob_ac_coupled
end
adc_outputs = 1; %{signal_power, noise_power, enob};

end
