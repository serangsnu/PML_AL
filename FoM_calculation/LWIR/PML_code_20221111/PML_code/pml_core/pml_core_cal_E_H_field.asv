function [E_s_pol H_s_pol which_pol]=pml_core_cal_E_H_field(amp_layer,num_layer,which_pol,kz_layer,kx,k_0,eps_layer,subs_coeff,subs_mode)
% amp_layer,num_layer,which_pol,kz_layer,kx,k_0,eps_layer
mhu_0=1.256637061*1e-6;
eps_0=8.854187817*1e-12;
eps_u=eps_layer(1);
eps_l=eps_layer(2:num_layer+1);
eps_d=eps_layer(num_layer+2);

if strcmp(which_pol,'s-pol')
    %% s-pol
    imp=1i*sqrt(mhu_0/eps_0);
    E_s_pol=amp_layer;
    E_s_pol(1).inc=1;
    if strcmp(subs_mode,'off')
        H_s_pol(1).inc=(1/imp)*1i*1/(k_0)*[-kz_layer(1).upper kx]*E_s_pol(1).inc;
    end
    if strcmp(subs_mode,'on')
        H_s_pol(1).inc=(1/imp)*1i*1/(k_0)*[-subs_coeff.kz_m kx]*E_s_pol(1).inc;
    end
    H_s_pol(1).R=(1/imp)*1i*(1/k_0)*[kz_layer(1).upper kx]*E_s_pol(1).R;
    H_s_pol(num_layer).T=(1/imp)*1i*(1/k_0)*[-kz_layer(num_layer).down kx]*E_s_pol(num_layer).T;
    for nl=1:num_layer
        H_s_pol(nl).P=(1/imp)*1i*(1/k_0)*[-kz_layer(nl).kz kx]*E_s_pol(nl).P;
        H_s_pol(nl).Q=(1/imp)*1i*(1/k_0)*[kz_layer(nl).kz kx]*E_s_pol(nl).Q;
    end
end
if strcmp(which_pol,'p-pol')
    %% p-pol
    imp=1i*sqrt(mhu_0/eps_0);
    H_s_pol=amp_layer;
    H_s_pol(1).inc=1;
    if strcmp(subs_mode,'off')
        E_s_pol(1).inc=imp*1i*1/(k_0*eps_u)*[-kz_layer(1).upper kx]*H_s_pol(1).inc;
    end
    if strcmp(subs_mode,'on')
        E_s_pol(1).inc=imp*1i*1/(k_0*subs_coeff.eps_m)*[-subs_coeff.kz_m kx]*H_s_pol(1).inc;
    end
    E_s_pol(1).R=imp*1i*1/(k_0*eps_u)*[kz_layer(1).upper kx]*H_s_pol(1).R;
    E_s_pol(num_layer).T=imp*1i*1/(k_0*eps_d)*[-kz_layer(num_layer).down kx]*H_s_pol(num_layer).T;
    for nl=1:num_layer
        E_s_pol(nl).P=imp*1i*(1/(k_0*eps_l(nl)))*[-kz_layer(nl).kz kx]*H_s_pol(nl).P;
        E_s_pol(nl).Q=imp*1i*(1/(k_0*eps_l(nl)))*[kz_layer(nl).kz kx]*H_s_pol(nl).Q;
    end
end


