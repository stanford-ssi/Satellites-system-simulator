clear 
%Don't set clear all. wipes debug points
close all

%Helpful References:
%http://www.ti.com/lit/an/sboa060/sboa060.pdf
% Walks through the noise calculations of a tia^

%% System Parameters:

global verbose
verbose = 1;

global scenario
scenario = 0;
%0 == worst case, default, conservative.
%1 == typical behavior
%2 == Optimistic. 
global tx_divergance_angle;
global calib_power;
global calib_spot;
calib_spot = 0.004/2; %4mm diameter
tx_divergance_angle = 0.5E-3; %500uRad
%tx_divergance_angle = 1.1E-3; %1.1mRad
global LT_SPICE; %Whether to use LT-spice sims for TIA. (You probably should)
global Rf;
global v_ref;
global safety_factor;
global snr_target;
global Cf; %updated Automatically in TIA block.
LT_SPICE = 0;
safety_factor = 2;
snr_target = 30;
v_ref = 5;
Rf = 500E3;
verbose = 0;

 


%%
%Test Run Through:
        %%
        verbose = 1;
        scenario = 0;
        link_package = link_block(); 
        scenario = 2;
        link_package = link_block(); 
        
        link_package{1} = link_package{1}/4;
        link_package{2} = link_package{2}/4;
        link_package{3} = link_package{3}/4;
        link_package{4} = link_package{4}/4;
        
        %%
        Rf = 6.28E3;
        tia_outputs = tia_block(link_package);
        Cf
        %%
        verbose = 1;
        adc_outputs = adc_block(tia_outputs);
        %%
        final_signal = adc_outputs{1};
        final_noise = adc_outputs{2};
        verbose=1
        %[angle_uncertainty] = quad_block(final_signal, final_noise)

%%
%Get Power values in best and worst case:
    clc    
    tx_divergance_angle = 100E-6;
    tx_divergance_angle = 1.1E-3;
    verbose = 0;
    scenario = 0
    link_package_w = link_block() 
    %sigs_worst = tia_block(link_package_w);
    scenario = 2
    link_package_b = link_block() 
    
    
%%
% Rf System Design:
%Not switching the TIA for the calib Laser.
%Results: Yes; but calib laser must be looow power. Tricky
%otherwise.
        verbose = 0;
        calib_power = 1E-5; %0.1mW;
        
        v_max_calib = 4.5;
        n = 100;
        R_sweep = logspace(0,8,n);
        v_calib = ones(1,n);
        v_calib_s = ones(1,n);
        v_calib_n = ones(1,n);
        v_sum = ones(1,n);
        v_sig_b = ones(1,n);
        v_sig_w = ones(1,n);
        v_noise_b = ones(1,n);
        v_noise_w = ones(1,n);

        for i =1:n
            Rf = R_sweep(i);
            scenario = 0;
            link_package = link_block(); 
            sigs_worst = tia_block(link_package);
            scenario = 2;
            link_package = link_block(); 
            sigs_best = tia_block(link_package);
            calib_package = { calib_power, 0, link_package{3} + link_package{1} + link_package{2}};
            sigs_calib = tia_block(calib_package);
            v_calib(i) = sigs_calib{1}+sigs_calib{2}+sigs_calib{3};
            v_calib_s(i) = sigs_calib{1};
            v_calib_n(i)     = sigs_calib{2};
            v_sum(i) = sigs_best{1}+sigs_best{2}+sigs_best{3};
            v_sig_b(i) = sigs_best{1};
            v_sig_w(i) = sigs_worst{1};
            v_noise_b(i) = sigs_best{2}; %Taking Circuit noise, not system noise.
            v_noise_w(i) = sigs_worst{2};
        end
        %Find order of magnitude of best Rf for coupled calib laser, or
        %switched calib laser:
        [val, ind] = min(abs(v_max_calib-v_calib)); %The 1/4 in safety factor is because we can control the calib laser very well, no need to give it so much dynamic range.
        R_calib = R_sweep(ind);
        [val, ind] = min(abs(v_ref/safety_factor-v_sum));
        R_no_calib = R_sweep(ind);
        R_max_dr = 5E6;
        
        verbose = 1;
        if(verbose)
            figure
            loglog(R_sweep, v_calib);
            hold on;
            loglog(R_sweep, v_sum);
            loglog(R_sweep, v_sig_b);
            loglog(R_sweep, v_noise_b,'-.');
            loglog(R_sweep, v_calib_s);
            loglog(R_sweep, v_calib_n,'-.');
            loglog(R_sweep, v_max_calib.*ones(1,n),'-.');
            loglog(R_sweep, v_ref.*ones(1,n)./safety_factor,'-.');
            loglog(R_calib.*ones(1,n), logspace(-8,5,n));
            loglog(R_no_calib.*ones(1,n), logspace(-8,5,n));
            %loglog(R_max_dr.*ones(1,n), logspace(-8,5,n),'*');

            
            title(['Rf Sensitivity Study, CalibPower: ', num2str(calib_power*1000), 'mW']);
            legend('Calibration', 'BG+Sig Voltage','Best Signal',...
                'Best Noise','Calib Signal','Calib Noise',...
                'Max Vcalib 4.5v','Max Allowable AC signal');
            xlabel('Rf');
            ylabel('Vrms'); %But also Vrms?
            
