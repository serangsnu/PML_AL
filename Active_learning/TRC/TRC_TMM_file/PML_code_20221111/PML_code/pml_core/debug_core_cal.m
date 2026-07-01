% debugging mode
% input variables 
substrate_mode='off';
substrate_upper=1;
layer(1).upper=1;
layer(1).material=1;
layer(1).thickness=30;
layer(1).down=1.5;


wavelength=400;
which_pol='s-pol';
count=0;
tic
for tt=0:1:89
    count=count+1;
    theta=tt;
    pml_calculation
    der(count)=output.R;
    det(count)=output.T;
end
