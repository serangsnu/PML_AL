function sum_d_l=sum_thick(output_layer,init,fin)
leng=length(output_layer);
d_l=zeros(leng,1);
for ll=1:leng
    d_l(ll)=output_layer(ll).thickness;
end
sum_d_l=sum(d_l(init:fin));