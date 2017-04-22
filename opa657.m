function specs = opa657(w)
    %Opamp is OPA657
    %http://www.ti.com/lit/ds/symlink/opa657.pdf
    OPAMP_3DB_OPENLOOP = 1E9; %1Ghz
    OPAMP_DC_GAIN = 75; %Db
    OPAMP_OPENLOOPGAIN = openloop_gain(OPAMP_3DB_OPENLOOP, OPAMP_DC_GAIN,w); 
    OPAMP_VNOISE_PEAK = 40E-9; %150nV/root(Hz)
    OPAMP_VNOISE_FREQ = 1500; %1.5kHz
    OPAMP_VNOISE_TROUGH = 4.8E-9;  %4.8nV/root(Hz)
    OPAMP_VNOISE = opamp_vnoise(OPAMP_VNOISE_PEAK, OPAMP_VNOISE_FREQ, OPAMP_VNOISE_TROUGH, w);
    OPAMP_INOISE_DC = 1.3E-15;
    OPAMP_INOISE_POLE = 1E6; %1Mhz
    OPAMP_INOISE_SLOPE = 1; %in log10,log10.
    OPAMP_INOISE = opamp_inoise(OPAMP_INOISE_DC, OPAMP_INOISE_POLE, OPAMP_INOISE_SLOPE, w);
    specs = {OPAMP_3DB_OPENLOOP; OPAMP_DC_GAIN; OPAMP_VNOISE; OPAMP_INOISE; OPAMP_OPENLOOPGAIN};

    global verbose;
    if(verbose ==1)
        figure
        %hold on
        %loglog(w,OPAMP_INOISE);
        %semilogx((w),(OPAMP_INOISE));
        loglog(w,OPAMP_INOISE);
        title('Current Noise in OPA657 opamp');
        xlabel('Hz');
        ylabel('fA per rt Hz');
        legend('opamp inoise');

        figure
        %hold on
        loglog(w,OPAMP_VNOISE*1E9);
        %semilogy(log10(w), OPAMP_VNOISE*1E9);
        title('Voltage Noise in OPA657 opamp');
        xlabel('10^x Hz');
        ylabel('nV per rt Hz');
        
    end
end
