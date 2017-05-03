function [x,y, A, B, C, D] = integrate_quad(spot_x,spot_y, waist, beam_power, quad_width, pixel_gap, simulation_depth )
    %Simulates a gaussian spot with center at spot_x,spot_y
    %Beam waist is 1/e^2
    %power is total beam power, not peak.
    %quad_width and pixel_gap should both be in meters, as well as
    %beam_waist.
    n = simulation_depth;
    quad = [0,0;0,0];%Simulate Gaussian spot on entire quad cell.
    w = waist;
    Io = beam_power*2/(pi*w^2);
    for i = 1:2
        for j =1:2
            if(i ==2)
                low_x = -1*quad_width/2;
                high_x = -pixel_gap/2;
                del = abs(low_x-high_x);
            end
            if(i ==1)
                low_x = pixel_gap/2; 
                high_x = 1*quad_width/2;
                del = abs(low_x-high_x);
            end
            if(j ==2)
                low_y = -1*quad_width/2;
                high_y = -pixel_gap/2;
            end
            if(j ==1)
                low_y = pixel_gap/2; 
                high_y = 1*quad_width/2;
            end
            [x,y] = meshgrid(low_x:del/n:high_x,low_y:del/n:high_y);
            x_relative = x-spot_x*(0.5*quad_width);
            y_relative = y-spot_y*(0.5*quad_width); 
            I = Io*exp(-2*(x_relative.^2)./(w^2)).*exp(-2*(y_relative.^2)./w.^2); %Beacon Signal.
            %^From eq1. "Detection sensitivity of the optical beam deflection
            %method characterized with the optical spot size on the detector"
            quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
        end
    end
    q_sum = sum(sum(quad));
    
    y = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2))) / q_sum;
    x = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
    A= quad(1,1);
    B= quad(2,1);
    C= quad(1,2);
    D= quad(2,2);
end
