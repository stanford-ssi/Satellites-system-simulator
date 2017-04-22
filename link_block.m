
function output_package= link_block(sigs, orbit_package, pointing_package, optics)
    %Simulates effect of first half of link. Includes laser transmitter, to
    %pointing, to atmospheric effects. Outputs a
    %time-domain attenuated signal for irradiance W/m^2 at aperture, noise signal,
    %and subsequent power levels. 
    
    %signals are all assumed to be time-domain signals. Inputs should be 
    %normalized. WARNING: THIS IS IN CONFLICT WITH TIA_BLOCK, WHICH ASSUMES
    %FREQUENCY DOMAIN SIGNALS. PROPER CONVERTION IS NECASSARY IN
    %SYSTEMMASTER.

    %Several times in this simulation an OPALS paper is mentioned. It is
    %universally the "Optical Payload for Lasercomm Science (OPALS) Link
    %Validation During Operations from the ISS" paper.
    
    global verbose
    global best_case
    time = sigs{1}; %seconds
    signal_tx = sigs{2}; %unitless amplitude.
    noise_tx = sigs{3}; %unitless amplitude.
    %^These are currently not implemented. Do something with them later. 
    
    signal_power = sigs{4};
    noise_power = sigs{5};
    
    op_filter_bandwidth = optics{1}; %bandwidth of notch filter 976;
    %op_filter_bandwidth = 11.2E-9; %m. From Opals. "LINK DESIGN AND VALIDATION" pg 6;
    
    zenith_ang = orbit_package{1}/180*pi; %Converts to radians
    distance = orbit_package{2}; %convert km to meters
    
    %Neither of these have been implemented yet.
    %Requires better propogation with gaussian beam and better
    %understanding of optics. Get jitter from Hammati and gaussian from 
    %the lecture slides?
    point_err = pointing_package{1}; 
    jitter = pointing_package{2};
 
    %transmitted signal should be normalized to 0-1 range.
    %% System Parameters:
    %Warning: Divergance angle taken as full width of beam. So the
    %triangular angle of the div_angle is half the value reported.
    %Transmitter from OCTL:
    laser_tx_power = 1.6; %Watts
    tx_divergance_angle = 1.5E-3; %1.5mRad 
    
    laser_tx_power = 9.25;
    laser_tx_power = 1.6; %Watts
    laser_tx_power = 9.25 *.86; %*db2mag(-4.4);
    %Geometeric Decay Of Laser
    cone_radius = distance.*tan(tx_divergance_angle/2);
    spot_size = (pi*(cone_radius.^2)); 
    ideal_power_at_satellite = laser_tx_power./spot_size;
    %OR--- Interpolating from OPAL's Link budget. Assuming 1.1mRad.
    if(tx_divergance_angle == 1.1E-3)                
        ideal_power_at_satellite = 4E-5/ (430000).^2 .*( distance.^2);
    end
    if(tx_divergance_angle == 1.5E-3)                
        ideal_power_at_satellite = 2.2E-5/ (430000).^2 .*( distance.^2);
    end
    geometeric_signal = ideal_power_at_satellite.*signal_power;
    if((tx_divergance_angle ~= 1.1E-3) & (tx_divergance_angle ~=1.5E-3)) 
        Warning_DIV_ANGLE_NOT_SUPPORTED; %Currently, the propogator only works with 1.1mRad b/c it steals
    end
    %Weirdly, getting different answers for ideal transmission
    
    %Atmosphereic Transfer Function for Laser
    %This should be simulated with MODTRAN, a $1500 yearly piece of
    %software. I've interpolated the attenuation graph from OPALS "Optical
    %Payload for Lasercom..." Fig 2.b.
    air_mass = 1./( cos(zenith_ang) + 0.50572.*(6.07995 + 90-zenith_ang).^-1.6364);
    %^Uses Kasten and Young Model to calculate air_mass. See Opals Paper
    %eq(1). section 2.1
    attenuation = rural_23km_cloudy_model(air_mass);
    %Rural_20km fit Opal's mission the best. 
    atmo_variance = 0.3; %Taken from Opals paper
    if(best_case)
        attenuation = desert_ext_model(air_mass);
        atmo_variance = 1E-2;    
        %Best case, it's 1E-2
        %worst case, it's 0.3 of the range.
    end
    atmo_signal = geometeric_signal.*db2mag(attenuation); %signal after
    %atmospheric atetenuation.
    %Based on here: https://en.wikipedia.org/wiki/White_noise
    %Power_i for all spectrum i  = variance;
    level = rms(atmo_signal); %This can't be right. Purely because the other one was too low of answers.
    atmo_noise = level*atmo_variance; %This is noise power. W/rt(Hz)
    %Todo; this one is beyond me. 
%     variance = level*atmo_variance; %b/c the number from OPALS was normalized.
%     atmo_noise = variance.^.5*randn(length(atmo_signal),1);    
%     %Todo: should 'level' be rms or mean? Did Opals Normalize variance to
    %signal mean or signal power? Signal mean seems more culturally common.
    %based off equation found under 'alternative definition':
    %https://en.wikipedia.org/wiki/Signal-to-noise_ratio
  
    background_radiant_intensity = 0.013;% W/cm^2/sr/um Units of radiant intensity. Which is angular
     %flux by wavelength (um), with an extra area term (cm^2) in there. 
     %in LEO, the Earth subtends a solid angle of ~2Pi (D'Amico's experiment paper).
     %Therefore;
    op_filter_bandwidth = 11.2E-9; %m. From Opals. "LINK DESIGN AND VALIDATION" pg 6;
    HFOV = 1/180*pi; %1 degree.
    SR_HFOV = 2*pi*(1-cos(HFOV));
    atmo_background = background_radiant_intensity*SR_HFOV*((1/100).^2) *1E-6/op_filter_bandwidth; 
    aperture_flux = atmo_background*(pi*aper_radius.^2);
    %W/m^2 (for our bw) =  W/cm^2/sr/um            * sr *   (cm/m).^2 * um/m (spectrum)
    %This should technically change with altitude. Todo; add Earth Subtend
    %for solid angle at our altitude.
             
    %%Pointing
    %
    pointed_signal = atmo_signal; %Perfect pointing.
    %TODO: Not implemented yet
    %Todo: Add pointing noise.
    
    %%
    %Putting it all together
    total_signal = pointed_signal;
    total_noise = atmo_noise;% + atmo_background; Not including background, treating that as a DC offset. 
    total_bg = atmo_background; 
    
    
    if(verbose)
        figure;
        hold on;
        t = linspace(1,100);
        o = ones(length(t),1)';
        plot(t, mag2db(o.*rms(geometeric_signal)));
        plot(t, mag2db(o.*rms(atmo_signal)));
        plot(t, mag2db(o.*(rms(atmo_noise)))); %+atmo_background.^2).^0.5));
        plot(t, mag2db(o.*rms(atmo_background)));
        
        title('Atmospheric Effects');
        legend('Signal After Propogation Loss',...
            'Signal After Atmospheric Loss',...
            'Total Atmo-Noise',...
            'Atmospheric Background Irradiance');
    end
    
    output_package = {total_signal , total_noise, total_bg};
end


