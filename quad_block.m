function quad_outputs = quad_block(thetas, sig_power, spot_size, bg_power, noise_power)
    %%Full simulation of power hitting a quad cell
    %including gaps from pixels. Produces estimate
    %X and Y of position normalized to 1.
    %THIS IS LIGHT FALLING ON THE QUAD CELL. OPTICAL GAINS, LENSES, SHOULD 
    %BE HANDLED IN OPTICS_BLOCK.M.
    global verbose
    %%Section 1: Attribute Declaration
    n=50; %Number of points to integrate over.
    w = 0.001;% beam_waist. exp(-2) of power.
    w = 100E-6;
    fc = 0.015 %focal distance assuming simple telescope (it's not)
    power = 1E-5; %Total integrated gaussian beam power . 
    %Power for beam waist to Peak Intensity.
    %https://en.wikipedia.org/wiki/Gaussian_beam
    I_bg = 0;%Background intensity. However you scale that. 
    
    %used in section 2. Take signal and noise and produce position
    %estimate. Produces uncertainty bounds as well. 
    signal = 0.01596; %Best guess estimates of signal and noise rms values from TIA block.
    noise = 8E-5;
   
    pixel_gap = 30E-6; %30um;
    quad_width = 0.01; %10mm 
    %Assumes square quad
    
    
    %%
    %Section 1.5:
    %Sanity check on outputs of x and y;
    %Simulate power over all possible X,Y positions and return
    %power values for each. 
    low_x = -1;
    high_x = 1;
    low_y = -1;
    high_y = 1; %Cordinates are normalized to width of quad/2.
    num_locations = 30;  %Number of different spot positions to test. scales N^2
    simulation_depth = 30; %How many points to integrate over for power calcs. Scales N^2
    diff = high_x - low_x;
    [spot_pos_x, spot_pos_y]  = meshgrid(low_x:diff/num_locations:high_x,low_y:diff/num_locations:high_y);           
    x_hat = zeros(num_locations);
    y_hat = zeros(num_locations);
    Io = power*2/(pi*w^2) %Peak intensity for gaussian beam.
    for p = spot_pos_x(1,:)
        for m = spot_pos_y(:,1)'
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
                    
                    end
                end
                q_sum = sum(sum(quad));
                Y_hat = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2))) / q_sum;
                X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
                P = round( p*num_locations/2+num_locations/2+1 );
                M = round( m*num_locations/2+num_locations/2+1 );
                x_hat(P,M) = X_hat;     
                y_hat(P,M) = Y_hat;
        end
    end

    if(verbose)
        figure
        surf(spot_pos_x, spot_pos_y, x_hat);
        hold on;
        surf(spot_pos_x, spot_pos_y, y_hat);
        title('Position Estimates VS True Estimates');
        xlabel('True X position (Normalized to Width of Detector)');
        ylabel('True Y Position (Normalized to Width of Detector)');
        zlabel('Predicted Position');
    end


  
