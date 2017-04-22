function specs = s5981()
    %photodiode is Hamamatsu's S5981. The 10mm one
    %http://www.hamamatsu.com/jp/en/product/alpha/S/4106/S5981/index.html
    PHOTODIODE_RESPONSIVITY = 0.72; %Grabbed from plot...
    PHOTODIODE_CAPACITANCE = 35E-12;
    PHOTODIODE_RESISTANCE = 1E8; %Not spec'd;
    DARK_CURRENT = 4E-9;% 4nA
    specs = {PHOTODIODE_RESPONSIVITY, PHOTODIODE_CAPACITANCE, PHOTODIODE_RESISTANCE, DARK_CURRENT};
end
