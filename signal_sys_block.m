function system_outputs = signal_sys_block( sigs_best, sigs_worst, sigs_calib)
%These are all static voltage levels
%or Vrms of each input. 

signal_best = sigs_best{1};
noise_best = sigs_best{2};
background_best= sigs_best{3};

signal_worst = sigs_worst{1};
noise_worst = sigs_worst{2};
background_worst= sigs_worst{3};

signal_calib = sigs_calib{1};
noise_calib = sigs_calib{2};
background_calib= sigs_calib{3};

%Power on SINGLE DIODE. not total power. The 1/4 happens in TIA land.


global verbose;

safety_factor = 2; 
%Multiplies the max signal by
%this to set the max sampling range.
%safety_factor*total_signal = highest voltage we can measure
%to prevent railing.  

%ADC definition.
global v_ref
%adc_vals = ltc25000();
adc_vals = mk66_avg4();
enob_adc = adc_vals{1};
thd_adc = adc_vals{2};
adc_name = adc_vals{3};


%%
%SNR for our signal across best and worst case scenarios.
%Determines if we need to perform in flight gain adjustments.

%AC coupled:
    total_inp_voltage = signal_best + noise_best;
    dynamic_range = total_inp_voltage.*safety_factor; %Safety factor to prevent railing. 
    voltage_per_division = dynamic_range.*(2.^-enob_adc);
    enob_best = log2( signal_best ./ voltage_per_division );
    SINAD = 6.02.*enob_best + 1.76;
    snr_best = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );
    gain_best = v_ref/dynamic_range;
    enob_worst = log2( signal_worst ./ voltage_per_division );
    SINAD = 6.02.*enob_worst + 1.76;
    snr_worst = -10*log10(10.^(-SINAD./10) - 10.^(thd_adc/10) );
    sigs_ratio = signal_best/signal_worst;
    
    
system_outputs = 1;


end
