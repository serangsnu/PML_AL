function output=pml_cal_eff_R_T(output)
%output.k, output.fields, output.eps
kz_layer=output.k{2};
kx=output.k{3};
E_fields=output.fields{1};
H_fields=output.fields{2};
num_layer=length(kz_layer);
mhu_0=1.256637061*1e-6;
eps_0=8.854187817*1e-12;
if strcmp(output.layer(1).subs,'off')
    inc_flux=real(kz_layer(1).upper)*sum(abs(E_fields(1).inc).^2);
    R_flux=real(kz_layer(1).upper)*sum(abs(E_fields(1).R).^2);
    T_flux=real(kz_layer(num_layer).down)*sum(abs(E_fields(num_layer).T).^2);
    output.R=R_flux/inc_flux;
    output.T=T_flux/inc_flux;
elseif strcmp(output.layer(1).subs,'on')
    R_ms=output.subs_coeff.R_ms;
    R_sm=output.subs_coeff.R_sm;
    T_ms=output.subs_coeff.T_ms;
    T_sm=output.subs_coeff.T_sm;
    inc_flux=real(output.subs_coeff.kz_m)*sum(abs(E_fields(1).inc).^2);
    if strcmp(output.fields_pol,'p-pol')
        imp_sq=mhu_0/eps_0;
        k_vector_ratio_up=(abs(output.subs_coeff.kz_m)^2+abs(kx)^2)/(abs(output.subs_coeff.kz_m^2+kx^2));
        k_vector_ratio_down=(abs(kz_layer(num_layer).down)^2+abs(kx)^2)/(abs(kz_layer(num_layer).down^2+kx^2));
        H_sq_r=abs(R_ms)^2+(abs(T_ms)^2*abs(T_sm)^2*abs(H_fields(1).R)^2)/(1-abs(H_fields(1).R)^2*abs(R_sm)^2);
        H_sq_t=(1/(1-abs(H_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2*abs(H_fields(num_layer).T)^2;
        R_flux=real(output.subs_coeff.kz_m)*H_sq_r*imp_sq*(1/abs(output.subs_coeff.eps_m))*k_vector_ratio_up;
        T_flux=real(kz_layer(num_layer).down)*H_sq_t*imp_sq*(1/abs(output.eps(num_layer+2)))*k_vector_ratio_down;
    elseif strcmp(output.fields_pol,'s-pol')
        E_sq_r=abs(R_ms)^2+(abs(T_ms)^2*abs(T_sm)^2*abs(E_fields(1).R)^2)/(1-abs(E_fields(1).R)^2*abs(R_sm)^2);
        E_sq_t=(1/(1-abs(E_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2*abs(E_fields(num_layer).T)^2;
        R_flux=real(output.subs_coeff.kz_m)*E_sq_r;
        T_flux=real(kz_layer(num_layer).down)*E_sq_t;
    end
    output.R=R_flux/inc_flux;
    output.T=T_flux/inc_flux;
end