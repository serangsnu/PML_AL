function [E_sq_time vector_z]=pml_fields_E_sq_single_time(nlayer,output,time_phase)  
nm=1e-9;
E_fields=output.fields{1};
H_fields=output.fields{2};
input.kz=output.k{2}(nlayer).kz;
input.P=output.fields{1}(nlayer).P;
input.Q=output.fields{1}(nlayer).Q;
input.d_l_1=(sum_thick(output.layer,1,nlayer-1))*nm;
input.d_l=(sum_thick(output.layer,1,nlayer))*nm;
input.eps=output.eps(1+nlayer);

z_l=input.d_l;
z_l_1=input.d_l_1;
delta_z=0.1*nm;
vector_z=z_l_1:delta_z:z_l;
E_xyz_time=real(pml_fields_core(vector_z,input)*time_phase);
if strcmp(output.layer(1).subs,'off')
   E_sq_time=sum((E_xyz_time).^2);
elseif strcmp(output.layer(1).subs,'on')
    R_ms=output.subs_coeff.R_ms;
    R_sm=output.subs_coeff.R_sm;
    T_ms=output.subs_coeff.T_ms;
    T_sm=output.subs_coeff.T_sm;
    if strcmp(output.fields_pol,'p-pol')
        coeff_subs=(1/(1-abs(H_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2;
        E_sq_time=coeff_subs*sum((E_xyz_time).^2);
    elseif strcmp(output.fields_pol,'s-pol')
        coeff_subs=(1/(1-abs(E_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2;
        E_sq_time=coeff_subs*sum((E_xyz_time).^2);
    end
end
