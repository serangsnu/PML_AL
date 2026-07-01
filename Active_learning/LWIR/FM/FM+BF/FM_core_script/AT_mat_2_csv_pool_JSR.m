function AT_mat_2_csv_pool_JSR(name,varargin)
if isempty(varargin)==1
    load(sprintf('%s.mat',name))
    xlearncsvsfile = fopen(sprintf('%s.txt',name),'w');
    get_size_vector=size(qv_ii_array);
    labelvalue=num2cell((FOM));
    
    labeltext='%12.8f ';
    for gn=1:get_size_vector(2)
        labelvalue(gn+1,:)=num2cell(transpose(qv_ii_array(:,gn)));
        labeltext=[labeltext '%d '];
    end
    labeltext=[labeltext '\n'];
    fprintf(xlearncsvsfile,labeltext,labelvalue{:});
    fclose(xlearncsvsfile); 
elseif length(varargin)==1
    sampling_rate=varargin{1};
    %sampling_size=varargin{2};

    load(sprintf('%s.mat',name))
    get_size_vector=size(qv_ii_array);
    labelvalue=num2cell((FOM));
    num_dataset=get_size_vector(1);
    cv_num_dataset=round(num_dataset*sampling_rate);
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
   
    
    [c_matrix]=[transpose(picked_FOM), picked_qv_ii_array];
    [numRows,numCols] = size(picked_qv_ii_array);
    fname= fntd+'_cv.txt';
    writematrix(c_matrix,fname,'Delimiter','space');

    
    clear get_size_vector; clear labelvalue; clear labeltext; clear gn; clear xlearncsvsfile;
    
    qv_ii_array(picked_random_id,:)=[];
    FOM(picked_random_id)=[];        
    xlearncsvsfile = fopen(sprintf('%s.txt',name),'w');
    get_size_vector=size(qv_ii_array);
    labelvalue=num2cell((FOM));
    
    labeltext='%12.8f ';
    for gn=1:get_size_vector(2)
        labelvalue(gn+1,:)=num2cell(transpose(qv_ii_array(:,gn)));
        labeltext=[labeltext '%d '];
    end
    labeltext=[labeltext '\n'];
    fprintf(xlearncsvsfile,labeltext,labelvalue{:});
    fclose(xlearncsvsfile);
    
elseif length(varargin)==2
    sampling_rate=varargin{1};
    sampling_size=varargin{2};

    load(sprintf('%s.mat',name))
    qv_ii_array_pool=qv_ii_array;
    clear qv_ii_array
    FOM_pool=FOM;
    clear FOM

    [qv_ii_array, FOM]=sampling_size_from_pool(qv_ii_array_pool,FOM_pool,sampling_size);

    get_size_vector=size(qv_ii_array);
    labelvalue=num2cell((FOM));
    num_dataset=get_size_vector(1);
    cv_num_dataset=round(num_dataset*sampling_rate);
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
    
   
    
    [c_matrix]=[transpose(picked_FOM), picked_qv_ii_array];
    [numRows,numCols] = size(picked_qv_ii_array);
    fname= string(name)+'_cv.txt';
    writematrix(c_matrix,fname,'Delimiter','space');

    clear c_matrix;clear numRows; clear numCols; clear fname;
    
    
    qv_ii_array(picked_random_id,:)=[];
    FOM(picked_random_id)=[];        
   
    [c_matrix]=[transpose(FOM), qv_ii_array];
    [numRows,numCols] = size(qv_ii_array);
    fname= string(name)+'.txt';
    writematrix(c_matrix,fname,'Delimiter','space');

    clear c_matrix;clear numRows; clear numCols; clear fname;
    
    
end
