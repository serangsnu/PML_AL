function AT_mat_2_csv_pool_sampling_CYP(name,sampling_size)  
    load(sprintf('%s.mat',name))
    qv_ii_array_pool=qv_ii_array;
    clear qv_ii_array
    FOM_pool=FOM;
    clear FOM
    
    [qv_ii_array, FOM]=sampling_size_from_pool(qv_ii_array_pool,FOM_pool,sampling_size);      
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
end
