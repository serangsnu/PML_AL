#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 28 16:10:24 2022

@author: eungkyulee
"""

import numpy as np
from io import StringIO

def mfi(name_file):
    text_file_buffer=open(name_file,'r')
    content_buffer=text_file_buffer.read()
    np_buffer=StringIO(content_buffer)
    data_array=np.loadtxt(np_buffer)
    return data_array

def save_batch_to_txt(batch,layer, filename):
    # 빈 리스트 생성
    results = []

    for batch_x, batch_y in batch:
        # 입력 데이터를 numpy 배열로 변환하고, 데이터 타입을 int로 변환
        batch_x = batch_x.numpy().astype(int)
        # 라벨 데이터를 numpy 배열로 변환하고, reshape를 통해 열 벡터로 변환
        batch_y = batch_y.numpy().reshape(-1, 1)
        # 결과 리스트에 추가
        results.append(np.concatenate((batch_y, batch_x), axis=1))

    # 전체 결과 배열 생성
    result_np = np.concatenate(results, axis=0)

    np.savetxt(f"tmp{filename}.txt", result_np, delimiter='\t')
    
    ar_r=mfi("tmp"+filename+'.txt')

    first_col_cv =ar_r[:, 0].reshape(-1, 1)
    rest_cols_cv = ar_r[:, 1:] #cv

    result_cv = np.concatenate((first_col_cv,rest_cols_cv), axis=1)


    fmt = ['%f'] + ['%d']*layer  # 포맷 리스트 생성
    with open(filename+'.txt', 'w') as f:
    
        np.savetxt(f, result_cv,  fmt=fmt)