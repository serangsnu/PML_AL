function [abs_cell]=pml_fields_abs(output)
    num_layer=length(output.layer);    
    total_vector_z=[0,sum_thick(output.layer,1,num_layer)]*1e-9;
    Abs=[0,0];
    scrsz=get(0,'ScreenSize');
    frame=figure('Position',[scrsz(3)*0.24,scrsz(4)*0.0,scrsz(3)*0.3,scrsz(3)*0.6]);
    abs=gca;
    abs_fig=gcf;
    set(frame,'Color','none');
    frame=plot(Abs,total_vector_z,'k');
    max_abs=zeros(1,num_layer);
    for nl=1:num_layer
       [abs_single delta_zz vector_z]=pml_fields_abs_single(nl,output);
       max_abs(nl)=max(abs_single);
       abs_cell{nl,2}=abs_single;
       abs_cell{nl,1}=vector_z;
    end
    max_max_abs=max(max_abs);
    set(abs,'FontSize',13);title(abs,'Absorption' );
    ylabel('z (m)');xlabel('G(z)hw (W/m^3)');%set(abs,'color','none');
%     axis([0,sum_thick(output.layer,1,num_layer)*1e-9,0,round(max_max_abs*1.1)]);
    axis([0,round(max_max_abs*1.1),0,sum_thick(output.layer,1,num_layer)*1e-9]);
    axis ij
    hold on
    for nl=1:num_layer
       text(round(max_max_abs*0.8),(sum_thick(output.layer,1,nl)-0.45*output.layer(nl).thickness)*1e-9,output.layer(nl).name,'FontSize',12);
    end
    for nl=1:num_layer
       line([0,round(max_max_abs*1.1)],[sum_thick(output.layer,1,nl)*1e-9,sum_thick(output.layer,1,nl)*1e-9],'LineWidth',1.5,'Color','k'); 
    end
    for nl=1:num_layer
       plot(abs_cell{nl,2}, abs_cell{nl,1},'b','LineWidth',3,'LineStyle','-.');
    end



