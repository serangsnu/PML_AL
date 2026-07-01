% Perform optimizer
if strcmp(optimizer,'BO')==1
    %dos(sprintf('/Users/eungkyulee/opt/miniconda3/envs/pymc3_env/bin/python -c "from BO_main_in%d import run_BO_scriptfun; run_BO_scriptfun(%s,%d,%0.1f)"',number_of_variables,[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    display('not supported')
elseif strcmp(optimizer,'BO_Digit')==1
    %dos(sprintf('/Users/eungkyulee/miniconda3/envs/sklearn_env/bin/python -c "from BO_digit_main_CYP import run_BO_digit_scriptfun; run_BO_digit_scriptfun(%s,%d,%0.1f)"',[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    %dos(sprintf('/Users/eungkyulee/miniconda3/envs/sklearn_env/bin/python -c "from BO_digit_main import run_BO_digit_scriptfun; run_BO_digit_scriptfun(%s,%d,%0.1f)"',[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    display('not supported')

elseif strcmp(optimizer,'FCNN')==1
    % FCNN: Neural Network with Pytorch to obtain the optimal vector
    %dos(sprintf('/Users/eungkyulee/opt/miniconda3/envs/torch_env/bin/python -c "from FCNN_main_in%d import run_NN_scriptfun; run_NN_scriptfun(%s,%d,%0.1f)"',number_of_variables,[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    display('not supported')

elseif strcmp(optimizer,'FCNN_Digit')==1
    % FCNN: Neural Network with Pytorch to obtain the optimal vector
    %dos(sprintf('/Users/eungkyulee/opt/miniconda3/envs/torch_env/bin/python -c "from FCNN_digit_main import run_NN_digit_scriptfun; run_NN_digit_scriptfun(%s,%d,%d)"',[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    display('not supported')

elseif strcmp(optimizer, 'FM')==1
    % FM: Factorization Machine with Xlearn to obtain the optimal vector
    %[oi,oy]=system(sprintf('/Users/eungkyulee/opt/miniconda3/envs/xl_env/bin/python -c "from FM_main_in%d import run_FM_scriptfun; run_FM_scriptfun(%s,%d,%0.1f)"',number_of_variables,[char(39) fntd char(39)],global_optimization_options(1),global_optimization_options(2)));
    display('not supported')

elseif strcmp(optimizer, 'FM_Digit')==1
    ml_opt_FM_optimizer_JSR
end 