%             figure
%             loglog(R_sweep, v_calib);
%             hold on;
%             loglog(R_sweep, v_sum);
%             loglog(R_sweep, v_sig_b);
%             loglog(R_sweep, v_noise_b,'-.');
%             loglog(R_sweep, v_sig_w);
%             loglog(R_sweep, v_noise_w,'-.');
%             loglog(R_sweep, v_max_calib.*ones(1,n),'-.');
%             loglog(R_sweep, v_ref.*ones(1,n)./safety_factor,'-.');
%             loglog(R_calib.*ones(1,n), logspace(-8,5,n));
%             loglog(R_no_calib.*ones(1,n), logspace(-8,5,n));
% 
%             title(['Rf Sensitivity Study, CalibPower: ', num2str(calib_power*1000), 'mW']);
%             legend('Calibration', 'BG+Sig Voltage','Best Signal',...
%                 'Best Noise','Worst Signal','Worst Noise',...
%                 'Max Vcalib 4.5v','Max Allowable AC signal');
%             xlabel('Rf');
%             ylabel('V peak'); %But also Vrms?
%             R_calib;
%             R_no_calib;
        end
        
        verbose = 0;
        scenario = 0;
        Rf = R_calib;
        link_package = link_block(); 
        sigs_calib = tia_block(link_package);
        SNR_calib_beacon = mag2db(sigs_calib{1}^2/sigs_calib{4}^2);
        calib_package = { calib_power, 0, link_package{3}};% + link_package{1} + link_package{2}};
        sigs_calib = tia_block(calib_package);
        v_calib_s = sigs_calib{1};
        v_calib_n = sigs_calib{2};
        SNR_calib_laser = mag2db(v_calib_s^2/ v_calib_n^2);
            
        Rf = R_no_calib;
        link_package = link_block(); 
        sigs_no_calib = tia_block(link_package);
        SNR_no_calib_beacon = mag2db(sigs_no_calib{1}^2/sigs_no_calib{4}^2);
        calib_package = { calib_power, 0, link_package{3} + link_package{1} + link_package{2}};
        sigs_calib = tia_block(calib_package);
        v_no_calib_s = sigs_calib{1};
        v_no_calib_n = sigs_calib{2};
        SNR_no_calib_laser = mag2db(v_no_calib_s/ v_no_calib_n);
        
        verbose =1;
        if(verbose==1)
            do_we_switch = {
            calib_power,...
            SNR_calib_beacon,...
            SNR_no_calib_beacon,...
            SNR_no_calib_laser,...
            SNR_calib_laser};
            names = {'calib_power, ','beacon cRf, ','beacon bRf, ','cal cRf, ','cal bRf'}
            do_we_switch
        end
        
%%
%SNR of calib laser
    verbose = 1;
    scenario = 0;
    Rf = R_calib;
    %Rf = 100E3;
    link_package = link_block(); 
    sigs_calib = tia_block(link_package);
    SNR_calib_beacon = mag2db(sigs_calib{1}^2/sigs_calib{4}^2);
    calib_package = { calib_power, 0, link_package{3}};% + link_package{1} + link_package{2}};
    sigs_calib = tia_block(calib_package);
    v_calib_s = sigs_calib{1};
    v_calib_n = sigs_calib{2};
    SNR_calib_laser = mag2db(v_calib_s/ v_calib_n)
        
%%
%System Design:
%Build the rest of the system.
    Rf = R_calib;
    v_ref = 1;
    verbose = 0;
    scenario = 0;
    link_package_w = link_block(); 
    sigs_worst = tia_block(link_package_w);
    scenario = 2
    link_package_b = link_block(); 
    sigs_best = tia_block(link_package_b);
    calib_package = { calib_power, 0, link_package_b{3} + link_package_b{1} + link_package_b{2}};
    sigs_calib = tia_block(calib_package);

    signal_sys_block(sigs_best,sigs_worst, sigs_calib);

