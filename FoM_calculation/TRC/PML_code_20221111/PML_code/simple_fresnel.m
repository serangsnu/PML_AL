clear all
substrate_upper=1;
substrate_mode='off';

layer(1).upper=1;
layer(1).material=1;
layer(1).thickness=50;
layer(2).material=1.5;
layer(2).thickness=50;
layer(2).down=1.5;
theta_regime=0:1:89;

for tn=1:length(theta_regime)
    theta=theta_regime(tn)
    which_pol='s-pol'; %or 'p-pol'
    wavelength=500;
    pml_calculation;
    Ref(tn)=output.R;
    Trs(tn)=output.T;
end