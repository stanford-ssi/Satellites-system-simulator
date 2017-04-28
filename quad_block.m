function quad_outputs = quad_block(thetas, sig_power, spot_radius, bg_power, noise_power)
    %%Full simulation of power hitting a quad cell
    %including gaps from pixels. Produces estimate
    %X and Y of position normalized to 1.
    %THIS IS LIGHT FALLING ON THE QUAD CELL. OPTICAL GAINS, LENSES, SHOULD 
    %BE HANDLED IN OPTICS_BLOCK.M.
    
    %%Section 1: Attribute Declaration
    n=50; %Number of points to integrate over.
    
    w = 0.001;% beam_waist. exp(-2) of power.
    fc = 0.015 %focal distance assuming simple telescope (it's not)
    power = 1E-5;
    Io = power*2/(pi*w^2)
    %Power for beam waist to Peak Intensity.
    %https://en.wikipedia.org/wiki/Gaussian_beam
    I_bg = 0;%Background intensity. However you scale that. 
    
    pixel_gap = 30E-6; %30um;
    %pixel_gap = 30E-5;
    quad_width = 0.01; %10mm 
    %Assumes square quad
%%
%Section 1.9999:
%Simulate power over all possible X,Y positions and return
%cordinate estimates for each. 
% low_x = -quad_width/2;
% high_x = quad_width/2;
% low_y = -quad_width/2;
% high_y = quad_width/2;
low_x = -1;
high_x = 1;
low_y = -1;
high_y = 1;
num_locations = 2;  %Number of different spot positions to test. scales N^2
simulation_depth = 100; %How many points to integrate over for power calcs. Scales N^2
diff = high_x - low_x;
[spot_pos_x, spot_pos_y]  = meshgrid(low_x:diff/num_locations:high_x,low_y:diff/num_locations:high_y);           
x_hat = zeros(num_locations);
y_hat = zeros(num_locations);


for p = spot_pos_x(1,:)
    for m = spot_pos_y(:,1)'
            figure
            spot_x = p; %01;%Ranges from -1 to 1.
            spot_y = m;
            n = simulation_depth;
            quad = [0,0;0,0];%Simulate Gaussian spot on entire quad cell.
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
                    I_bg = 0;
                    I_sig = Io*exp(-2*(x_relative.^2)./(w^2)).*exp(-2*(y_relative.^2)./w.^2); %Beacon Signal.
                    %^From eq1. "Detection sensitivity of the optical beam deflection
                    %method characterized with the optical spot size on the detector"
                    I = I_sig;
                    %I = I_sig + I_bg;
                    quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
                     if(verbose)
                        view_res = 50;
                        res = round((n+1)/view_res:n+1); 
                        surf(x(1:res:n+1,1:res:n+1),...
                        y(1:res:n+1,1:res:n+1),...
                        I(1:res:n+1,1:res:n+1) );
                        hold on;
                     end
                end
            end
            q_sum = sum(sum(quad));
            Y_hat = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2))) / q_sum;
            X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
            P = round( p*num_locations/quad_width+num_locations/2+1 );
            M = round( m*num_locations/quad_width+num_locations/2+1 );
            x_hat(P,M) = X_hat;     
            y_hat(P,M) = Y_hat;
    end
end
figure
surf(spot_pos_x, spot_pos_y, x_hat);
surf(spot_pos_x, spot_pos_y, y_hat);


    


%%
%Section2: Power Gathered For Given Point. 
%given a spot location, X,Y simulate power
%falling on each of the 4 cells.
%Creates an estimate X_hat.

    spot_x = 0; %01;%Ranges from -1 to 1.
    spot_y = 0.75;
    
    n = 100;
    quad = [0,0;0,0];
    %Simulate Gaussian spot on entire quad cell.
    for i = 1:2
        for j =1:2
            if(i ==2)
                low_x = -1*quad_width/2;
                high_x = -pixel_gap/2;
                del = abs(low_x-high_x);
                %high_x = high_x -del/n/2;
            end
            if(i ==1)
                low_x = pixel_gap/2; 
                high_x = 1*quad_width/2;
                del = abs(low_x-high_x);
            end
            
            if(j ==2)
                low_y = -1*quad_width/2;
                high_y = -pixel_gap/2;
                %del = abs(low_y-high_y);
                %high_y = high_y +del/n;
            
            end
            if(j ==1)
                low_y = pixel_gap/2; 
                high_y = 1*quad_width/2;
            end
            

            [x,y] = meshgrid(low_x:del/n:high_x,low_y:del/n:high_y);
            x_relative = x-spot_x*(0.5*quad_width);
            y_relative = y-spot_y*(0.5*quad_width); 
            I_bg = 0;
            I_sig = Io*exp(-2*(x_relative.^2)./(w^2)).*exp(-2*(y_relative.^2)./w.^2); %Beacon Signal.
            %^From eq1. "Detection sensitivity of the optical beam deflection
            %method characterized with the optical spot size on the detector"
            I = I_sig;
            %I = I_sig + I_bg;
            quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
            
            if(verbose)
                view_res = 50;
                res = round((n+1)/view_res:n+1); 
                surf(x(1:res:n+1,1:res:n+1),...
                     y(1:res:n+1,1:res:n+1),...
                     I(1:res:n+1,1:res:n+1) );
                hold on;
            end
        end
    end
    
    
%%  

%Section 3: Power Gathered to slope.
%Adds variance of signal noise to determine
%the delta_X_hat. delta_X_hat*2 is angular 
%uncertainty
    q_sum = sum(sum(quad));
    Y_hat = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2))) / q_sum;
    X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
    cord = [X_hat, Y_hat]
    
    thetas = asin(cord./fc);
    
    
    var_xy = [var_x, var_y];
    quad_outputs = var_xy;
    quad_outputs = { quad_currents_sig, quad_currents_bg, quad_currents_noise, var_xy };
end