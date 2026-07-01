function output=FM_main_JSR(inputFM,flag)
% terms_mat(k_space+1,input_length), input.FOM, input.data
% Defining Weight and Interfaction factor
% flag == 1, learn the model: input.FOM, input.data
% flag == 2, predict the value with 20 bits code: input.data
k_space=inputFM.k_space;
terms_interact=inputFM.w2;
terms_linear = inputFM.w1;
omega_0 = inputFM.w0;

if flag == 1

elseif flag == 2
    
    input_data=transpose(inputFM.data);
    size_input_data=size(input_data);
    input_length=size_input_data(1);
    WW=terms_linear;
    VV=terms_interact;

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
    
    WW=terms_linear;
    VV=terms_interact;
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
