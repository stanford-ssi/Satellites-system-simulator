function specs = opa111(w)
    %Opamp is OPA111
    %http://www.ti.com/lit/ds/symlink/opa111.pdf
    OPAMP_3DB_OPENLOOP = 1E6; %Mhz
    OPAMP_DC_GAIN = 125; %Db
    OPAMP_OPENLOOPGAIN = openloop_gain(OPAMP_3DB_OPENLOOP, OPAMP_DC_GAIN,w); 
    OPAMP_VNOISE_PEAK = 150E-9; %150nV/root(Hz)
    OPAMP_VNOISE_FREQ = 200;
    OPAMP_VNOISE_TROUGH = 4.8E-9;  %4.8nV/root(Hz)
    OPAMP_VNOISE = opamp_vnoise(OPAMP_VNOISE_PEAK, OPAMP_VNOISE_FREQ, OPAMP_VNOISE_TROUGH, w);
    OPAMP_INOISE_DC = 0.5E-15;
    OPAMP_INOISE_POLE = 30E3; %30kHz;
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
        title('Current Noise in OPA111 opamp');
        xlabel('Hz');
        ylabel('fA per rt Hz');
        legend('opamp inoise');

        figure
        %hold on
        loglog(w,OPAMP_VNOISE*1E9);
        %semilogy(log10(w), OPAMP_VNOISE*1E9);
        title('Voltage Noise in OPA111 opamp');
        xlabel('10^x Hz');
        ylabel('nV per rt Hz');
        legend('V, opa111');
    end
end
