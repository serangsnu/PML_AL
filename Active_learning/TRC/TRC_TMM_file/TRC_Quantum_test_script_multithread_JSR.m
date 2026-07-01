function [FOM]=TRC_Quantum_test_script_multithread_JSR(digital_vector)
%clear all
% Assigned digital vector (it is the input of this function)
% digit=12;% you need to delete this line if you would like to use this script as a function
% qv_random=rand(digit,1); % you need to delete this line if you would like to use this script as a function
% qv_random(qv_random>0.5)=1; % you need to delete this line if you would like to use this script as a function
% qv_random(qv_random<=0.5)=0; % you need to delete this line if you would like to use this script as a function
% clear qv_ii; % you need to delete this line if you would like to use this script as a function
% digital_vector=qv_random; % you need to delete this line if you would like to use this script as a function

addpath(genpath('.\material'))
load solar_irradiance_def.mat

%digital_vector=[0 0 1 1 0 0 1 1];

% Design Parameters
num_digital_vector=length(digital_vector); % number of layers
num_layer=num_digital_vector/2;

% parameters
%thick=2500/num_layer;
thick=20; %nm previous : 10nm. 20nm
theta_region=0:20:80; % wavelength = 0 to 80 deg
weights = cos(theta_region.*pi/180);% weight values from solar intensity
resolution = 2;
wave_region = 300:resolution:2500;
wave_point = length(wave_region);

for ideal=1:wave_point
    if wave_region(ideal)<400
        ideal_T(ideal) = 0;
    elseif (wave_region(ideal)>= 400 & wave_region(ideal)<= 750)
        ideal_T(ideal) = 1;
    else
        ideal_T(ideal) = 0;
    end
    new_s_spec(ideal) = interp1(s_spec.wave,s_spec.spec,wave_region(ideal));
    ideal_trans_energy(ideal) = new_s_spec(ideal).*ideal_T(ideal);
end
% Building-up Nanophotonic Structure
substrate_upper=1.4; % PDMS refractive index
substrate_mode='off'; % we assume there is no-substrate

% %plot
% plot(wave_region,ideal_T,"Color","red",'LineWidth',1.5); hold on;

% Estimation radiation efficiencies of the nanophotonic structure
for tn=1:length(theta_region)
    parfor wn = 1:length(wave_region)

        layer=digital_wave_ref(digital_vector,num_layer,thick,wave_region(wn));
        %PML cal
        which_pol = 's-pol';
        theta=theta_region(tn);
        wavelength=wave_region(wn);
        addpath(genpath("D:\Quantum_supremacy\Active learning code\TRC\TRC_FM\TRC_TMM_file_thickness\PML_code_20221111\PML_code"))
        output=pml_cal_fun(layer, substrate_mode ,substrate_upper ,wavelength ,theta, which_pol);
        Transmittance(wn) = output.T;
        Reflectance(wn) = output.R;
    end

    output_save_s(tn).trans_energy = new_s_spec(1:wave_point).*Transmittance(1:wave_point);
    FOM_theta_s(tn) = sum((output_save_s(tn).trans_energy-ideal_trans_energy).^2)/sum(new_s_spec.^2)*10*weights(tn);

    % %plot
    %     plot(wave_region,Transmittance,'LineWidth',1); hold on;
    %     xlim([300,2500]);
    %     grid on;
    %     grid minor;
    %     xlabel("wavelength (nm)","FontSize",12);
    %     ylabel("Transmission Efficiency","FontSize",12);

end

% FOM calculation (it is the output of this function)
FOM = sum(FOM_theta_s)/length(theta_region);


