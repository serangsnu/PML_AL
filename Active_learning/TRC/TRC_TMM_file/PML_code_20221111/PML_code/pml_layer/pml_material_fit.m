function index=pml_material_fit(varargin)
if length(varargin)==1
    material_num=varargin{1};
    [lambda_data n] = eval(['index_' num2str(material_num)]);
elseif length(varargin)==2
    material_num=varargin{1};
   if imag(material_num)==0
    [lambda_data n] = eval(['index_' num2str(material_num)]);
    n=interp1(lambda_data,n,varargin{2});
   elseif ~(imag(material_num)==0)
    n=eval(['index_' num2str(real(material_num)) '(' num2str(varargin{2}) ')']);  
   end
end
index=abs(real(n))+1i*abs(imag(n));