function [esq_cell]=pml_fields_E_sq(output)
    num_layer=length(output.layer);    
    total_vector_z=[0,sum_thick(output.layer,1,num_layer)]*1e-9;
    esq_tot=[0,0];
    scrsz=get(0,'ScreenSize');
    frame=figure('Position',[scrsz(3)*0.24,scrsz(4)*0.0,scrsz(3)*0.3,scrsz(3)*0.6]);
    set(frame,'Color','none');
    frame=plot(esq_tot,total_vector_z,'k');
    esq=gca;
    max_esq=zeros(1,num_layer);
    for nl=1:num_layer
       [E_sq vector_z]=pml_fields_E_sq_single(nl,output);    
       max_esq(nl)=max(E_sq);
       esq_cell{nl,2}=E_sq;
       esq_cell{nl,1}=vector_z;
    end
    max_max_esq=max(max_esq);
    set(esq,'FontSize',13);title(esq,'E field Intensity' );
    ylabel('z (m)');xlabel('|E(z) / E_0|^2');%set(esq,'color','none');
    axis([0,max_max_esq*1.1,0,sum_thick(output.layer,1,num_layer)*1e-9]);
    axis ij
    hold on
    for nl=1:num_layer
        text(max_max_esq*0.8,(sum_thick(output.layer,1,nl)-0.45*output.layer(nl).thickness)*1e-9,output.layer(nl).name,'FontSize',12);
    end
    for nl=1:num_layer
        line([0,max_max_esq*1.1],[sum_thick(output.layer,1,nl)*1e-9,sum_thick(output.layer,1,nl)*1e-9],'LineWidth',1.5,'Color','k'); 
    end
    for nl=1:num_layer
        plot(esq_cell{nl,2}, esq_cell{nl,1},'k','LineWidth',3,'LineStyle','-.');
    end
 