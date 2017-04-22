function specs = opa847(w)
    %Opamp is OPA847
    %http://www.ti.com/lit/ds/symlink/opa847.pdf
    OPAMP_3DB_OPENLOOP = 10E9; %1Ghz
    OPAMP_DC_GAIN = 95; %Db
    OPAMP_OPENLOOPGAIN = openloop_gain(OPAMP_3DB_OPENLOOP, OPAMP_DC_GAIN,w); 
    OPAMP_VNOISE_PEAK = 8E-9; %150nV/root(Hz)
    OPAMP_VNOISE_FREQ = 1500; %1.5kHz
    OPAMP_VNOISE_TROUGH = 0.8E-9;  %4.8nV/root(Hz)
    OPAMP_VNOISE = opamp_vnoise(OPAMP_VNOISE_PEAK, OPAMP_VNOISE_FREQ, OPAMP_VNOISE_TROUGH, w);
    OPAMP_INOISE_TROUGH= 2.7E-12; %2.7pA
    OPAMP_INOISE_POLE = 1000; %1kHz
    OPAMP_INOISE_PEAK = 12E-12; %in log10,log10.
    OPAMP_INOISE = opamp_vnoise(OPAMP_INOISE_PEAK, OPAMP_INOISE_POLE, OPAMP_INOISE_TROUGH, w);
    %Note: ^above uses vnoise instead of inoise b/c of shape of opa847's
    %current noise curve. Compare the curves of i noise to data sheet if
    %concerned. 
    specs = {OPAMP_3DB_OPENLOOP; OPAMP_DC_GAIN; OPAMP_VNOISE; OPAMP_INOISE; OPAMP_OPENLOOPGAIN};

    global verbose;
    if(verbose ==1)
        figure
        %hold on
        %loglog(w,OPAMP_INOISE);
        %semilogx((w),(OPAMP_INOISE));
        loglog(w,OPAMP_INOISE);
        title('Current Noise in OPA847 opamp');
        xlabel('Hz');
        ylabel('fA per rt Hz');
        legend('opamp inoise');

        figure
        %hold on
        loglog(w,OPAMP_VNOISE*1E9);
        %semilogy(log10(w), OPAMP_VNOISE*1E9);
        title('Voltage Noise in OPA847 opamp');
        xlabel('10^x Hz');
        ylabel('nV per rt Hz');
        end
end
