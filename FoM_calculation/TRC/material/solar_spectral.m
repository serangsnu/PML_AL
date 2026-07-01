clear all
addpath(genpath('C:\Users\skim53\Desktop\01. Research\05. Transparent radiative cooling\PML_code'));
solar=xlsread('astmg173.xls');     % 1
% s_spec(1,:)=interp1(transpose(solar(1:1662,1))*1,transpose(solar(1:1662,3)),[300:2500]);
% plot([300:2500],s_spec);
% xlabel('Wavelength (nm)')
% ylabel('Solar spectral irradiance (Wm^2 nm^-1)')
% xlim([300 2500])

UV = sum(s_spec(300-300+1:399-300+1)); % UV
Vis = sum(s_spec(400-300+1:750-300+1)); % Vis
NIR_A = sum(s_spec(751-300+1:1000-300+1)); % NIR_A 750 - 1000
NIR_B = sum(s_spec(1001-300+1:1500-300+1)); % NIR_B 1001 - 1500
NIR_C = sum(s_spec(1501-300+1:2500-300+1)); % NIR_C 1501 - 2500
total_solar = UV+Vis+NIR_A+NIR_B+NIR_C;

UV_e = UV/total_solar*100;
Vis_e = Vis/total_solar*100;
NIR_A_e = NIR_A/total_solar*100;
NIR_B_e = NIR_B/total_solar*100;
NIR_C_e = NIR_C/total_solar*100;