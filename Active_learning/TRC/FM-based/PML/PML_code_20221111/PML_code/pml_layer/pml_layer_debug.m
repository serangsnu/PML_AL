substrate_mode='off';
substrate_upper=1; 
%substrate_upper='n_1_5';
layer(1).upper=1.5;
layer(1).material=1.5;
layer(1).thickness=30;
layer(2).material='Vacuum';
layer(2).thickness=30;
layer(2).down='Vacuum';


wavelength=515;
theta=20;
which_pol='s-pol'

[detail_layer kx wavelength]=pml_layer2detail(layer, substrate_mode ,substrate_upper ,wavelength ,theta)
output=pml_core_cal(detail_layer,wavelength,kx,which_pol);
output=pml_cal_eff_R_T(output)