global verbose
verbose = 0
% figure
% hold on
% axis([0 6 -15 0]);
% plot(a, desert_ext_model(a));
% plot(a, rural_5km_cloudy_model(a));
% plot(a, rural_23km_cloudy_model(a));
% plot(a, rural_23km_NC_model(a));


laser_tx_power = 1.6; %Watts
%laser_tx_power = 9.25;
tx_divergance_angle = (1.5E-3); %1.5mRad 
%tx_divergance_angle = (1.5E-3).*(2*log(2)).^.5;
%tx_divergance_angle = (1.5E-3); %1.5mRad 

%This converts from a FullWidthHalfMax Measurement to a 1/e^2 angular
%measurement. Currently, the approximation

%Look at pg 23 to get a way to propagate the laser as a gaussian
distance = 430000;
laser_tx_power = 9.25 *.86; %*db2mag(-4.4);
signal_tx = 1;
%Geometeric Decay Of Laser
cone_radius = distance.*tan(tx_divergance_angle/2);
spot_size = (pi*(cone_radius.^2)); 
ideal_power_at_satellite = laser_tx_power./spot_size;
geometeric_signal = ideal_power_at_satellite.*signal_tx
