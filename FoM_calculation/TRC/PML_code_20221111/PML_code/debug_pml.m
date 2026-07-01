clear all
wave=900;
angle=0:90;
for an=1:length(angle)
    
substrate_mode='off';
substrate_upper=1.0;
layer(1).upper=1.0;
layer(1).material=1.5;
layer(1).thickness=100;
layer(1).down=1.5;

theta=angle(an);
which_pol='p-pol'; %(or p-pol);
wavelength=wave; 
pml_calculation;
ref(an)=output.R(1)
trs(an)=output.T(1)

end


% wave=100:10:1000;
% for wn=1:length(wave)
%     
% substrate_mode='on';
% substrate_upper=1.5;
% layer(1).upper=1.5;
% layer(1).material=1;
% layer(1).thickness=100;
% layer(1).down=1;
% 
% theta=0;
% which_pol='p-pol'; %(or p-pol);
% wavelength=wave(wn); 
% pml_calculation;
% ref(wn)=output.R(1)
% trs(wn)=output.T(1)
% 
% end
% 

% substrate_mode='on';
% substrate_upper=1;
% layer(1).upper=1.7;
% layer(1).material=1.7;
% layer(1).thickness=100;
% layer(2).material=2.35+1i*0.0064;
% layer(2).thickness=500;
% layer(2).down=1;
% theta=00;
% which_pol='s-pol'; %(or p-pol);
% wavelength=800; 
% pml_calculation;
% %pml_fields_E_sq(output);
% output.ABS(1)
% output.ABS(2)
% % 
% substrate_mode='off';
% substrate_upper=1;
% layer(1).upper=1;
% layer(1).material=1;
% layer(1).thickness=100;
% layer(2).material='Al';
% layer(2).thickness=100;
% layer(2).down=1;
% theta=00;
% which_pol='s-pol'; %(or p-pol);
% wavelength=400; 
% pml_calculation;
% output.ABS(2)