%%
%Section 3
%Varying spot radius and creating surface for prediction accuracy.
    Io = signal*2/(pi*w^2);
    low_x = -1;
    high_x = 1;
    low_r = pixel_gap/4; %Half the size of the gap.
    high_r = quad_width; %Spans twice full quad.
    num_locations = 50;  %Number of different spot positions to test. scales N^2
    simulation_depth = 30; %How many points to integrate over for power calcs. Scales N^2
    diff = high_x - low_x;
    diff_r = high_r - low_r;
    [spot_pos_x, spot_radius]  = meshgrid(low_x:diff/num_locations:high_x,low_r:diff_r/num_locations:high_r);           
    x_hat = zeros(num_locations+1);
    
    %Noises are currently adding + on the one side, - on the other,
    %This may be doubling the effect of the noise. But in a world dominated
    %by dB, a doubling or a half should be acceptable. 
    for p = 1:length(spot_pos_x(1,:))
        for m = 1:length(spot_radius(:,1)')
                spot_x = spot_pos_x(1,p); %01;%Ranges from -1 to 1.
                spot_y = 0;
                r = spot_radius(m,1); %beam waist.
                Io = signal*2/(pi*w^2);
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
                        I_sig = Io*exp(-2*(x_relative.^2)./(r^2)).*exp(-2*(y_relative.^2)./r.^2); %Beacon Signal.
                        %^From eq1. "Detection sensitivity of the optical beam deflection
                        %method characterized with the optical spot size on the detector"
                        I = I_sig;
                        %I = I_sig + I_bg;
                        quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
                    end
                end
                q_sum = sum(sum(quad));
                Y_hat = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) ) / q_sum;
                X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
                Y_hat_plus = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) +2*noise ) / (q_sum+2*noise);
                X_hat_plus = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2)) +2*noise ) / (q_sum+2*noise);
                Y_hat_neg = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) -2*noise ) / (q_sum+2*noise);
                X_hat_neg = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2)) -2*noise ) / (q_sum+2*noise);
                
             
                P = p; %round( p*num_locations/2+num_locations/2+1 );
                M = m; %
                x_hat(M,P) = X_hat;     
                y_hat(M,P) = Y_hat;
                x_hat_plus(M,P) = X_hat_plus; 
                y_hat_plus(M,P) = Y_hat_plus;
                x_hat_neg(M,P) =  X_hat_neg;
                y_hat_neg(M,P) =  Y_hat_neg;
                x_hat_diff(M,P) = abs(X_hat_neg-X_hat_plus);
                y_hat_diff(M,P) = abs(Y_hat_neg-Y_hat_plus);
        
        end
    end
    x_hat_diff = x_hat_diff.*quad_width*2; %Re-attach proper units of meters for dx. The x2 is because the units are in half-widths. ie +1 equals half the total width of the quad.
    
    if(verbose)

        figure
        surf(spot_pos_x, spot_radius, x_hat);
        title('Spot Size vs Estimated Position');
        xlabel('True X position (Normalized to Width of Detector)');
        ylabel('Spot Radius');
        zlabel('Position Estimate (Meters)');
    end
    
