%%SSI Link Budget.
% Michael Taylor
% Jake Hillard
 
function output_package= link_block()
    %Simulates effect of first half of link. Includes laser transmitter, to
    %pointing, to atmospheric effects. Outputs a
    %rms power levels attenuated signal for irradiance W/m^2 at aperture, noise signal,
    
    %signals are all assumed to be time-domain signals. Inputs should be 
    %normalized. WARNING: THIS IS IN CONFLICT WITH TIA_BLOCK, WHICH ASSUMES
    %FREQUENCY DOMAIN SIGNALS. PROPER CONVERTION IS NECASSARY IN
    %SYSTEMMASTER.

    %Several times in this simulation an OPALS paper is mentioned. It is
    %universally the "Optical Payload for Lasercomm Science (OPALS) Link
    %Validation During Operations from the ISS" paper.
    
    global verbose
    global scenario
    global tx_divergance_angle
    %tx_divergance_angle = 0.5E-3; %100uRad 
    
    
    if(scenario == 2)
        orbit_dist = 575e3; % distance straight overhead 0deg zenith ~600km
        zenith_ang = 0;
    end
    if(scenario == 0)
        orbit_dist = 1000e3; % max distance at 65deg zenith ~1000km
        zenith_ang = 65/180*pi; 
    end
    
    Ptx = 9.25; % 9.25 W out
    Ltx = 10^(-4.4/10); % 4.4dB optical loss out of beacon telescope.
    
    %% System Parameters:
    % Parameters
    T = 300;
    k = 1.38065e-23;
    q = 1.602e-19;

    % Background upwelling radiance
    B_lambda_976 = 0.013; % worst case earth reflection
    %orbit_dist = 575e3; % distance straight overhead 0deg zenith ~600km
    
        
    % Beacon Transmit Characteristics
    lambda_tx = 976e-9; % 976nm beacon from JPL
    div_tx_e2 = tx_divergance_angle; % 1.1mrad FW1/e^2 beam div.
    div_tx = div_tx_e2; % shorter var name, can swap with HWHM if added later.
    Ptx_eff = Ptx*Ltx;

    % Receiver Characteristics
    r_rx = 25e-3; % 25mm.
    A_rx = pi*r_rx.^2;
    A_rx_eff = A_rx*3/4; % Secondary mirror of telescope blocks ~1/4th of useable aperture area
    A_rx_eff_cm2 = A_rx_eff*10000; % Receiver effective area in cm^2
    theta_HFOV_deg = 1; % Half Field of View in degrees
    theta_HFOV_rad = theta_HFOV_deg*pi/180;
    solid_angle_rx = 2*pi*(1-cos(theta_HFOV_rad)); % Receiver FOV solid angle
    delta_lambda_opt_um = 0.01; % 10nm optical filter
    Lrx = 10^(-3/10); % 3db optical loss in Rx

    % Calculate background radiance
    P_background = B_lambda_976*solid_angle_rx*A_rx_eff_cm2*delta_lambda_opt_um;

    % Background Intensity at aperture
    I_background = P_background/A_rx_eff;

    % Beacon Intensity at aperture
    r_spot = (div_tx/2)*orbit_dist;
    A_spot = pi*r_spot.^2;
    I_spot = 2*0.86*Ptx_eff/A_spot; % x2 for gaussian peak vs avg scaling

    Lpoint = 10^(-3/10); % 3dB pointing / jitter loss

    Prx_ap = I_spot*A_rx_eff; % Power available at receiver aperture
    Prx = Prx_ap*Lrx*Lpoint; % Power collected by receiver aperture (incl losses)

    Prx_bg = I_background*A_rx_eff; % Background power at receiver aperture
    Pbg = Prx_bg*Lrx*Lpoint; % BG Power collected by receiver aperture (incl losses)

    if(verbose)
        Prx
        Pbg
        r_spot
    end


    %Weirdly, getting different answers for ideal transmission
    
    %Atmosphereic Transfer Function for Laser
    %This should be simulated with MODTRAN, a $1500 yearly piece of
    %software. I've interpolated the attenuation graph from OPALS "Optical
    %Payload for Lasercom..." Fig 2.b.
    air_mass = 1./( cos(zenith_ang) + 0.50572.*(6.07995 + 90-zenith_ang).^-1.6364);
    %^Uses Kasten and Young Model to calculate air_mass. See Opals Paper
    %eq(1). section 2.1
    if(scenario == 0)
        attenuation = rural_23km_cloudy_model(air_mass);
        %Rural_20km fit Opal's mission the best. 
        atmo_variance = 0.3; %Taken from Opals paper
    end
    if(scenario == 2)
        attenuation = desert_ext_model(air_mass);
        atmo_variance = 1E-2;    
        %Best case, it's 1E-2
        %worst case, it's 0.3 of the range.
    end
    atmo_signal = Prx.*db2mag(attenuation); %signal after atmosphere
    %atmospheric atetenuation.
    %Based on here: https://en.wikipedia.org/wiki/White_noise
    %Power_i for all spectrum i  = variance;
    atmo_noise = atmo_signal*atmo_variance; %This is noise power. W/rt(Hz)
    %Todo; this one is beyond me. 
