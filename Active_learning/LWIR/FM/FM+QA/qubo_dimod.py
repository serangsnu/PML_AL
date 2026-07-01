# -*- coding: utf-8 -*-
"""% 
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


from dwave.system import EmbeddingComposite, DWaveSampler, LeapHybridSampler
import numpy as np
import pandas as pd
import timeit
import dwave.inspector
from dimod import BinaryQuadraticModel, ExactSolver






def qubo_run(filename):
    file = open(filename+'_qubo_qlm.txt', 'r')
    bias_file = np.loadtxt(filename+'_bias.txt')
    
    start_time = timeit.default_timer()

    
    A = file.read()
    A = np.asmatrix(A)
    m = int(np.size(A)**(1/2))
    A = np.reshape(A, (m,m))
    
    var_off=bias_file.astype(float)
    
    Q = np.zeros(np.shape(A))
    Q = A
    
    
    b= BinaryQuadraticModel.from_qubo(Q=Q, offset=var_off)
    
    
    
    
    sampler = EmbeddingComposite(DWaveSampler())
    # sampleset = sampler.sample_qubo(Q=Q, annealing_time=1000,
    #                                  num_reads = 100,
    #                                  label='30_layer - Simple Ocean Programs: QUBO')
    
    sampleset= sampler.sample(b, warnings=None, num_reads = 1000,label='30_layer - Simple Ocean Programs: QUBO')
    ##
    
    #Hybrid Solver
    #sampler = LeapHybridSampler()
    #sampleset=sampler.sample_qubo(Q, label='Example - Hybrid_Simple Ocean Programs: QUBO')
    ##
    
    terminate_time = timeit.default_timer()
    
    print(Q)
    print('--------------------------------------------------------------')
    print(sampleset)
    
    print("calculation: %fsec." % (terminate_time - start_time))
    print(sampleset.info['timing'])
    
    df = pd.DataFrame(sampleset)
    df.to_csv('output.txt', header = None, index = False, sep = '\t')
    
    file = open('output.txt', 'r')
    sampleset = file.read()
    sampleset = np.asmatrix(sampleset)
    sampleset = np.reshape(sampleset, (-1, m))
    print("This is sampleset \n")
    
    print(sampleset)
    print("This is sampleset \n")
    
    OptimizedData = sampleset[0, :]
    df = pd.DataFrame(OptimizedData)
    df.to_csv('OptimizedData.txt', header = None, index = False, sep = ' ')
    
    FOM = OptimizedData*Q*OptimizedData.T
    # bias 추가해주자~!!!
    df = pd.DataFrame(FOM)
    df.to_csv('FOM.txt', header = None, index = False, sep = '\t')
     #     dwave.inspector.show(sampleset)   
    
    print("Optimized Structure: \n", OptimizedData)
    print("FOM: ", FOM)
    
    
    
#qubo_run('test_start_FM_Digit_bat1_25')