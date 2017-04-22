function specs = bpw34()
    %photodiode is BPW34
    %http://www.vishay.com/docs/81521/bpw34.pdf
    PHOTODIODE_RESPONSIVITY = 10E-6/(0.2)*0.001/(0.01.^2); %Grabbed from plot...
    PHOTODIODE_CAPACITANCE = 40E-12;
    PHOTODIODE_RESISTANCE = 1E8;
    specs = {PHOTODIODE_RESPONSIVITY, PHOTODIODE_CAPACITANCE, PHOTODIODE_RESISTANCE};
end
