function vals = ltc2500_df64()
    SINAD = 103; %dB;
    THD = -120;%dB, worst case
    NAME = 'LTC2500-DF64';
    %Using this equation:https://en.wikipedia.org/wiki/Effective_number_of_bits
    ENOB = (SINAD-1.76)/6.02;
    NOISE = 1.68E-6;
    DOWNSAMPLE_FACTOR = 64;
    DATA_RATE = 15.6;%ksps;
    vals = {ENOB, THD, NAME, NOISE, DOWNSAMPLE_FACTOR, DATA_RATE};
end
