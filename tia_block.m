function output_package= tia_block(sigs);
    %Inputs: Watts delivered to an individual diode.
    %This system operates in the frequency domain, so don't
    %input a time varying signal into the sigs spot.
    
    global verbose;
    %Helpful References:
    %http://www.ti.com/lit/an/sboa060/sboa060.pdf
    % Walks through the noise calculations of a tia^
    
    
    %all power divided by 4 because thats how much power would fall on a
    %single diode
    signal_optical = sigs{1}/4; %In Watts delivered to an individual diode. 
    noise_optical = sigs{2}/4;
    offset_optical = sigs{3}/4; %From Earth Albedo. Treated as a white noise source of this amplitude.
    
    
    
    F_high = 10E3;
    F_low = 2;
    

    
    samples = 1000;
    df = ((F_high-F_low)/samples);
    bandwidth = F_high;
    a = linspace(F_low, F_high, samples);

    %a = np.linspace(df, frequencies)
    w = a;
    
    %% System Parameters:
    opspecs = opa657(w);
    photspecs = s5981();
    Rf = 1E3; %1k CHANGE VALUE HERE
    Cf = 1E-12; %1pF CHANGE VALUE HERE
    
    T = 273; %Kelvin
    
    


  

    %%
    %Load component values
    OPAMP_3DB_OPENLOOP = opspecs{1};
    OPAMP_DC_GAIN = opspecs{2};
    OPAMP_VNOISE = opspecs{3};
    OPAMP_INOISE = opspecs{4};
    OPAMP_OPENLOOPGAIN = opspecs{5};
    PHOTODIODE_RESPONSIVITY = photspecs{1};
    PHOTODIODE_CAPACITANCE = photspecs{2};
    PHOTODIODE_RESISTANCE = photspecs{3};
    PHOTODIODE_DARK_CURRENT = photspecs{4};
    R2 = Rf; %Feedback resistance
    C2 = Cf; %Feedback capacitance
    R1 = PHOTODIODE_RESISTANCE; %Diode shunt resistance
    C1 = PHOTODIODE_CAPACITANCE; %PHOTODIODE_CAPACITANCE
    Cd = C1; 
    responsivity = PHOTODIODE_RESPONSIVITY;
    opt_currents = offset_optical + signal_optical + noise_optical;
    I_DC = responsivity*opt_currents + PHOTODIODE_DARK_CURRENT; %used in shot noise calcs.
    
    
    
    %% 
    %Misc Amplifier:
        XC2 = 1./(C2.*w);
        transfer_function = (1./R2 + 1./XC2).^-1;
        if(verbose == 1)
            figure
            plot(log10(w),mag2db(transfer_function));
            title('Transfer function of OpAmp');
            xlabel('10^x Hz');
            ylabel('dB');
        end
    %Amplifer Voltage Noise
        A = OPAMP_OPENLOOPGAIN; % Open loop gain
        j = (-1)^.5;
        s = j.*w;
        C1S = 1*w.*C1;
        C2S = 1*w.*C2;
        inv_B = 1+ R2*(R1*C1*s+1)./(R2*C2.*s+1)/R1;
        %https://en.wikipedia.org/wiki/Transimpedance_amplifier
        %Try using ^ to set Beta's.
        B=1./inv_B;
        AB = A.*B; % loop gain
        en = OPAMP_VNOISE;
        eo = en.*(A./(1+AB));
        %transfer_function = 1./C1S.*Rf./(1+inv_B./A);
        %transfer_function = A./(1+AB);
        noise_tf = abs( inv_B.*(1./(1+inv_B./A)) );
        %noise_tf = (A./(1+AB));
        v_noise = en.* noise_tf;
        %THE NOISE WILL LOOK WEIRD IF YOU PLOT IT. 
        %REMEMBER, PLOT IT AS log10(v_noise*1E9) TO PLOT
        %IN nV. The nV is important for non-weird scaling.
        get_rms(v_noise,df);
    %Misc Figures for sanity
    if(verbose == 1)
        figure
        hold on
        plot(log10(w),mag2db(abs(AB)));
        plot(log10(w),mag2db(abs(inv_B)));
        plot(log10(w),mag2db(noise_tf));
        plot(log10(w),mag2db(A));
        plot(log10(w),mag2db(abs(B)));
        plot(log10(w),mag2db(en*1E9));
        plot(log10(w),mag2db(en.*noise_tf.*1E9));
        plot(log10(w),mag2db(transfer_function));
        plot(log10(w),mag2db(ones(length(w),1)'*Rf),'.');
        
        
        %plot(log10(w),mag2db(inv_B));
        title('Voltage Noise Transfer Functions');
        xlabel('10^x Hz');
        ylabel('db Gain');
        legend('AB','1/B','V_noise TF','A','B','en','final_noise','Transfer function');
        
        figure
        loglog(w, v_noise);
        title('Total Voltage Noise');
        xlabel('Hz');
        ylabel('V per rt Hz');
        legend('V_noise');
    end
    %%
    %Optical Signals and Noises converted to Voltages
        optical_noise_tot = ((noise_optical).^2 + (offset_optical)*.2 ).^0.5 .*responsivity; 
        optical_noise_tot = noise_optical.*responsivity;
        %TODO; Is this how the noises should be added to achieve a white
        %noise signal of the sum of these two?
        optical_noise =  Rf .* optical_noise_tot .* responsivity;
        optical_signal = Rf.* signal_optical .* responsivity;
        optical_offset = Rf .* offset_optical .* responsivity;
        if(verbose == 1)
            %Figure of optical noise through circuit:
            figure
            o = ones(50,1)';
            l = linspace(1,10,length(o));
            loglog(l, o.*optical_noise);
            hold on;
            loglog(l,o.*optical_signal);
            loglog(l,o.*optical_offset);
            title('Optical Signals (Voltagized)');
            xlabel('Scalar');
            ylabel('Vrms');
            legend('optical noise','optical signal','optical offset');
        end
    %%
    %Resistor Noise:
     K = 1.38E-23; %Boltzmann's
     RES = 4*K*T*R2;%Resistor Noise
     v_res_noise = sqrt(4*K*T*R2*bandwidth);  
    %%
    %Input Current Noise
    %warning, these are functions of frequency. Must have some w defined.
        c = 1.60217662E-19; %TODO, HOW to actually do shot noise. This is an educated guess.
        SHOT = 2.*c.*I_DC;
        i_n =  (OPAMP_INOISE.^2 + SHOT.^2 + PHOTODIODE_DARK_CURRENT.^2).^.5;
        
        %Z2 = (R2.^-1 + (1./(w.*C2)).^-1).^-1;    
        %TODO; DO I ALSO MULTIPLY TF? IDK!
        i_noise_opamp =  OPAMP_INOISE .* transfer_function;  
        i_noise_shot =  SHOT .*transfer_function;
        i_dark = PHOTODIODE_DARK_CURRENT .*transfer_function;
        i_noise = ((i_noise_opamp.^2 + i_noise_shot.^2 ).^0.5) .* transfer_function;
        
        
        if(verbose == 1)  
            figure
            loglog(w,i_noise);
            hold on;
            loglog(w,i_noise_opamp);
            loglog(w,i_noise_shot);            
            title('Current Noise Sources (Through Rf)');
            xlabel('Hz');
            ylabel('V per rt Hz');
            legend('Total inoise','Opamp inoise','Shot noise');
        
        end
    %%
    %Putting all the TIA stuff together;
    %output_signal = (signal_optical*responsivity) * noise_tf; %Input optical signal through the circuit
    signal_rms = optical_signal;
    offset_rms = optical_offset +  PHOTODIODE_DARK_CURRENT .*Rf;
    hz_noise = (v_noise.^2 + i_noise.^2).^0.5;
    noise_rms = (optical_noise.^2 + get_rms(hz_noise,df).^2 + v_res_noise.^2 ) .^0.5;
    
        
    if(verbose == 1)
%         figure   
%         loglog(w,(output_noise), '*');
%         hold on
%         loglog(w,(i_noise));
%         loglog(w,(v_noise),'d');
%         title('Frequency Noise Contributions');
%         xlabel('10^x Hz');
%         ylabel('V per rt Hz');
%         legend('Total Noise','Current Noise','Voltage Noise');
%         
        o = ones(50,1)';
        l = linspace(1,10,length(o));
        figure
        loglog(l,o.*signal_rms,'-.'); 
        hold on;
        loglog(l,o.*offset_rms,'-.'); 
        loglog(l,o.*noise_rms,'-.'); 
        loglog(l,o.*get_rms(v_noise,df)); 
        loglog(l,o.*get_rms(i_noise,df)); 
        loglog(l,o.*v_res_noise); 
        loglog(l,o.*optical_noise); 
        title('RMS Values for signals and noises');
        ylabel('Volts');
        xlabel('dimensionless (Scalar Values)');
        legend('Signal RMS', 'Total Noise RMS',...
            'DC Offset (Optical, Dark)',...
            'Voltage Noise RMS', 'Current Noise RMS',...
            'Resistor RMS Noise', 'Optical RMS Noise');
        
        
        
        o = ones(50,1)';
        l = linspace(1,10,length(o));
        figure
        loglog(l,o.*signal_rms);
        hold on;
        loglog(l,o.*offset_rms);
        loglog(l,o.*noise_rms);
        title('RMS Values for signals and noises');
        ylabel('Volts');
        xlabel('dimensionless (Scalar Values)');
        legend('Signal RMS', 'Offset RMS', 'Noise RMS');
        
    end
    output_package = {signal_rms, noise_rms, offset_rms};
end

