function vals = ltc2508()
    SINAD = 100; %dB;
    THD = -119;%dB, worst case
    NAME = 'LTC2500';
    %Using this equation:https://en.wikipedia.org/wiki/Effective_number_of_bits
    ENOB = (SINAD-1.76)/6.02;
    vals = {ENOB, THD, NAME};
end
