function index=pml_index_fit(mater,wavelength)
%layer(nl).material
if isstr(mater)==1
     num_mater=material_def(mater);
     index=pml_material_fit(num_mater,wavelength);
elseif isstr(mater)==0
     index=mater;
end