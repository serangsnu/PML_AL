function Vec_xyz=pml_fields_core(z,input)
%z,input ; all length scale 'm';
%input.P input.Q input.d_l_1 input.d_l input.kz
kz=input.kz;
P=input.P;
Q=input.Q;
d_l=input.d_l;
d_l_1=input.d_l_1;
size_z=length(z);
phase_p=exp(1i*kz*(z-d_l_1));
phase_q=exp(-1i*kz*(z-d_l));
length_mode=length(P);
Pxyz=zeros(length_mode+1,size_z);
Qxyz=zeros(length_mode+1,size_z);
P(length_mode+1)=0;
Q(length_mode+1)=0;
for lm=1:length_mode
    Pxyz(lm,:)=P(lm)*phase_p;
    Qxyz(lm,:)=Q(lm)*phase_q;
end
Vec_xyz=Pxyz+Qxyz;
