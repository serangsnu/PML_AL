% initiate plots
scrsz=get(0,'ScreenSize');
frame_1=figure('Position',[scrsz(3)*0.05,scrsz(4)*0.5,scrsz(3)*0.4,scrsz(4)*0.4]);
semilogy(0,0)
rms_plot_gca=gca;
set(rms_plot_gca,'FontSize',16,'FontName','Serif');
ylabel('RMS','FontSize',20,'FontName','Serif');
xlabel('Opt. Cycles' ,'FontSize',20,'FontName','Serif');
title('Accuracies' ,'FontSize',20,'FontName','Serif');
box on
hold on

frame_2=figure('Position',[scrsz(3)*0.05,scrsz(4)*0.025,scrsz(3)*0.4,scrsz(4)*0.4]);
semilogy(0,0)
min_opt_plot_gca=gca;
set(min_opt_plot_gca,'FontSize',16,'FontName','Serif');
ylabel('Minimum FOM','FontSize',20,'FontName','Serif');
xlabel('Opt. Cycles' ,'FontSize',20,'FontName','Serif');
title('Optimization Performances' ,'FontSize',20,'FontName','Serif');
box on
hold on

frame_3=figure('Position',[scrsz(3)*0.45,scrsz(4)*0.025,scrsz(3)*0.4,scrsz(4)*0.4]);
semilogy(0,0)
opt_plot_gca=gca;
set(opt_plot_gca,'FontSize',16,'FontName','Serif');
ylabel('FOM','FontSize',20,'FontName','Serif');
xlabel('Opt. Cycles' ,'FontSize',20,'FontName','Serif');
title('Optimization Performances' ,'FontSize',20,'FontName','Serif');
box on
hold on

frame_4=figure('Position',[scrsz(3)*0.45,scrsz(4)*0.525,scrsz(3)*0.4,scrsz(4)*0.4]);
reg_plot_gca=gca;
set(reg_plot_gca,'FontSize',16,'FontName','Serif');
ylabel('FOM^*','FontSize',20,'FontName','Serif');
xlabel('FOM' ,'FontSize',20,'FontName','Serif');
title('Regression Plot' ,'FontSize',20,'FontName','Serif');
box on