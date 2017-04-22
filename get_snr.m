function r = get_snr(sig, noise, df);
%Requires spacing between frequencies to be constant;
%Assumes a given noise spectrum,
    sigPow = get_rms(sig,df);
    noisePow = get_rms(noise,df);
    r = mag2db(sigPow) - mag2db(noisePow);
end
