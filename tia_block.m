function output_package= tia_block(sigs, bandwidth, w, df);
    global verbose
    %Helpful References:
    %http://www.ti.com/lit/an/sboa060/sboa060.pdf
    % Walks through the noise calculations of a tia^

    signal_optical = sigs{1};
    noise_optical = sigs{2};
    offset_optical = sigs{3}; %From Earth Albedo. Treated as a white noise source of this amplitude.
    
    Rf=-1;
    Cf=-1;
    
    %% System Parameters:
    opspecs = opa657(w);
    photspecs = s5981();
    
    if( Rf == -1)
        Rf = 1E3; %1k CHANGE VALUE HERE
    end
    if( Cf == -1)
        Cf = 1E-12; %1pF CHANGE VALUE HERE
    end
    
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
    I_DC = responsivity*get_rms(offset_optical,df); %used in shot noise calcs.
    
    
    
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
        plot(log10(w),mag2db(AB));
        plot(log10(w),mag2db(inv_B));
        plot(log10(w),mag2db(noise_tf));
        plot(log10(w),mag2db(A));
        plot(log10(w),mag2db(B));
        plot(log10(w),mag2db(en*1E9));
        plot(log10(w),mag2db(en.*noise_tf.*1E9));
        plot(log10(w),mag2db(transfer_function));
        plot(log10(w),mag2db(ones(length(w))'*Rf),'.');
        
        
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
        op_noise = transfer_function .* optical_noise_tot .* responsivity;
        op_signal = transfer_function .* signal_optical .* responsivity;
        op_offset = transfer_function .* offset_optical .* responsivity;
        if(verbose == 1)
            'Optical Noise:' 
            get_rms(op_noise,df)
            %Figure of optical noise through circuit:
            figure
            loglog(w, op_noise);
            hold on;
            loglog(w,op_signal);
            loglog(w,op_offset);
            title('Optical Signals (Voltagized)');
            xlabel('Hz');
            ylabel('V per rt Hz');
            legend('optical noise','optical signal','optical offset');
       end
    %%
    %Input Current Noise
    %warning, these are functions of frequency. Must have some w defined.
        c = 1.60217662E-19; %TODO, HOW to actually do shot noise. This is an educated guess.
        SHOT = 2.*c.*I_DC;
        K = 1.38E-23; %Boltzmann's
        RES = 4*K*T*R2;%Resistor Noise
        i_n =  (OPAMP_INOISE.^2 + SHOT.^2 + RES.^2 + PHOTODIODE_DARK_CURRENT.^2).^.5;
        i_n_ropamp =  (OPAMP_INOISE.^2 ).^.5;
        
        %Z2 = (R2.^-1 + (1./(w.*C2)).^-1).^-1;    
        %TODO; DO I ALSO MULTIPLY TF? IDK!
        i_noise = i_n .* transfer_function;
        i_noise_op =  OPAMP_INOISE .* transfer_function;
        i_noise_res =  RES .*transfer_function;
        i_noise_shot =  SHOT .*transfer_function;
        i_dark = PHOTODIODE_DARK_CURRENT .*transfer_function;
        %
        if(verbose == 1)  
            figure
            loglog(w,i_noise);
            title('Total Current Refered Noise (TIA)');
            xlabel('Hz');
            ylabel('V per rt Hz');

            figure
            hold on
            plot(log10(w),log10(i_noise_op));
            plot(log10(w),log10(i_noise));
            plot(log10(w),log10(i_noise_res));
            plot(log10(w),log10(i_noise_shot));
            plot(log10(w),log10(i_dark));
            title('Noise Contributions (Through Opamp)');
            xlabel('10^x Hz');
            ylabel('V per rt Hz');
            legend('opamp inoise','Total inoise', 'Resistor Noise', 'Shot Noise','Dark Current');
        end
    %%
    %Putting all the TIA stuff together;
    %output_signal = (signal_optical*responsivity) * noise_tf; %Input optical signal through the circuit
    output_signal = op_signal;
    output_offset = op_offset;
    output_noise = (op_noise.^2 + v_noise.^2 + i_noise.^2) .^0.5;
    tia_noise = (v_noise.^2 + i_noise.^2) .^0.5;
    
    if(verbose == 1)
        figure
        loglog(w,output_noise,'.');
        hold on;
        loglog(w,output_signal);
        loglog(w,tia_noise);
        loglog(w,op_noise);
        loglog(w, ((output_offset+output_signal).^2 + tia_noise.^2 + op_noise.^2).^0.5);
        legend('Total Noise', 'Output Signal', 'TIA refered noise', 'Optical Signal Noise','Max Output Range');
        title('TIA Signal and Noise');
        xlabel('Hz');
        ylabel('V per rt Hz');
        %loglog(OUTPUT);
        'Total SNR up to TIA block:'
        get_snr(output_signal, output_noise, df)
    end
    output_package = {output_signal, output_noise, w, df};
end

