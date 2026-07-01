function [QUBO_for_qlm,Bias_for_qlm]=formulate_QUBO_myqlm_SWA(inputFM)
terms_mat=inputFM.wvmat;
size_tm=size(terms_mat);
WW=terms_mat(1,1:size_tm(2));
VV=terms_mat(2:size_tm(1),1:size_tm(2));

vv_sq_dummy=transpose(VV)*VV;
vv_sq=vv_sq_dummy-diag(diag(vv_sq_dummy));
double_ww=diag(2*WW);
QUBO_for_qlm=vv_sq+double_ww;
Bias_for_qlm=2*inputFM.w0;
length_QB=size_tm(2)+1;
Q_plus_B=zeros(length_QB,length_QB-1);
Q_plus_B(1:length_QB-1,:)=QUBO_for_qlm;
Q_plus_B(length_QB,1)=Bias_for_qlm;
xlearncsvsfile = fopen(sprintf('%s_qubo_qlm.txt',inputFM.fntd),'w');
bias_txt = fopen(sprintf('%s_bias.txt',inputFM.fntd),'w');

labelvalue=num2cell(transpose(Q_plus_B));

labeltext='%12.8f ';
for gn=1:length_QB-2
    labeltext=[labeltext '%12.8f '];
end
labeltext=[labeltext '\n'];
fprintf(xlearncsvsfile,labeltext,labelvalue{1:end-length_QB+1});
fprintf(bias_txt,labeltext,labelvalue{end-length_QB+2});

fclose(xlearncsvsfile);
fclose(bias_txt);