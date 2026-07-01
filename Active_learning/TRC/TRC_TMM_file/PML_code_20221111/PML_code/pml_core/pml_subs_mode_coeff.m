function subs_coeff=pml_subs_mode_coeff(sub_u,upper_index,kx,wavelength,mode)
%sub_u
%detail_layer(1).upper_index
%kx wavelength
%mode
nm=1e-9;
k_0=2*pi/(wavelength*nm);

dummy_eps=(sub_u)^2;
eps_m=(real(dummy_eps))+1i*abs(imag(dummy_eps));
dummy_eps=(upper_index)^2;
eps_s=(real(dummy_eps))+1i*abs(imag(dummy_eps));

dummy_ks=k_0*upper_index;
dummy_kzs_1=sqrt(dummy_ks^2-kx^2);
kz_s=abs(real(dummy_kzs_1))+1i*abs(imag(dummy_kzs_1));

dummy_km=k_0*sub_u;
dummy_kzm_1=sqrt(dummy_km^2-kx^2);
kz_m=abs(real(dummy_kzm_1))+1i*abs(imag(dummy_kzm_1));

if strcmp(mode,'s-pol')
    R_ms=(kz_m-kz_s)/(kz_m+kz_s);
    T_ms=2*kz_m/(kz_m+kz_s);
    R_sm=(kz_s-kz_m)/(kz_s+kz_m);
    T_sm=2*kz_s/(kz_s+kz_m);
end
if strcmp(mode,'p-pol')
    R_ms=(eps_s*kz_m-eps_m*kz_s)/(eps_s*kz_m+eps_m*kz_s);
    T_ms=2*eps_s*kz_m/(eps_s*kz_m+eps_m*kz_s);
    R_sm=(eps_m*kz_s-eps_s*kz_m)/(eps_m*kz_s+eps_s*kz_m);
    T_sm=2*eps_m*kz_s/(eps_m*kz_s+eps_s*kz_m);
end
subs_coeff.R_ms=R_ms;subs_coeff.T_ms=T_ms;subs_coeff.R_sm=R_sm;subs_coeff.T_sm=T_sm;        
subs_coeff.kz_s=kz_s; subs_coeff.kz_m=kz_m;subs_coeff.eps_m=eps_m;subs_coeff.eps_s=eps_s;
