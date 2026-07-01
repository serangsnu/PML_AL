function [esq_cell]=pml_fields_E_sq_time(output)
    num_layer=length(output.layer);    
    total_vector_z=[0,sum_thick(output.layer,1,num_layer)]*1e-9;
    esq_tot=[0,0];
    c_speed=299792458;
    nm=1e-9;
    omega_0=c_speed*output.k{1};
    wavelength=2*pi/output.k{1}*1e+9;
    get_frame=25;
    period_0=2*pi/omega_0;
    delta_time=period_0/get_frame;
    max_esq=zeros(get_frame,num_layer);
    for tt=1:1:get_frame
        time_phase=exp(-1i*omega_0*delta_time*tt);    
        for nl=1:num_layer
            [E_sq vector_z]=pml_fields_E_sq_single_time(nl,output,time_phase);
            max_esq(tt,nl)=max(E_sq);
            esq_cell{nl,2,tt}=E_sq;
            esq_cell{nl,1,tt}=vector_z;
        end
    end
     max_max_esq=max(max(max_esq));
%      max_max_esq=2.4;
     scrsz=get(0,'ScreenSize');
    for tt=1:1:get_frame  
        frame(tt)=figure('Position',[scrsz(3)*0.24,scrsz(4)*0.0,scrsz(3)*0.2,scrsz(3)*0.4]);
        esq(tt)=gca;
        esq_fig(tt)=gcf;
        set(frame(tt),'Color','none');
        frame(tt)=plot(esq_tot,total_vector_z,'k');
        set(esq(tt),'FontSize',13);title(esq(tt),'E field Intensity' );
        ylabel('z (m)');xlabel('|E(z) / E_0|^2');%set(esq(tt),'color','none');
        axis([0,max_max_esq*1.1,0,sum_thick(output.layer,1,num_layer)*1e-9]);
        axis ij
        hold on;
        for nl=1:num_layer
            text(max_max_esq*0.8,(sum_thick(output.layer,1,nl)-0.45*output.layer(nl).thickness)*1e-9,output.layer(nl).name,'FontSize',12);
        end
        for nl=1:num_layer
            line([0,max_max_esq*1.1],[sum_thick(output.layer,1,nl)*1e-9,sum_thick(output.layer,1,nl)*1e-9],'LineWidth',1.5,'Color','k');
        end
        for nl=1:num_layer
            plot(esq_cell{nl,2,tt}, esq_cell{nl,1,tt},'r','LineWidth',3);
        end
        if tt<10;
%         saveas(esq_fig(tt),[sprintf( 'E_sq_%s_lamda%g.frame.0%d',output.fields_pol,wavelength,tt) '.png'],'png');
          str=sprintf( ' E_sq_%s_lamda%g.frame.0%d',output.fields_pol,wavelength,tt);
          eval(['export_fig' str ' -png -a1 -m1']) 
        elseif tt>9;
%         saveas(esq_fig(tt),[sprintf( 'E_sq_%s_lamda%g.frame.%d',output.fields_pol,wavelength,tt) '.png'],'png');    
          str=sprintf( ' E_sq_%s_lamda%g.frame.%d',output.fields_pol,wavelength,tt);
          eval(['export_fig' str ' -png -a1 -m1']) 
        end
         
    end
     system(['/Users/eungkyulee/Rosettapkgs/ImageMagick/bin/convert '  sprintf( ' E_sq_%s_lamda%g.frame',output.fields_pol,wavelength) '*.png' sprintf( ' E_sq_%s_lamda%g.frame',output.fields_pol,wavelength) '.gif']);
     system(['rm' sprintf( ' E_sq_%s_lamda%g.frame',output.fields_pol,wavelength) '*.png']); 
     close(esq_fig);
     