%     variance = level*atmo_variance; %b/c the number from OPALS was normalized.
%     atmo_noise = variance.^.5*randn(length(atmo_signal),1);    
%     %Todo: should 'level' be rms or mean? Did Opals Normalize variance to
    %signal mean or signal power? Signal mean seems more culturally common.
    %based off equation found under 'alternative definition':
    %https://en.wikipedia.org/wiki/Signal-to-noise_ratio
  
    %flux by wavelength (um), with an extra area term (cm^2) in there. 
     %in LEO, the Earth subtends a solid angle of ~2Pi (D'Amico's experiment paper).
     %Therefore;
%     aperture_radius = 2.5; %cm b/c Bl is in cm
%     filterBW = 10E-9*1E6;%um; converts nm to um. Industry standard optical filter;
%     HFOV = 1/180*pi; %1 degree.
%     SR_HFOV = 2*pi*(1-cos(HFOV));
%     Bl = 0.013;% W/cm^2/sr/um Units of radiant intensity. Which is angular
%     Ar = pi * (aperture_radius).^2;
%     Omr = SR_HFOV;    
%     Lr = 1;
%     P_bg = Bl * Ar * Omr * filterBW * Lr
%     atmo_background = P_bg/ Ar; %Intensity. W/m^2;
    %aperture_flux = atmo_background*(pi*aper_radius.^2);
    %W/m^2 (for our bw) =  W/cm^2/sr/um            * sr *   (cm/m).^2 * um/m (spectrum)
    %This should technically change with altitude. Todo; add Earth Subtend
    %for solid angle at our altitude.

    
    %%
    %Putting it all together
    total_signal = atmo_signal;
    total_noise = atmo_noise;
    total_bg = Pbg; 
    
    
    if(verbose)
        figure;
        t = linspace(1,100);
        o = ones(length(t),1)';
        semilogy(t, (o.*Prx));
        hold on;
        semilogy(t, (o.*atmo_signal));
        semilogy(t, (o.*atmo_noise)); %+atmo_background.^2).^0.5));
        semilogy(t, (o.*Pbg));
        
        title('Atmospheric Effects');
        ylabel('Watts on Quad Cell');
        xlabel('Scalars');
        legend('Signal After Propogation Loss',...
            'Signal After Atmospheric Loss',...
            'Total Atmo-Noise',...
            'Atmospheric Background Irradiance');
    end
    
    if(verbose == -2)
        total_signal
        total_noise
        total_bg
        r_spot
    end
    
    output_package = {total_signal , total_noise, total_bg, r_spot};
end


