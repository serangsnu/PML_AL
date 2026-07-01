function [detail_layer kx wavelength subs_coeff]=pml_layer2detail(layer, substrate_mode ,substrate_upper ,wavelength ,theta,mode)
% layer substrate_mode substarte_upper wavelength theta 
nm=1e-9;
k_0=2*pi/(wavelength*nm);
num_layer=length(layer);
detail_layer(1).upper_index=pml_index_fit(layer(1).upper,wavelength);
detail_layer(num_layer).down_index=pml_index_fit(layer(num_layer).down,wavelength);
if strcmp(substrate_mode,'on')
   sub_u=pml_index_fit(substrate_upper,wavelength);
   kx=k_0*sub_u*sin(theta*pi/180);
   subs_coeff=pml_subs_mode_coeff(sub_u,detail_layer(1).upper_index,kx,wavelength,mode);
   detail_layer(1).subs='on';
end
if strcmp(substrate_mode,'off')
   kx=k_0*detail_layer(1).upper_index*sin(theta*pi/180);
   subs_coeff=0;
   detail_layer(1).subs='off';
end
for nl=1:num_layer
    detail_layer(nl).index=pml_index_fit(layer(nl).material,wavelength);
    detail_layer(nl).thickness=layer(nl).thickness;
    detail_layer(nl).name=num2str(layer(nl).material);
end