function theta = noise_to_angle(signal, noise, w, f)

        laser_spot_diameter = w; %0.25E-3;
        %f = 10E-3; 
        SNR = signal/noise;
        
        %simpler equation. spot directly on center. 
        quad_sensitivity_xy_2 = 4./SNR;
        quad_sensitivity_xy = sqrt(quad_sensitivity_xy_2);
        spot_sensitivity_xy = (laser_spot_diameter/2)*quad_sensitivity_xy;    
        spot_sensitivity_rad = spot_sensitivity_xy./f;

        %Larger, less idealized equation. From Theory of tracking accuracy of
        %laser systems. eq 62
        spot_size = w/2; %0.001; %.2mm
        var_x = SNR.^-1.*(1-8./SNR)./(1+8./SNR).^2;
        var_x = 4./SNR;
        dx = sqrt(spot_size.^2*var_x); %denormalized variance. eq 3b
        fc = 0.01; %focal distance assuming simple telescope (it's not)
        std_theta_II = asin(dx/fc);
        
        theta = spot_sensitivity_rad;
end


