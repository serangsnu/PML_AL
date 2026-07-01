function [picked_qv_ii_array, picked_FOM]=sampling_size_from_pool(qv_ii_array,FOM,sampling_size)

get_size_vector=size(qv_ii_array);
labelvalue=num2cell((FOM));
num_dataset=get_size_vector(1);
%%%
NOS = sampling_size+(num_dataset-sampling_size)/2;%added code
%%%
if num_dataset <=sampling_size
    picked_qv_ii_array=qv_ii_array;
    picked_FOM=FOM;
elseif num_dataset > sampling_size
    cv_num_dataset=round(NOS);
    check_num=0;
    picked_random_id=zeros(cv_num_dataset,1);
    while check_num<cv_num_dataset
        random_id=round(rand(1)*(num_dataset-1))+1;
        check_id=sum(random_id==picked_random_id);
        if check_id==0
            check_num=check_num+1;
            picked_random_id(check_num)=random_id;
        end
    end
    picked_qv_ii_array=qv_ii_array(picked_random_id,:);
    picked_FOM=FOM(picked_random_id);
end