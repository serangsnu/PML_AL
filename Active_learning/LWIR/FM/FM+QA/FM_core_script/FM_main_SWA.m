function output=FM_main_SWA(inputFM,flag)
% terms_mat(k_space+1,input_length), input.FOM, input.data
% Defining Weight and Interfaction factor
% flag == 1, learn the model: input.FOM, input.data
% flag == 2, predict the value with 20 bits code: input.data
k_space=inputFM.k_space;
omega_0=inputFM.w0;
terms_mat=inputFM.wvmat;
if flag == 1
%     A_true=inputFM.FOM;
%     size_A_true=size(A_true);
%     sample_number=size_A_true(1);
%     
%     input_data=transpose(inputFM.data);
%     size_input_data=size(input_data);
%     input_length=size_input_data(1);
%     
%     WW=terms_mat(1,1:input_length);
%     VV=terms_mat(2:k_space+1,1:input_length);
%     % Defining Loss Function
%     % linear term
%     Lw_term=WW*input_data;
%     % Interaction term
%     Iv_term=0.5*sum((VV*input_data).^2-((VV.^2)*(input_data.^2)));
%     lambda=0.001;
%     % L2 term to prevent overfitting
%     L2_term=lambda*sum(WW.^2)+lambda*sum(sum(VV.^2));
%     % Defining errorfundtion
%     A_prime=omega_0+Lw_term+Iv_term;
%     Error_val=sum((A_prime-A_true).^2)/sample_number;
%     % Defining loss function
%     Loss_fun=Error_val+L2_term;
%     output=Loss_fun;
    %display(sprintf('Loss %0.4e, MSE %0.4e',Loss_fun,Error_val))
elseif flag == 2
    %input_data=transpose(inputFM.data);
    input_data=transpose(inputFM.data);
    size_input_data=size(input_data);
    input_length=size_input_data(1);
    WW=terms_mat(1,1:input_length);
    VV=terms_mat(2:k_space+1,1:input_length);
    % Defining Loss Function
    % linear term
    Lw_term=WW*input_data;
    % Interaction term
    Iv_term=0.5*sum((VV*input_data).^2-((VV.^2)*(input_data.^2)));    
    A_prime=omega_0+Lw_term+(Iv_term);
    output=A_prime;
elseif flag == 3
    A_true=inputFM.FOM;
    size_A_true=size(A_true);
    sample_number=size_A_true(2);
    
    input_data=transpose(inputFM.data);
    size_input_data=size(input_data);
    input_length=size_input_data(1);
    
    WW=terms_mat(1,1:input_length);
    VV=terms_mat(2:k_space+1,1:input_length);
    % Defining Loss Function
    % linear term
    Lw_term=WW*input_data;
    % Interaction term
    Iv_term=0.5*sum((VV*input_data).^2-((VV.^2)*(input_data.^2)));
     % Defining errorfundtion
    A_prime=omega_0+Lw_term+Iv_term;
    MSE=sum((A_prime-A_true).^2)/sample_number;
    % Defining loss function
    display(sprintf('MSE %0.4e',MSE))
end
