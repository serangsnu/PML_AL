function [amp_layer eps_layer]=pml_core_cal_transmitt(detail_layer,kz_layer,k_0,num_layer,which_pol)
%input
%detail_layer,kz_layer,k_0,num_layer,s-pol or p-pol
nm=1e-9;
alpha_l=zeros(2,1,num_layer);
beta_l=zeros(2,2,num_layer);
delta_l=zeros(2,2,num_layer);
ab_l=zeros(2,1,num_layer);
fg_l=zeros(2,1,num_layer+1);
exe_l=zeros(num_layer,1);
dummy_eps=(detail_layer(num_layer).down_index)^2;
eps_d=(real(dummy_eps))+1i*abs(imag(dummy_eps));
dummy_eps=(detail_layer(1).upper_index)^2;
eps_u=(real(dummy_eps))+1i*abs(imag(dummy_eps));
if strcmp(which_pol,'s-pol')
    fg_l(:,:,num_layer+1)=[1 ; -kz_layer(num_layer).down/k_0];
end
if strcmp(which_pol,'p-pol')
    fg_l(:,:,num_layer+1)=[1 ; -kz_layer(num_layer).down/(eps_d*k_0)];
end
eps_l=zeros(1,num_layer);
for nl=num_layer:-1:1
    dummy_eps=(detail_layer(nl).index)^2;
    eps_l(nl)=(real(dummy_eps))+1i*abs(imag(dummy_eps));
    if strcmp(which_pol,'s-pol')
        gamma_l=kz_layer(nl).kz/k_0;
    end
    if strcmp(which_pol,'p-pol')
        gamma_l=kz_layer(nl).kz/(k_0*eps_l(nl));
    end
    exe_l(nl)=exp(1i*kz_layer(nl).kz*detail_layer(nl).thickness*nm);
    beta_l(:,:,nl)=[1 1; -gamma_l gamma_l];
    ab_l(:,:,nl)=beta_l(:,:,nl)\fg_l(:,:,nl+1);
    alpha_l(:,:,nl)=[ab_l(1,1,nl) ; ab_l(2,1,nl)*exe_l(nl)];
    delta_l(:,:,nl)=[1 exe_l(nl) ; -gamma_l gamma_l*exe_l(nl)];
    fg_l(:,:,nl)=delta_l(:,:,nl)*alpha_l(:,:,nl);
end
if strcmp(which_pol,'s-pol')
    key=[1 ; -kz_layer(1).upper/k_0];
    T1_R=[fg_l(1,1,1) -1;fg_l(2,1,1) -kz_layer(1).upper/k_0] \key;
end
if strcmp(which_pol,'p-pol')
    key=[1 ; -kz_layer(1).upper/(eps_u*k_0)];
    T1_R=[fg_l(1,1,1) -1;fg_l(2,1,1) -kz_layer(1).upper/(eps_u*k_0)] \key;
end
T_layer=zeros(num_layer+1,1);
amp_layer(1).R=T1_R(2,1);
T_layer(1)=T1_R(1,1);
for nl=1:num_layer   
    PQ_l=alpha_l(:,:,nl)*T_layer(nl);
    amp_layer(nl).P=PQ_l(1,1);
    amp_layer(nl).Q=PQ_l(2,1);
    T_layer(nl+1)=exe_l(nl)*T_layer(nl);
end
amp_layer(num_layer).T=T_layer(num_layer+1);
eps_layer=[eps_u eps_l eps_d];