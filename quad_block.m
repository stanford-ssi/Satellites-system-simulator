function angle_uncertainty = quad_block(sig_power, noise_power)
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
    power = sig_power; %Total integrated gaussian beam power . 
    %Power for beam waist to Peak Intensity.
    %https://en.wikipedia.org/wiki/Gaussian_beam
    
    %used in section 2. Take signal and noise and produce position
    %estimate. Produces uncertainty bounds as well. 
    signal = sig_power; %Best guess estimates of signal and noise rms values from TIA block.
    noise = noise_power;
   
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
    beam_power = power
    for p = 1:length(spot_pos_x(1,:))
        for m = 1:length(spot_pos_y(:,1)')
                spot_x = spot_pos_x(1,p); %01;%Ranges from -1 to 1.
                spot_y = spot_pos_y(m,1);
                [x,y] = integrate_quad(spot_x,spot_y,...
                    w,beam_power,quad_width,...
                    pixel_gap, simulation_depth);
                x_hat(p,m) = x;     
                y_hat(p,m) = y;
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
    %Section 5:
    %Create curve that varies position and records power collected. 
    low_x = -w/quad_width*4; %Auto scaling to capture most detail.
    high_x = w/quad_width*4;
    
    num_locations = 1000;  %Number of different spot positions to test. scales N
    simulation_depth = 70; %How many points to integrate over for power calcs. Scales N^2
    diff = high_x - low_x;
    spot_pos_x  = low_x:diff/num_locations:high_x;           
    x_hat = zeros(num_locations+1,1)';
    
    %Calculate inverse for max point.     
    for p = 1:length(spot_pos_x)
                spot_x = spot_pos_x(p); %01;%Ranges from -1 to 1.
                spot_y = 0;
                [x,y] = integrate_quad(spot_x,spot_y,...
                w,beam_power,quad_width,...
                pixel_gap, simulation_depth);
                x_hat_pre(p) = x;     
    end
        if(verbose)
        figure
        plot(spot_pos_x, x_hat_pre);
        title('Position To Quad Output Curve');
        xlabel('True X position (Normalized to Width of Detector)');
        ylabel('Output of Summations');
    end    
    %%
    %Section 6: Produce plot of uncertainty and SNR.
    compute_again = 0;
    if(compute_again)
        simulation_depth = 70;
        num_points = 50;
        num_locations = 1000;
        snratio = linspace(3, 100,num_points);
        dx = ones(num_points,1);
        for index = 1:num_points
                SNR = snratio(index);
                dx(index) = quad_snr_to_uncertainty(SNR, spot_x,...
                w, beam_power, quad_width, pixel_gap, simulation_depth, num_points);
                index
                num_points
        end
        snratio = linspace(3, 100,num_points);
        dx_no_gap = ones(num_points,1);
        for index = 1:num_points
                SNR = snratio(index);
                pg = 0;
                dx_no_gap(index) = quad_snr_to_uncertainty(...
                    SNR, spot_x, w, beam_power,...
                    quad_width, pg, simulation_depth,...
                    num_points);
                index
                num_points
        end
        save('snr_angle_sim','snratio','dx','dx_no_gap');
    else
        load('snr_angle_sim');
    end
    
    if(verbose)
        var_theta_II = abs(asin(dx./fc)) %It's abs cause when the snr is really bad, you just don't know and the large values break asin.
        var_theta_no_gap = abs(asin(dx_no_gap./fc))
                     
        figure
        semilogy(snratio, var_theta_II);
        hold on;
        semilogy(snratio, var_theta_no_gap);
        
        title('SNR vs Angular Determination');
        xlabel('System SNR');
        ylabel('Maximum Uncertainty, Radians');
        legend('Pixel Gap','No Pixel Gap');
    end
    
        
    %%
    %Section 7:
    %Given the sum output of a quad and the SNR, tell me the position and dx cloud.
    SNR = mag2db(sig_power/ noise_power);
    dx = quad_snr_to_uncertainty(SNR, spot_x,...
    w, beam_power, quad_width, pixel_gap,...
    simulation_depth, num_locations )
    
    if(verbose)
        var_theta_II = asin(dx/fc)
        hold on
        plot(SNR,var_theta_II,'*');
        legend('SNR/Rad plot','Given SNR, angle uncertainty','Satellite Operating Point');
	end
    angle_uncertainty = var_theta_II;
    
    
    %%
    %Converts SNR into an angle
    SNR = logspace(-5,10,1000);
    %SNR = get_snr(tia_sig, tia_noise, df);
    %mag2db(SNR) %Sanity check component. from Theory of tracking accuracy of
    %laser systems. eq 62
    spot_size = w*2; %0.001; %.2mm
    var_x = SNR.^-1.*(1-8./SNR)./(1+8./SNR).^2;
    dx = spot_size.^2*var_x %denormalized variance. eq 3b
    dx = spot_size*var_x %denormalized variance. eq 3b
    fc = 0.015 %focal distance assuming simple telescope (it's not)
    var_theta_II = asin(dx/fc);

    display =1;
    if(display ==1)
        figure
        hold on;
        o = ones(length(SNR),1)';
        target_angle = 1E-7; %0.1uRad;
        plot(mag2db(SNR),log10(var_theta_II));
        plot(mag2db(SNR),log10(target_angle*o));
        title('SNR of Quad VS. Angular Variance');
        ylabel('Variance, Rad');
        xlabel('SNR, linear');
        legend('Var vs SNR','Target Variance');

    end

    if(verbose ==1)
        'Angle Variance: '
        var_theta_II
    end
        target_theta = 1E-6;
    tg = ones(1,length(SNR))*target_theta;
    figure
    semilogy(mag2db(SNR), var_theta_II);
    title('SNR vs Angular Determination');
    xlabel('SNR (dB)');
    ylabel('Radians');

    
end
    
    
   