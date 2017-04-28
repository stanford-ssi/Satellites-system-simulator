function quad_outputs = quad_block(thetas, power, spot_radius)
    %%Full simulation of power hitting a quad cell
    %including gaps from pixels. Produces estimate
    %X and Y of position normalized to 1.
    
    %%Section 1: Attribute Declaration
    n=50; %Number of points to integrate over.
    
    spot_x = linspace(-1,1,n);
    power = 1E-5;
    
    pixel_gap = 30E-6; %30um;
    total_width = 0.01; %10mm 
    w = 0.1;% beam_waist. exp(-2) of power.
    %Assumes square
    
    
    %%Section 2: Power Gathered
    %%given a spot location, X,Y simulate power
    %falling on each of the 4 cells.
    %Creates an estimate X_hat.
  
    spot_x = 0; % total_width/4;
    spot_y = 0;
    
    n = 50
    quad = [0,0;0,0];
    figure    
    for i = 1:2
        for j =1:2
            if(i ==1)
                low_x = -1*total_width/2;
                high_x = -pixel_gap/2;
            end
            if(i ==2)
                low_x = pixel_gap/2; 
                high_x = 1*total_width/2;
            end
            
            if(j ==1)
                low_y = -1*total_width/2;
                high_y = -pixel_gap/2;
            end
            if(j ==2)
                low_y = pixel_gap/2; 
                high_y = 1*total_width/2;
            end
            del = abs(low_y-high_y);

            [x,y] = meshgrid(low_x:del/n:high_x,low_y:del/n:high_y);
            x_relative = x-spot_x;
            y_relative = y-spot_y; 
            I = power*exp(-2*(x_relative.^2)./(w^2)).*exp(-2*(y_relative.^2)./w.^2);
            %^From eq1. "Detection sensitivity of the optical beam deflection
            %method characterized with the optical spot size on the detector"
            quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
                  
            surf(x,y,I);
            hold on;
        end
    end
    
            
    %%Section 3: Power Gathered to slope.
    %Adds variance of signal noise to determine
    %the delta_X_hat. delta_X_hat*2 is angular 
    %uncertainty

    

    var_xy = [var_x, var_y];
    quad_outputs = var_xy;
end