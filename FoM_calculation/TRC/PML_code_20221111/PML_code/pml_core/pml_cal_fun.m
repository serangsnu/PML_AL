function output=pml_cal_fun(layer, substrate_mode ,substrate_upper ,wavelength ,theta,which_pol)
[detail_layer kx wavelength subs_coeff]=pml_layer2detail(layer, substrate_mode ,substrate_upper ,wavelength ,theta,which_pol);
output=pml_core_cal(detail_layer,wavelength,kx,which_pol,subs_coeff);
output=pml_cal_eff_R_T(output); 
output=pml_eff_abs(output);