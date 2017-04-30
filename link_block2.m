%% SSI-Sat0.5 Optical Link Budget
% FOR SERIOUS THIS TIME
% April 22nd
% Michael Taylor

% Parameters
T = 300;
k = 1.38065e-23;
q = 1.602e-19;

% Background upwelling radiance
B_lambda_976 = 0.013; % worst case earth reflection
orbit_dist_min = 575e3; % distance straight overhead 0deg zenith ~600km
orbit_dist_max = 1000e3; % max distance at 65deg zenith ~1000km

% Beacon Transmit Characteristics
lambda_tx = 976e-9; % 976nm beacon from JPL
div_tx_e2 = 1.5e-3; % 1.1mrad FW1/e^2 beam div.
div_tx = div_tx_e2; % shorter var name, can swap with HWHM if added later.
Ptx = 9.25; % 9.25 W out
Ltx = 10^(-4.4/10); % 4.4dB optical loss out of beacon telescope.
Ptx_eff = Ptx*Ltx;

% Receiver Characteristics
r_rx = 25e-3; % 25mm.
A_rx = pi*r_rx.^2;
A_rx_eff = A_rx*3/4; % Secondary mirror of telescope blocks ~1/4th of useable aperture area
A_rx_eff_cm2 = A_rx_eff*10000; % Receiver effective area in cm^2
theta_HFOV_deg = 1; % Half Field of View in degrees
theta_HFOV_rad = theta_HFOV_deg*pi/180;
solid_angle_rx = 2*pi*(1-cos(theta_HFOV_rad)); % Receiver FOV solid angle
delta_lambda_opt_um = 0.01; % 10nm optical filter
Lrx = 10^(-3/10); % 3db optical loss in Rx

% Calculate background radiance
P_background = B_lambda_976*solid_angle_rx*A_rx_eff_cm2*delta_lambda_opt_um;

% Background Intensity at aperture
I_background = P_background/A_rx_eff;

% Beacon Intensity at aperture
r_spot = (div_tx/2)*orbit_dist_min;
A_spot = pi*r_spot.^2;
I_spot = 2*0.86*Ptx_eff/A_spot; % x2 for gaussian peak vs avg scaling

Latmo = 10^(-3/10); % 3dB atmospheric loss
Lpoint = 10^(-3/10); % 3dB pointing / jitter loss

Prx_ap = I_spot*A_rx_eff; % Power available at receiver aperture
Prx = Prx_ap*Lrx*Latmo*Lpoint % Power collected by receiver aperture (incl losses)

Prx_bg = I_background*A_rx_eff; % Background power at receiver aperture
Pbg = Prx_bg*Lrx*Latmo*Lpoint % BG Power collected by receiver aperture (incl losses)



sigma_th_2 = 4*k*T*Fn*delta_f/Rl;
sigma_shot_2 = 2*q*(R*Prx+i_dark)*delta_f;

SNR = ((R*Prx)^2) / (sigma_th_2 + sigma_shot_2);
SNR_dB = 10*log10(SNR);