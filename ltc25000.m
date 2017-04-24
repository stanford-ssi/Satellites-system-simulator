function ENOB = ltc25000()
    SINAD = 100; %dB;
    %Using this equation:https://en.wikipedia.org/wiki/Effective_number_of_bits
    ENOB = (SINAD-1.76)/6.02;
end
