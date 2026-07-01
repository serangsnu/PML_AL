
from dwave.system import EmbeddingComposite, DWaveSampler, LeapHybridSampler
import numpy as np
import pandas as pd
import timeit

def d_Hsolver(filename):
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

    ##Direct Solver
#     sampler = EmbeddingComposite(DWaveSampler())
#     sampleset = sampler.sample_qubo(Q,
#                                      num_reads = 1000,
#                                      label='Example - Simple Ocean Programs: QUBO')
    ##

    # Hybrid Solver
    sampler = LeapHybridSampler()
    HQA_name = 'HQA_problem_{s}'.format(s=filename)
    sampleset=sampler.sample_qubo(Q, label=HQA_name)
    #

    terminate_time = timeit.default_timer()

    print(Q)
    print('--------------------------------------------------------------')
    print(sampleset)

    print("calculation: %fsec." % (terminate_time - start_time))
    #print(sampleset.info['timing'])

    df = pd.DataFrame(sampleset)
    df.to_csv('output.txt', header = None, index = False, sep = '\t')
    
    m = Q.shape[0]

    file = open('output.txt', 'r')
    sampleset = file.read()
    sampleset = np.asmatrix(sampleset)
    sampleset = np.reshape(sampleset, (-1, m))

    OptimizedData = sampleset[0, :]
    df = pd.DataFrame(OptimizedData)
    df.to_csv('OptimizedData.txt', header = None, index = False, sep = ' ')

    bias = var_off
    FOM = OptimizedData*Q*OptimizedData.T
    df = pd.DataFrame(FOM)
    df.to_csv('FOM.txt', header = None, index = False, sep = '\t')

    print("Optimized Structure: \n", OptimizedData)
    print("type of OptimizedData : ", type(OptimizedData))
    print("FOM: ", FOM)
    print("type of FOM : ", type(FOM))