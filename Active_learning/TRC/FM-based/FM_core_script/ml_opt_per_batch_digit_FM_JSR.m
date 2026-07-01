function output=ml_opt_per_batch_digit_FM_JSR(input,ttn)
% Optimization Parameters
filename_header=input.filename_header;
optimizer=input.optimizer; % string, 'BO' : bayesian optimization, 'FCNN': Fully-connected neural network, 'FM' : Factorization Machine
global_optimization_options=input.global_optimization_options; % {int, float =< 1}
number_of_initial_dataset=input.number_of_initial_dataset; % The number of initial training dataset
ratio_of_cross_validation_set=input.ratio_of_cross_validation_set; % The ratio assigned to the cross-validation-set in dataset
number_of_variables=input.number_of_variables; % The number of input variables to the surrogate function
number_of_optimization_cycles=input.number_of_optimization_cycles; % The number of optimization cycles per batches with the initial dataset
FOM_script=input.FOM_script;

% Pop-up the figure frames
ml_opt_figs_popup_SWA

% Import Dataset
filename=sprintf('%s_%d_%d',filename_header,number_of_variables,ttn);

dos(sprintf('mkdir %s_mat',filename));
dos(sprintf('mkdir %s_traintxt',filename));
fntd=sprintf('%s_%d',filename,number_of_initial_dataset);
if isfield(input,'sampling_tag')==1
    if isfield(input,'csv_mode')==1
        if strcmp(input.csv_mode, 'on')
            %this mode generate cv pool from the training dataset
            AT_mat_2_csv_pool_JSR(sprintf('%s',fntd),ratio_of_cross_validation_set,input.sampling_tag)
            in=number_of_initial_dataset;
            display('csv_mode_on')

        elseif strcmp(input.csv_mode, 'off')
            display('csv_mode_off')
            AT_mat_2_csv_pool_sampling_SWA(sprintf('%s',fntd),input.sampling_tag)
            in=number_of_initial_dataset;
            % generate initial validation dataset,
            givd_biDigit_SWA(round(in*ratio_of_cross_validation_set),number_of_variables,fntd,FOM_script)
            %this mode generate cv pool externally
        end
    end
else
    AT_mat_2_csv_pool_JSR(sprintf('%s',fntd))
    display('full')
    in=number_of_initial_dataset;
    % generate initial validation dataset,
    givd_biDigit_SWA(round(in*ratio_of_cross_validation_set),number_of_variables,fntd,FOM_script)
end

