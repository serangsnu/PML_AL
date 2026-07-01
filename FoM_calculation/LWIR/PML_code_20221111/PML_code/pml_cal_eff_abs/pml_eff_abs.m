function output=pml_eff_abs(output)
%output
nm=1e-9;
mhu_0=1.256637061*1e-6;
c_speed=299792458;
k_0=output.k{1};
kz_layer=output.k{2};
E_fields=output.fields{1};
H_fields=output.fields{2};
num_layer=length(output.layer);
abs_layer=zeros(1,num_layer);
if strcmp(output.layer(1).subs,'off')
    inc_flux=(1/2)*(1/(c_speed*mhu_0*k_0))*real(kz_layer(1).upper)*sum(abs(E_fields(1).inc).^2);
    for nlayer=1:num_layer
        input.kz=output.k{2}(nlayer).kz;
        input.P=output.fields{1}(nlayer).P;
        input.Q=output.fields{1}(nlayer).Q;
        input.d_l_1=(sum_thick(output.layer,1,nlayer-1))*nm;
        input.d_l=(sum_thick(output.layer,1,nlayer))*nm;
        input.eps=output.eps(1+nlayer);
        fun_abs=@(z)pml_cal_abs_fun(z,k_0,input);     
        abs_layer(nlayer)=quadv(fun_abs,input.d_l_1,input.d_l)/inc_flux;
    end    
elseif strcmp(output.layer(1).subs,'on')
   inc_flux=(1/2)*(1/(c_speed*mhu_0*k_0))*real(output.subs_coeff.kz_m)*sum(abs(E_fields(1).inc).^2);
   R_ms=output.subs_coeff.R_ms;
   R_sm=output.subs_coeff.R_sm;
   T_ms=output.subs_coeff.T_ms;
   T_sm=output.subs_coeff.T_sm;                      
   if strcmp(output.fields_pol,'p-pol')
       for nlayer=1:num_layer
           input.kz=output.k{2}(nlayer).kz;
           input.P=output.fields{1}(nlayer).P;
           input.Q=output.fields{1}(nlayer).Q;
           input.d_l_1=(sum_thick(output.layer,1,nlayer-1))*nm;
           input.d_l=(sum_thick(output.layer,1,nlayer))*nm;
           input.eps=output.eps(1+nlayer);
           fun_abs=@(z)pml_cal_abs_fun(z,k_0,input);
           coeff_subs=(1/(1-abs(H_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2;
           abs_layer(nlayer)=coeff_subs*quadv(fun_abs,input.d_l_1,input.d_l)/inc_flux;
       end
   elseif strcmp(output.fields_pol,'s-pol')
       for nlayer=1:num_layer
           input.kz=output.k{2}(nlayer).kz;
           input.P=output.fields{1}(nlayer).P;
           input.Q=output.fields{1}(nlayer).Q;
           input.d_l_1=(sum_thick(output.layer,1,nlayer-1))*nm;
           input.d_l=(sum_thick(output.layer,1,nlayer))*nm;
           input.eps=output.eps(1+nlayer);
           fun_abs=@(z)pml_cal_abs_fun(z,k_0,input);
           coeff_subs=(1/(1-abs(E_fields(1).R)^2*abs(R_sm)^2))*abs(T_ms)^2;
           abs_layer(nlayer)=coeff_subs*quadv(fun_abs,input.d_l_1,input.d_l)/inc_flux;
       end
   end
end    
output.ABS=abs_layer;