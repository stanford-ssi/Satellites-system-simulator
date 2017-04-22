function g = openloop_gain(db3, dc_gain, f)
%Assumes f is linear. returns in linear gain.
%returns gain for every value of f specified.    
    DB3 = log10(db3); %The 3db point is specified in linear freqiency. The log base here makes scaling make sense.
    F = log10(f);
    G = -(dc_gain-3)/DB3*F + dc_gain;
    g = db2mag(G);
end
