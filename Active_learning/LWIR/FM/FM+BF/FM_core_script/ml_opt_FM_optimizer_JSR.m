load(sprintf('%s.mat',fntd))

% FM parameters
 get_size_qv=size(qv_ii_array);
 qv_length=get_size_qv(2);
 inputFM.data=qv_ii_array;
 inputFM.FOM=FOM;
 inputFM.k_space=8;
 inputFM.lr=0.001;
 inputFM.b=0.001;
 inputFM.epoch=20000;
 inputFM.fntd=fntd;
    
 
% Learn FM
FM_time = tic;
inputFM=FM_xlearn_cv_ml_SWA(inputFM);
caltime_fm=toc(FM_time);
caltime_fm_array(in-24)=caltime_fm;%  fm 측정 시간
%% four Model_Testing_Methods 
% 1. if "simulated_annealing"
% 2. else if "quantum_annealing"
% 3. else if "brute_force"
%%
if strcmp(input.fm_optimizer,'simulated_annealing')
    %% Predict Global minimum with Simulated Annealing
    % Formulate QUBO matrix for d:wave neal
    [QUBO_for_qlm,Bias_for_qlm]=formulate_QUBO_myqlm_SWA(inputFM);
    SA_time = tic;
    [os,oi]=system(sprintf('C:\\Users\\JungSR\\miniconda3\\envs\\JSR_Guinness\\python -c "from simul_annealing_matlab import d_simul; d_simul(%s)"',[char(39) fntd char(39)]));        %% Predict Global minimum 
    caltime_SA=toc(SA_time);
    caltime_SA_array(in-24)=caltime_SA;

    caltime=[caltime_fm_array;caltime_SA_array];
    save('cal_fm_SA_time.mat', 'caltime');
 %   x0_candidates = x0_txtimport_SWA(sprintf('x0_%s_qubo_qlm.txt',fntd),qv_length);%%%지워 

    QA_answer= x0_txtimport_SWA(sprintf('simul_OptimizedData.txt'),qv_length);

    FOM_predict_gmin_qa= dlmread('simul_FOM.txt');
    qv_gmin_qa=QA_answer;

    opt_file = fopen(sprintf('opt_%s.txt',fntd),'w');
    labelvalue=num2cell(([FOM_predict_gmin_qa, qv_gmin_qa]));
    labeltext='%12.8f \n';
    fprintf(opt_file,labeltext,labelvalue{:});
    fclose(opt_file);

    if ismac
        dos(sprintf('rm x0_%s_qubo_qlm.txt ',fntd));
        dos(sprintf('rm %s_qubo_qlm.txt ',fntd));
    elseif isunix
        % Code to run on Linux platform
    elseif ispc%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 여기 수정했어    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del x0_%s_qubo_qlm.txt',fntd));
        [oi,oy]=system(sprintf('del %s_qubo_qlm.txt',fntd));
        [oi,oy]=system(sprintf('del %s_bias.txt',fntd));%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del simul_FOM.txt'));%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del simul_OptimizedData.txt'));%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        disp('Platform not supported')
    end


elseif strcmp(input.fm_optimizer,'quantum_annealing')
        %% Predict Global minimum with Quantum Annealing using d:wave cloud service
    % Formulate QUBO matrix for myQlm
    [QUBO_for_qlm,Bias_for_qlm]=formulate_QUBO_myqlm_SWA(inputFM);
    QA_time= tic;
    [os,oi]=system(sprintf('C:\\Users\\JungSR\\miniconda3\\envs\\ocean_JSR\\python -c "from qubo_dimod import qubo_run; qubo_run(%s)"',[char(39) fntd char(39)]));        %% Predict Global minimum 

    caltime_QA=toc(QA_time);
    caltime_QA_array(in-24)=caltime_QA;
    caltime=[caltime_fm_array;caltime_QA_array];
    save('cal_fm_QA_time.mat', 'caltime');

    QA_answer= x0_txtimport_SWA(sprintf('OptimizedData.txt'),qv_length);


    FOM_predict_gmin_qa= dlmread('fom.txt');
    qv_gmin_qa=QA_answer;

    opt_file = fopen(sprintf('opt_%s.txt',fntd),'w');
    labelvalue=num2cell(([FOM_predict_gmin_qa, qv_gmin_qa]));
    labeltext='%12.8f \n';
    fprintf(opt_file,labeltext,labelvalue{:});
    fclose(opt_file);

    if ismac
        dos(sprintf('rm x0_%s_qubo_qlm.txt ',fntd));
        dos(sprintf('rm %s_qubo_qlm.txt ',fntd));
    elseif isunix
        % Code to run on Linux platform
    elseif ispc%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 여기 수정했어    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del x0_%s_qubo_qlm.txt',fntd));
        [oi,oy]=system(sprintf('del %s_qubo_qlm.txt',fntd));
        [oi,oy]=system(sprintf('del %s_bias.txt',fntd));%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del FOM.txt'));%%%%%%%%%%%%%
        [oi,oy]=system(sprintf('del OptimizedData.txt'));%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        disp('Platform not supported')
    end


elseif strcmp(input.fm_optimizer,'tensor_brute_force')
    BF_time = tic;
    %% Predict Global minimum with Tensor Brute Force for FM
    deci_array=transpose([1:2^qv_length]-1);
    buffer_number=input.global_optimization_options(1)^input.global_optimization_options(2);
    junk_number=length(deci_array)/buffer_number;
    clear FOM_predict_gmin_buffer
    clear qv_gmin_buffer
    
    for jn=1:junk_number
        
        jn
        inputGFM.data=de2bi(deci_array((jn-1)*buffer_number+1:(jn)*buffer_number),qv_length);
        inputGFM.k_space=inputFM.k_space;
        inputGFM.wvmat=inputFM.wvmat;
        inputGFM.w0=inputFM.w0;
        FOM_predict_dummy=FM_main_SWA(inputGFM,2);
        FOM_predict_gmin_buffer(jn)=min(FOM_predict_dummy);
        qv_gmin_buffer(jn,:)=inputGFM.data(FOM_predict_gmin_buffer(jn)==FOM_predict_dummy,:);
        clear FOM_predict_dummy
   
    end
   
    FOM_predict_gmin_tbf=min(FOM_predict_gmin_buffer);
    qv_gmin_tbf=qv_gmin_buffer(FOM_predict_gmin_tbf==FOM_predict_gmin_buffer,:);
    caltime_Brute=toc(BF_time);
    caltime_Brute_array(in-24)=caltime_Brute;
    opt_file = fopen(sprintf('opt_%s.txt',fntd),'w');
    labelvalue=num2cell(([FOM_predict_gmin_tbf, qv_gmin_tbf]));
    labeltext='%12.8f \n';
    fprintf(opt_file,labeltext,labelvalue{:});
    fclose(opt_file);
    
    if ismac
        dos('rm *.model');
    elseif isunix
        % Code to run on Linux platform
    elseif ispc
        
    else
        disp('Platform not supported')
    end
    caltime=[caltime_fm_array;caltime_Brute_array];
    save('cal_fm_brute_time.mat', 'caltime');
end