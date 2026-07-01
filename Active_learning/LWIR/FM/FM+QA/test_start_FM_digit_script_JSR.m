clear all
clc
addpath('./FM_core_script')
addpath('./materials')
input.optimizer='FM_Digit'; % 'FM_digit' : Factorization Machine
input.type='Digit';


input.filename_header='IRAR_TRC_test_script'; 
input.FOM_script='IRAR_TRC_test_script'; %filename of TMM script, the name can be changed: you can edit the way you want. =

% binary vector length
input.number_of_variables=17; % The number of input variables to the FM surrogate function
% Optimization Options

input.fm_optimizer='quantum_annealing'; %tensor_brute_force 
input.global_optimization_options=[2,17]; % for tensor_brute_force, [state level, size of junk], State level: 2 = binary, Junk size = n ==> 2^n for a single junk
%input.fm_optimizer='simulated_annealing'; %simulated_annealing

input.number_of_batches=5; % The number of training batches
input.number_of_initial_dataset=25; % The number of initial training dataset

input.ratio_of_cross_validation_set=0.2; % The ratio assigned to the cross-validation-set in dataset 
input.sampling_tag=100;
input.csv_mode='on';
input.number_of_optimization_cycles=1000; % The number of optimization cycles per batches with the initial dataset 

%%%%
outputlog=ml_opt_main_SWA(input);
%%%%

