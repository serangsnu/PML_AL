function layer=digital_wave_ref(digital_vector,num_layer,thick,wavelength)

load Al2O3.mat
load Si3N4.mat
load SiO_2.mat
load TiO2.mat
load solar_irradiance_def.mat

%upper&down setting
for j = 1:num_layer
    layer(1).upper=1.4; % PDMS
    layer(j).thickness=thick;
    layer(num_layer).down=1.45; % SiO2 subsrate
end
%material setting
for i = 1:num_layer
    layer_mater(i) = bi2de(digital_vector(2*i-1:2*i),'left-msb');

end

%material indexing
for i = 1:num_layer
    if layer_mater(i)==0
        layer(i).material=interp1(SiO_2.wave,SiO_2.n,wavelength)+1i*interp1(SiO_2.wave,SiO_2.k,wavelength);
        Layer_tag{i}='SiO2';

    elseif layer_mater(i)==1
        layer(i).material=interp1(Si3N4.wave,Si3N4.n,wavelength)+1i*interp1(Si3N4.wave,Si3N4.k,wavelength);
        Layer_tag{i}='Si3N4';

    elseif layer_mater(i)==2
        layer(i).material=interp1(Al2O3.wave,Al2O3.n,wavelength)+1i*interp1(Al2O3.wave,Al2O3.k,wavelength);
        Layer_tag{i}='Al2O3';

    elseif layer_mater(i)==3
        layer(i).material=interp1(TiO2.wave,TiO2.n,wavelength)+1i*interp1(TiO2.wave,TiO2.k,wavelength);
        Layer_tag{i}='TiO2';
    end
end