%%
%Section 4
%Varies spot radius and SNR to show the surface of prediction accuracy.
    Io = signal*2/(pi*w^2);
    low_x = 0;
    high_x = 100;
    low_r = pixel_gap/4; %Half the size of the gap.
    high_r = quad_width; %Spans twice full quad.
    num_locations = 50;  %Number of different spot positions to test. scales N^2
    simulation_depth = 30; %How many points to integrate over for power calcs. Scales N^2
    diff = high_x - low_x;
    diff_r = high_r - low_r;
    [spot_SNR, spot_radius]  = meshgrid(low_x:diff/num_locations:high_x,low_r:diff_r/num_locations:high_r);           
    x_hat = zeros(num_locations+1);
    
    %Noises are currently adding + on the one side, - on the other,
    %This may be doubling the effect of the noise. But in a world dominated
    %by dB, a doubling or a half should be acceptable. 
    for p = 1:length(spot_SNR(1,:))
        for m = 1:length(spot_radius(:,1)')
                spot_x = 0;
                spot_y = 0;
                SNR = spot_SNR(1,p);
                noise = signal/sqrt(db2mag(SNR)); %Rearranged SNR=(Asig/Anoise)^2
                
                r = spot_radius(m,1); %beam waist.
                Io = signal*2/(pi*r^2);
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
                        I_sig = Io*exp(-2*(x_relative.^2)./(r^2)).*exp(-2*(y_relative.^2)./r.^2); %Beacon Signal.
                        %^From eq1. "Detection sensitivity of the optical beam deflection
                        %method characterized with the optical spot size on the detector"
                        I = I_sig;
                        %I = I_sig + I_bg;
                        quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 
                    end
                end
                q_sum = sum(sum(quad));
                Y_hat = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) ) / q_sum;
                X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
                Y_hat_plus = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) +2*noise ) / (q_sum+2*noise);
                X_hat_plus = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2)) +2*noise ) / (q_sum+2*noise);
                Y_hat_neg = ((quad(1,1)+quad(2,1)) - (quad(1,2)+quad(2,2)) -2*noise ) / (q_sum+2*noise);
                X_hat_neg = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2)) -2*noise ) / (q_sum+2*noise);
                
             
                P = p; %round( p*num_locations/2+num_locations/2+1 );
                M = m; %
                x_hat(M,P) = X_hat;     
                y_hat(M,P) = Y_hat;
                x_hat_plus(M,P) = X_hat_plus; 
                y_hat_plus(M,P) = Y_hat_plus;
                x_hat_neg(M,P) =  X_hat_neg;
                y_hat_neg(M,P) =  Y_hat_neg;
                x_hat_diff(M,P) = abs(X_hat_neg-X_hat_plus);
                y_hat_diff(M,P) = abs(Y_hat_neg-Y_hat_plus);
        
        end
    end
    x_hat_diff = x_hat_diff.*quad_width*2; %Re-attach proper units of meters for dx. The x2 is because the units are in half-widths. ie +1 equals half the total width of the quad.
    
    if(verbose)
        figure
        surf(spot_SNR, spot_radius, x_hat_diff);
        title('Spot Size vs SNR vs Estimation Accuracy');
        xlabel('SNR');
        ylabel('Spot Radius');
        zlabel('Uncertainty of Position Estimate (Meters)');
    end
    
    
    %%
    %Section 2:
    %Create curve that varies position and records power collected. 
    low_x = -0.04;
    high_x = .04;
    num_locations = 10000;  %Number of different spot positions to test. scales N
    simulation_depth = 70; %How many points to integrate over for power calcs. Scales N^2
    diff = high_x - low_x;
    spot_pos_x  = low_x:diff/num_locations:high_x;           
    x_hat = zeros(num_locations+1,1)';
    
    precomputed = 0;
    if(precomputed)
        Io = power*2/(pi*w^2) %Peak intensity for gaussian beam.
        for p = 1:length(spot_pos_x)
                    spot_x = spot_pos_x(p); %01;%Ranges from -1 to 1.
                    spot_y = 0;
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
                            I_sig = Io*exp(-2*(x_relative.^2)./(w^2)).*exp(-2*(y_relative.^2)./w.^2); %Beacon Signal.
                            %^From eq1. "Detection sensitivity of the optical beam deflection
                            %method characterized with the optical spot size on the detector"
                            I = I_sig;
                            %I = I_sig + I_bg;
                            quad(i,j) = sum(sum(I))* (abs(x(1,1)-x(2,2))^2); %I is power at point per unit area. multiply by area to get the final power. 

                        end
                    end
                    q_sum = sum(sum(quad));
                    X_hat = ((quad(1,1)+quad(1,2)) - (quad(2,1)+quad(2,2))) / q_sum;
                    x_hat(p) = X_hat;     

        end

        save('spot_power_data','spot_pos_x', 'x_hat');
    else
        load('spot_power_data');
    end
    if(verbose)
        figure
        plot(spot_pos_x, x_hat);
        title('Position To Quad Output Curve');
        xlabel('True X position (Normalized to Width of Detector)');
        ylabel('Output of Summations');
    end    
    
    %%
    %Section 6:
    %Given the sum output of a quad and the SNR, tell me the position and dx cloud.
    SNR = 70;
    quad_output = 0; %-1,0,1;
    p = (quad_output+1)/2;
    p_np = p*(1+4/db2mag(SNR));
    p_nn = p*(1-4/db2mag(SNR));
    q_max = (p*2-1);
    q_min = (p_nn*2-1); 

       
    [c , i_op] = min(abs(x_hat - (p*2-1)));
    [c , i_np] = min(abs(x_hat - (p_np*2-1)));
    [c , i_nn] = min(abs(x_hat - (p_nn*2-1)));
    op_point = spot_pos_x(i_op);
    op_max = spot_pos_x(i_np);
    op_min = spot_pos_x(i_nn);
    dx = (op_max-op_min)*quad_width*2; %b/c normalized to -1,0,1 of quad width;
 
    var_theta_II = asin(dx/fc)
    figure
    hold on;
    plot(spot_pos_x, x_hat);
    plot(op_point, quad_output, '*');
    plot(op_min, q_min, '*');
    plot(op_max, q_max, '*');
    title('Position To Quad Output Curve');
    xlabel('True X position (Normalized to Width of Detector)');
    ylabel('Output of Summations');
    legend('Operating Curve','Ideal Point','Minimum Possible Point','Maximum Possible Point');
    