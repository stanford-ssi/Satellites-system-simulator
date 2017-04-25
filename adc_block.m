function adc_outputs = adc_block( signal_levels)
%These are all static voltage levels
%or Vrms of each input. 
input_signal = signal_levels{1};
offset_signal = signal_levels{3};
input_noise = signal_levels{3};
input_signal = input_signal(1);
offset_signal = offset_signal(1);
input_noise = input_noise(1);

global verbose;

safety_factor = 2; 
%Multiplies the max signal by
%this to set the max sampling range.
%safety_factor*total_signal = high voltage we can measure
%to prevent railing. 

%ADC definition.
v_ref = 3.3;
enob_adc = ltc25000();

%Simulation from TIA signals. Probably not what you want.
voltage_per_division = v_ref*(2.^-enob_adc);
%V/1bit;
enob_signal = log2(input_signal/(voltage_per_division));

background_ranges = logspace(-5,2)*input_signal;
%Now, assume we've got some amount of a gain stage
%that boosts our voltages to as high as we could without railing.
total_inp_voltage = input_signal + offset_signal +  input_noise;
dynamic_range = total_inp_voltage*safety_factor; %Safety factor to prevent railing. 
voltage_per_division = dynamic_range*(2.^-enob_adc);
enob_high_dynamic_range = log2( input_signal / voltage_per_division );

%Now, assume we've AC coupled, and get full dynamic range on our signal.
dynamic_range = input_signal * safety_factor;
voltage_per_division = dynamic_range*(2.^-enob_adc);
enob_ac_coupled = log2(input_signal /voltage_per_division);

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
