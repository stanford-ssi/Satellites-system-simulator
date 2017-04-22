function r = get_rms(noise, df);
%Assumes f is linear.
%Requires spacing between frequencies to be constant;
    tg = (sum(noise.*conj(noise)).*df);
    r = abs( tg^.5);
end
