function uncertainty_x = quad_snr_to_uncertainty(SNR, spot_x,...
    w, beam_power, quad_width, pixel_gap, simulation_depth, num_locations )
        
        %sim parameters
        %num_locations:  %number of points to check between operating points.
                        %scales linearly, but does everything again, so it
                        %adds time.
        
        %power ratios to add.
        p = (spot_x+1)/2;
        p_np = p*(1+4/db2mag(SNR));
        p_nn = p*(1-4/db2mag(SNR));
        
        %Find initial operating points.   
        spot_y = 0;                             
        possible_op_points = linspace(-1,1,1000);
        x_hat_pre = ones(1000,1)';
        for p=1:1000
            spot_x = possible_op_points(p);
            [x,y] = integrate_quad(spot_x,spot_y,...
            w,beam_power,quad_width,...
            pixel_gap, simulation_depth);
            x_hat_pre(p) = x; 
        end
        [c , i_op] = min(abs(x_hat_pre - (p*2-1)));
        [c , i_np] = min(abs(x_hat_pre - (p_np*2-1)));
        [c , i_nn] = min(abs(x_hat_pre - (p_nn*2-1)));
        op_point = possible_op_points(i_op);
        op_max = possible_op_points(i_np);
        op_min = possible_op_points(i_nn);
        dx_prezoom = (op_max-op_min)*quad_width*2 %b/c normalized to -1,0,1 of quad width;
        %%
        %Zoom way in on operating points and find proper values for inversion.
        %======================================================================
             max_pos_x = linspace(possible_op_points(max([i_np-1,1])), possible_op_points(min([i_np+1,length(possible_op_points)])), num_locations);
             x_hat_max = ones(length(num_locations),1)';
             for p = 1:length(max_pos_x)
                            spot_x = max_pos_x(p); %01;%Ranges from -1 to 1.
                            spot_y = 0;                             
                            [x,y] = integrate_quad(spot_x,spot_y,...
                            w,beam_power,quad_width,...
                            pixel_gap, simulation_depth);
                            x_hat_max(p) = x;     
             end
             min_pos_x = linspace(possible_op_points(max([i_nn-1,1])), possible_op_points(min([i_nn+1,length(possible_op_points)])), num_locations);                 
             x_hat_min = ones(length(num_locations),1)';
             for p = 1:length(max_pos_x)
                            spot_x = min_pos_x(p); %01;%Ranges from -1 to 1.
                            spot_y = 0;
                            [x,y] = integrate_quad(spot_x,spot_y,...
                            w,beam_power,quad_width,...
                            pixel_gap, simulation_depth);
                            x_hat_min(p) = x;     
             end
        %======================================================================
        %%
        [c , i_np] = min(abs(x_hat_max - (p_np*2-1)));
        [c , i_nn] = min(abs(x_hat_min - (p_nn*2-1)));
        op_max = max_pos_x(i_np);
        op_min = min_pos_x(i_nn);
        dx = (op_max-op_min)*quad_width*2 %b/c normalized to -1,0,1 of quad width;
        uncertainty_x = dx;
end