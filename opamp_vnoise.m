function vnoise = opamp_vnoise(peak, corner_freq, trough, f)
%This function calculates the voltage noise of an opamp based off a
%single pole model. Assumes all input values are linear.
    CORN_F = log10(corner_freq);
    F = log10(f);
    P = log10(peak);
    T = log10(trough);
        
    n = -(P-T)/CORN_F*F + P;
    n = 10.^n;
    n(f>corner_freq) = trough;
    vnoise = n;
end
