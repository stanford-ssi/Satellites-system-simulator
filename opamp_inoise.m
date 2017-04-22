function inoise = opamp_vnoise(dc, pole, slope,f); 
%This function calculates the current noise of an opamp based off a
%single pole model. Assumes all input values are linear.
    s = slope;
    P = log10(pole);
    F = log10(f);
    %P = log10(peak);
    %T = log10(trough);
    n = s*F-P*slope+log10(dc);
    %n = -(P-T)/CORN_F*F + P;
    n = 10.^n;
    n(f<pole) = dc;
    q = find(f<1E6);
    n(f>1E6)=n(q(end));
    inoise = n;
    
    

end
