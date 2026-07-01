# -*- coding: utf-8 -*-
"""
Created on Tue Aug  1 10:11:04 2023
% 
% # -*- coding: utf-8 -*-
% 
% Created on Mon Jul 31 17:34:53 2023
% 
% @author: Sangwoo An 
% 
% function : 
% 
% this is final version for release 
% feel free to ask me about detail 
% 
% e-mail : sang-wooahn@khu.ac.kr
%
%
"""
import neal
import numpy as np
import pandas as pd
import timeit
import dwave.inspector






def d_simul(filename):
    start_time = timeit.default_timer()
    
    file = open(filename+'_qubo_qlm.txt', 'r')
    bias_file = np.loadtxt(filename+'_bias.txt')
    
    A = file.read()
    A = np.asmatrix(A)
    m = int(np.size(A)**(1/2))
    A = np.reshape(A, (m,m))
    
    var_off=bias_file.astype(float)
    
    Q = np.zeros(np.shape(A))
    Q = A
    
    
    sampler = neal.SimulatedAnnealingSampler()
    sampleset=sampler.sample_qubo(Q, num_reads=100, num_sweeps=1000,beta_schedule_type="geometric")
    
    terminate_time = timeit.default_timer()
    
    
    
    print(Q)
    print('--------------------------------------------------------------')
    print(sampleset)
    
    print("calculation: %fsec." % (terminate_time - start_time))
    
    
    
    df = pd.DataFrame(sampleset)
    df.to_csv('simul_output.txt', header = None, index = False, sep = '\t')
    
    
    file = open('simul_output.txt', 'r')
    sampleset = file.read()
    sampleset = np.asmatrix(sampleset)
    sampleset = np.reshape(sampleset, (-1, m))
    print("This is sampleset \n")
    
    print(sampleset)
    print("This is sampleset \n")
    
    OptimizedData = sampleset[0, :]
    df = pd.DataFrame(OptimizedData)
    df.to_csv('simul_OptimizedData.txt', header = None, index = False, sep = ' ')
    #여기 위에 taqb에서 공백으로 바꿔줬다. 
    
    FOM = (OptimizedData*Q*OptimizedData.T +var_off)
    # bias 추가해주자~!!!
    df = pd.DataFrame(FOM)
    df.to_csv('simul_FOM.txt', header = None, index = False, sep = '\t')
     #     dwave.inspector.show(sampleset)   
    
    print("Optimized Structure: \n", OptimizedData)
    print("FOM: ", FOM)
#     fom_results.append(FOM)
    
    
# fom_results = []
# for i in range(100):
#    d_simul("test_start_FM_Digit_bat1_25")