load(sprintf('%s.mat',fntd))
while in < number_of_optimization_cycles+number_of_initial_dataset
%tic
    display('======================================')
    total_time=tic;
    opt_time = tic;
    % Perform optimizer
    ml_opt_select_optimizer_sysdepend_SWA

    optimizer_time=toc(opt_time);

    % Load rms accuracies
    rmsmat=importopttxt_SWA(sprintf('rms_%s.txt',fntd));
    % Load regression data
    regmat=importopttxt_mat_SWA(sprintf('tr_%s.txt',fntd));
    % Load validation data
    valmat=importopttxt_mat_SWA(sprintf('cv_%s.txt',fntd));

    display(sprintf('Acc: cycle: %d|| rms-tr:%0.4e || rms-cv:%0.4e || com-time:%0.4e sec ||',in,rmsmat(1),rmsmat(2),optimizer_time))

    figure(frame_1)
    plot(in,rmsmat(1),'bo')
    plot(in,rmsmat(2),'r+')
    pause(0.05)

    figure(frame_4)
    close(frame_4)
    frame_4=figure('Position',[scrsz(3)*0.45,scrsz(4)*0.525,scrsz(3)*0.4,scrsz(4)*0.4]);
    reg_plot_gca=gca;
    set(reg_plot_gca,'FontSize',16,'FontName','Serif');
    ylabel('FOM^*','FontSize',20,'FontName','Serif');
    xlabel('FOM' ,'FontSize',20,'FontName','Serif');
    title('Regression Plot' ,'FontSize',20,'FontName','Serif');
    box on
    hold on
    plot(regmat(:,2),regmat(:,1),'bo')
    plot(valmat(:,2),valmat(:,1),'r+')
    pause(0.05)

    % Load optimal vector point from txtfile
    optmatrix=importopttxt_SWA(sprintf('opt_%s.txt',fntd));
    x_vector=transpose(optmatrix(2:length(optmatrix)));
    FOM_predict_gmin=optmatrix(1);


    display(sprintf('Opt: cycle: %d|| Fine-opt:%s || Fine-FOM*:%0.4e',in,sprintf('%d',x_vector),FOM_predict_gmin))

    % Check optimal vector point is already here or not
    de_qv_ii_array=bi2de(qv_ii_array);
    de_qv_gmin=bi2de(x_vector);
    checking_id=sum(de_qv_ii_array==de_qv_gmin);
    if checking_id > 0
        repeatition_flag=1;
        repeatition_FOM=FOM(de_qv_ii_array==de_qv_gmin);
        repeatition_qv_ii=qv_ii_array(de_qv_ii_array==de_qv_gmin,:);
        search_flag=0;
        while search_flag==0
            de_qv_random=round(rand(1)*2^length(x_vector));
            searching_id=sum(de_qv_ii_array==de_qv_random);
            if searching_id==0
                search_flag=1;
            end
        end
        qv_random=de2bi(de_qv_random,length(x_vector));
        clear qv_gmin;
        qv_gmin=qv_random;
        clear qv_random;
        qv_gmin_text=sprintf('%d',qv_gmin);
        repeatition_qv_ii_text=sprintf('%d',repeatition_qv_ii);
        display(sprintf('Rpt: cycle: %d|| Rpt-opt:%s || Rpt-FOM*:%0.4e',in,repeatition_qv_ii_text,repeatition_FOM))
        display(sprintf('Rpt: flag: On, random %s used instead for the training dataset',qv_gmin_text))
        rpt_flag(in+1)=1;
        x_vector=qv_gmin;
    elseif checking_id==0
        repeatition_flag=0;
        display('Rpt: flag: Off')
        rpt_flag(in+1)=0;
    end

    % Validate the optimal point
    TMM_time = tic;
    eval(sprintf('[Figure_of_merit] = %s(x_vector);',FOM_script));

    display(sprintf('Tru: cycle: %d|| Fine-opt:%s || eval-FOM:%0.4e',in,sprintf('%d',x_vector), Figure_of_merit))
    caltime_TMM = toc(TMM_time);
    caltime_TMM_array(in-24) = caltime_TMM;
    % Update Parameters
    in=in+1;
    FOM(in)=(Figure_of_merit);
    qv_ii_array(in,:)=x_vector;
    rms_tr(in)=rmsmat(1);
    rms_cv(in)=rmsmat(2);
    com_time(in)=optimizer_time;
    FOM_star_log(in)=FOM_predict_gmin;
    FOM_log(in)= FOM(in);
    qv_ii_array_log(in,:)=x_vector;

    output.rms_tr=rms_tr;
    output.rms_cv=rms_cv;
    output.com_time=com_time;
    output.FOM_star_log=FOM_star_log;
    output.FOM_log=FOM_log;
    output.qv_ii_array_log=qv_ii_array_log;
    output.FOM=FOM;
    output.qv_ii_array=qv_ii_array;

    % Update Training Dataset & update Validation Dataset
    fntd=sprintf('%s_%d',filename,in);
    eval(sprintf('save %s FOM qv_ii_array',fntd))
    %     if isfield(input,'sampling_tag')==1
    %         display('on')
    %         AT_mat_2_csv_pool_sampling(sprintf('%s',fntd),input.sampling_tag)
    %     else
    %         AT_mat_2_csv_pool(sprintf('%s',fntd))
    %     end
    %     givd_biDigit(round(in*ratio_of_cross_validation_set),number_of_variables,fntd,FOM_script,in,filename)
    if isfield(input,'sampling_tag')==1
        if isfield(input,'csv_mode')==1
            if strcmp(input.csv_mode, 'on')
                %this mode generate cv pool from the training dataset
                AT_mat_2_csv_pool_JSR(sprintf('%s',fntd),ratio_of_cross_validation_set,input.sampling_tag)
                display('csv_mode_on')

            elseif strcmp(input.csv_mode, 'off')
                display('csv_mode_off')

                AT_mat_2_csv_pool_sampling_SWA(sprintf('%s',fntd),input.sampling_tag)
                % generate initial validation dataset,
                givd_biDigit_SWA(round(in*ratio_of_cross_validation_set),number_of_variables,fntd,FOM_script,in,filename)
                %this mode generate cv pool externally
            end
        end
    else
        AT_mat_2_csv_pool_JSR(sprintf('%s',fntd))
        display('full')

        % generate initial validation dataset,
        givd_biDigit_SWA(round(in*ratio_of_cross_validation_set),number_of_variables,fntd,FOM_script,in,filename)
    end
    output.fntd=fntd;

    % Training log for the optimized values
    FOM_min_log(in)=min(FOM);
    qv_ii_array_min_log(in,:)=qv_ii_array(min(FOM)==FOM,:);
    output.FOM_min_log=FOM_min_log;
    output.qv_ii_array_min_log=qv_ii_array_min_log;
    qv_ii_array_min_log_text=sprintf('%d,  ',qv_ii_array_min_log(in,:));
    output.rpt_flag=rpt_flag;

    display(sprintf('Min: cycle: %d|| GMin-opt:%s || Gmin-FOM:%0.4e',in,sprintf('%d',qv_ii_array_min_log(in,:)),FOM_min_log(in)))

    eval(sprintf('save %s_optimization qv_ii_array FOM output',filename));

    figure(frame_2)
    plot(in,FOM_min_log(in),'o','MarkerEdgeColor',[rpt_flag(in),0.1,0])
    pause(0.05)

    figure(frame_3)
    plot(in,FOM(in),'o','MarkerEdgeColor',[rpt_flag(in),0.1,0])
    pause(0.05)

    % Copy datafiles and remove them
    if ispc==0
        ml_opt_txtfiles_mac
    elseif ispc==1
        ml_opt_txtfiles_pc
    end
    % Save figure frames
    saveframename_1=sprintf('%s_%d_acc.fig',filename,ttn);
    saveas(frame_1,saveframename_1);
    saveframename_2=sprintf('%s_%d_min.fig',filename,ttn);
    saveas(frame_2,saveframename_2);
    saveframename_3=sprintf('%s_%d_fom.fig',filename,ttn);
    saveas(frame_3,saveframename_3);
    saveframename_4=sprintf('%s_%d_reg.fig',filename,ttn);
    saveas(frame_4,saveframename_4);
    each_iter_time=toc(total_time);
    cal_file_iter_array(in-25)=each_iter_time;

    caltime_TMM_total=[caltime_TMM_array;cal_file_iter_array];
    total_name = sprintf('%s_cal_TMM_total_time_%d.mat',filename_header,ttn);
    save(total_name, "caltime_TMM_total");


end