function attenuation = desert_ext_model(airmass)
    %

    %This _should_ be calculated via a complex integration and MODTRAN
    %simulation software. But JPL provided a plot of dB Attenuation vs
    %Airmass in our exact bandwidth. So I extracted the curve data with 
    %lines of best fit. That's what this initial del_x stuff is. Image
    %interpolation.
    
    model_name = 'DesertExtinction';
    
    del_x = 55.75; %Pixel to width converter. Width of a single atmosphere in pixels on the graph.
    del_y = 97.5/5;   %Height of -5dB chunk on the graph divided by 5;
    length_1_x = 253; %The X projection of the line. Finish-Start.
    length_1_y = 45; %The Y projection of the line. Finish-Start.
    y_1_intercept = -22.667; %Distance from 0 dB AirMass of 1 is.    
    
    m = -(length_1_y./del_y)./(length_1_x/del_x);
    b = y_1_intercept/del_y;
    attenuation = m.*airmass+(b-m);
    
    global verbose
    if( verbose ==1)
        figure
        a = linspace(1,5.5);
        plot(a, m.*a+(b-m));
        hold on;
        plot(airmass, attenuation, '*');
        axis([0 6 -15 0]);
        title(['Atmospheric Attenuation Model (', model_name, ')']);
        ylabel('dB Attenuation');
        xlabel('Airmass Number');
        legend( [model_name, ' Model'], 'Given Airmass');
    end
end