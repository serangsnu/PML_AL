function givd_biDigit_CYP(get_number,number_of_variables,fntd,FOM_script,varargin)  
if length(varargin)==0
    for it=1:1:get_number
        qv_random=rand(number_of_variables,1); % you need to delete this line if you would like to use this script as a function
        qv_random(qv_random>0.5)=1; % you need to delete this line if you would like to use this script as a function
        qv_random(qv_random<=0.5)=0; % you need to delete this line if you would like to use this script as a function
        clear qv_ii; % you need to delete this line if you would like to use this script as a function
        digital_vector=qv_random; % you need to delete this line if you would like to use this script as a function
        qv_ii_array(it,:)=digital_vector;
        eval(sprintf('[Figure_of_merit] = %s(qv_ii_array(it,:));',FOM_script));
        % Figure of merit
        FOM(it)=(Figure_of_merit);
        cv_fntd=sprintf('%s_cv',fntd);
        eval(sprintf('save %s qv_ii_array FOM',cv_fntd));
    end
    AT_mat_2_csv_pool(sprintf('%s',cv_fntd))
elseif length(varargin)==2
    pre_in=varargin{1}-1;
    filename=varargin{2};
    pre_fntd=sprintf('%s_%d',filename,pre_in);
    load(sprintf('%s_cv.mat',pre_fntd))
    siz_array=size(FOM);
    for it=siz_array(2):1:get_number
        qv_random=rand(number_of_variables,1); % you need to delete this line if you would like to use this script as a function
        qv_random(qv_random>0.5)=1; % you need to delete this line if you would like to use this script as a function
        qv_random(qv_random<=0.5)=0; % you need to delete this line if you would like to use this script as a function
        clear qv_ii; % you need to delete this line if you would like to use this script as a function
        digital_vector=qv_random; % you need to delete this line if you would like to use this script as a function
        qv_ii_array(it,:)=digital_vector;
        eval(sprintf('[Figure_of_merit] = %s(qv_ii_array(it,:));',FOM_script));
        % Figure of merit
        FOM(it)=(Figure_of_merit);
        cv_fntd=sprintf('%s_cv',fntd);
        eval(sprintf('save %s qv_ii_array FOM',cv_fntd));
    end
    AT_mat_2_csv_pool(sprintf('%s',cv_fntd))
end
