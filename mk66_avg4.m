function vals = mk66_avg4()
    %http://www.nxp.com/assets/documents/data/en/data-sheets/K66P144M180SF5V2.pdf
    %Differential operation mode
    %Averages 4 samples in HW.
    global best_case
    if(best_case >= 1)
        ENOB = 13.8; %Typical
    else
        ENOB = 11.9;
    end
    %WARNING NOT SPECC'D:
    THD = -94;%dB, worst case
    %THD not specc'ed on avg4! only specc'd 32
    vals = {ENOB, THD};
end
