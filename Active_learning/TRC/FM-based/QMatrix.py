from dwave.system import EmbeddingComposite, DWaveSampler
import numpy as np
import pandas as pd

m = 30

Q = np.zeros((m,m))
for i in range(m):
    for j in range(m):
        Q[i,j] = np.random.randn(1)

df = pd.DataFrame(Q)
df.to_csv('input.txt', header = None, index = False, sep = '\t')

