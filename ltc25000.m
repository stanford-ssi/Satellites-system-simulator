function vals = ltc25000()
    SINAD = 100; %dB;
    THD = -114;%dB, worst case
    %Using this equation:https://en.wikipedia.org/wiki/Effective_number_of_bits
    ENOB = (SINAD-1.76)/6.02;
    vals = {ENOB, THD};
end
