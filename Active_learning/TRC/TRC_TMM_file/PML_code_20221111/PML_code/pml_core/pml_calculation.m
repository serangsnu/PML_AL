%input variables
%substrate_mode='on' or 'off' 
%substrate_upper= digit number or string. / index of substrate upper
%layer(1).upper= digit number or string.  / index of substrate(if
%substrate_mode=on) , index of semi-infinite medium (if substrate_mode=off)
%layer(nl).material=digit number or string / index of nl_th layer material
%index
%layer(nl).thickness=digit number / thickness of nl_th layer (nm scale)
%wavelength=digit number / Vacuum wavelength of EM
%which_pol=string / s-pol(E_fields // y-axis) or p-pol(H_fields // y-axis)
%theta=digit number / the angle between z-axis and k-vector (degree)

output=pml_cal_fun(layer, substrate_mode ,substrate_upper ,wavelength ,theta,which_pol);