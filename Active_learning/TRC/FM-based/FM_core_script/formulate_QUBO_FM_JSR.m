function [QUBO_for_qlm,Bias_for_qlm]=formulate_QUBO_FM_JSR(inputFM)

%inputFM = FM_hyperparameter;


%import latent vector
terms_interact=inputFM.w2;
terms_linear = inputFM.w1;
bias = inputFM.w0;

%seperate interaction term for each field
size_interact = size(terms_interact); %[k,num_of bits]
num_field = size_interact(2)/length(terms_linear);
num_bits = length(terms_linear);


if num_field ==1
    vv_sq_dummy=transpose(terms_interact)*terms_interact;
    vv_sq=vv_sq_dummy-diag(diag(vv_sq_dummy)); %interaction terms without diag components.
    double_ww=diag(terms_linear); 
    QUBO_for_qlm=vv_sq+double_ww;
    QUBO_for_qlm=triu(QUBO_for_qlm); 
    Bias_for_qlm=bias;

else 
    QUBO_for_qlm = zeros(num_bits,num_bits);
    double_ww = diag(terms_linear);
    QUBO_for_qlm = QUBO_for_qlm+double_ww;
    Bias_for_qlm = bias;

    for i=1:num_bits
        parfor j = i+1:num_bits
            f_2 = field_index(j); %field of vj
            f_1 = field_index(i); %field of vi

            v_i = terms_interact(:,num_field*(i-1)+1+f_2);
            v_j = terms_interact(:,num_field*(j-1)+1+f_1);
            QUBO_for_qlm(i,j) = transpose(v_i)*v_j;
        end
    end
end

xlearncsvsfile = fopen(sprintf('%s_qubo_qlm.txt',inputFM.fntd),'w');
bias_txt = fopen(sprintf('%s_bias.txt',inputFM.fntd),'w');

formatString = '%12.8f ';
for i = 1:size(QUBO_for_qlm, 1)
    fprintf(xlearncsvsfile, formatString, QUBO_for_qlm(i, :));
    fprintf(xlearncsvsfile, '\n'); % Move to the next line after each row
end

fprintf(bias_txt,formatString,Bias_for_qlm);
fclose(xlearncsvsfile);
fclose(bias_txt);

