function specs = s5980()
    %photodiode is Hamamatsu's S5980. The small 5mm one
    %http://www.hamamatsu.com/jp/en/product/alpha/S/4106/S5981/index.html
    PHOTODIODE_RESPONSIVITY = 0.72; %Grabbed from plot...
    PHOTODIODE_CAPACITANCE = 10E-12;
    PHOTODIODE_RESISTANCE = 1E8; %Not spec'd;
    DARK_CURRENT = 2E-9;
    specs = {PHOTODIODE_RESPONSIVITY, PHOTODIODE_CAPACITANCE, PHOTODIODE_RESISTANCE, DARK_CURRENT};
end
