% nn=1:0.05:3;
% tt=1:0.5:20;
% for tn=1:length(tt)
%     for nn_n=1:length(nn)
%         tn
%         nn_n
%         substrate_upper=1;
%         substrate_mode='off';
%         
%         layer(1).upper=1;
%         
%         layer(1).material=1.5;
%         layer(1).thickness=50;
%         layer(2).material=1.75;
%         layer(2).thickness=100;
%         layer(3).material=nn(nn_n);
%         layer(3).thickness=tt(tn);
%         layer(4).material=1.75;
%         layer(4).thickness=100;
%         layer(5).material=1.5;
%         layer(5).thickness=50;
%         
%         layer(5).down=1;
%         
%         theta=0;
%         which_pol='s-pol'; %or 'p-pol'
%         wavelength=500;
%         pml_calculation;
%         R(tn,nn_n)=output.R;
%         T(tn,nn_n)=output.T;
%       %  save mydata_20112020 R T tn nn_n
%     end
% end
clear all
substrate_upper=1.5;
substrate_mode='off';

layer(1).upper=1.5;

layer(1).material=1.5;
layer(1).thickness=50;
layer(2).material=1.0;
layer(2).thickness=50;
layer(2).down=1.0;

theta=0;
which_pol='s-pol'; %or 'p-pol'
wavelength=500;
pml_calculation;