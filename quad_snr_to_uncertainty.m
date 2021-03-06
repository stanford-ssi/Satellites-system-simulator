function [uncertainty_x,linear_uncertainty] = quad_snr_to_uncertainty(SNR, spot_x,...
    w, beam_power, quad_width, pixel_gap, simulation_depth, num_locations )
        
        global verbose
        %sim parameters
        %num_locations:  %number of points to check between operating points.
                        %scales linearly, but does everything again, so it
                        %adds time.
        
        %power ratios to add.
        p = (spot_x+1)/2;
        p_np = p*(1+1/db2mag(SNR));
        p_nn = p*(1-1/db2mag(SNR));
        
        %Find initial operating points.   
        spot_y = 0;                             
        num_op_points = 1000;
        possible_true_points = linspace(-w*4/quad_width,w*4/quad_width,1000);
        possible_outputs = ones(num_op_points,1)';
        for ind=1:num_op_points
            spot_x = possible_true_points(ind);
            spot_y = spot_x; %carve diagonal path
            [x,y] = integrate_quad(spot_x,spot_y,...
            w,beam_power,quad_width,...
            pixel_gap, simulation_depth);
            possible_outputs(ind) = x; 
        end
        [c , i_op] = min(abs(possible_outputs - (p*2-1)));
        [c , i_np] = min(abs(possible_outputs - (p_np*2-1)));
        [c , i_nn] = min(abs(possible_outputs - (p_nn*2-1)));
        op_point = possible_true_points(i_op);
        op_max = possible_true_points(i_np);
        op_min = possible_true_points(i_nn);
        %dx_prezoom = (op_max-op_min)*quad_width*2 %b/c normalized to -1,0,1 of quad width;
        %%
        %Test assuming linear about op-point.
        y1 = possible_outputs(i_op);
        y2 = possible_outputs(i_op+1);
        x1 = possible_true_points(i_op);
        x2 = possible_true_points(i_op+1);
        slope = (y2-y1)/(x2-x1);
        dy =  p_np - p;        
        dx = dy/slope;
        
        if(verbose)
            figure
            hold on;
            plot(possible_true_points*2*quad_width, possible_outputs);
            plot(x1*2*quad_width,y1,'*');
            plot((x1+dx)*2*quad_width, y1+dy,'d');
            plot((x1-dx)*2*quad_width, y1-dy,'d');
        end
        linear_uncertainty = 2*dx;
        %%
        %Zoom way in on operating points and find proper values for inversion.
        %======================================================================
             max_pos_x = linspace(possible_true_points(max([i_np-1,1])), possible_true_points(min([i_np+1,length(possible_true_points)])), num_locations);
             x_hat_max = ones(length(num_locations),1)';
             for p = 1:length(max_pos_x)
                            spot_x = max_pos_x(p); %01;%Ranges from -1 to 1.
                            spot_y = spot_x;                             
                            [x,y] = integrate_quad(spot_x,spot_y,...
                            w,beam_power,quad_width,...
                            pixel_gap, simulation_depth);
                            x_hat_max(p) = x;     
             end
             min_pos_x = linspace(possible_true_points(max([i_nn-1,1])), possible_true_points(min([i_nn+1,length(possible_true_points)])), num_locations);                 
             x_hat_min = ones(length(num_locations),1)';
             for p = 1:length(max_pos_x)
                            spot_x = min_pos_x(p); %01;%Ranges from -1 to 1.
                            spot_y = spot_x;
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
        dx = (op_max-op_min)*quad_width*2; %b/c normalized to -1,0,1 of quad width;
        uncertainty_x = dx;
        
end