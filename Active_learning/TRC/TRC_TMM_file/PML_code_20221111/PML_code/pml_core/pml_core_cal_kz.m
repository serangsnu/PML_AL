function [kz_layer k_0 num_layer]=pml_core_cal_kz(detail_layer,wavelength,kx)
%input
%detail_layer , wavelength, kx
nm=1e-9;
k_0=2*pi/(wavelength*nm);
num_layer=length(detail_layer);

dummy_ku=k_0*detail_layer(1).upper_index;
dummy_kzu_1=sqrt(dummy_ku^2-kx^2);
dummy_kzu_2=abs(real(dummy_kzu_1))+1i*abs(imag(dummy_kzu_1));
kz_layer(1).upper=dummy_kzu_2;

for nl=1:num_layer
    dummy_kl=k_0*detail_layer(nl).index;
    dummy_kz_1=sqrt(dummy_kl^2-kx^2);
    dummy_kz_2=abs(real(dummy_kz_1))+1i*abs(imag(dummy_kz_1));
    kz_layer(nl).kz=dummy_kz_2;
end

dummy_kd=k_0*detail_layer(num_layer).down_index;
dummy_kzd_1=sqrt(dummy_kd^2-kx^2);
dummy_kzd_2=abs(real(dummy_kzd_1))+1i*abs(imag(dummy_kzd_1));
kz_layer(num_layer).down=dummy_kzd_2;
