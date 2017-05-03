function vals = mk66_avg32()
    %http://www.nxp.com/assets/documents/data/en/data-sheets/K66P144M180SF5V2.pdf
    %Differential operation mode
    %Averages 32 samples in HW.
    NAME = 'MK66-32avg';
    global scenario
    if(scenario >= 1)
        ENOB = 14.5; %Typical
    else
        ENOB = 12.8;
    end
    
    %WARNING NOT SPECC'D:
    THD = -94;%dB, worst case
    %THD not specc'ed on avg4! only specc'd 32
    vals = {ENOB, THD, NAME};
end
