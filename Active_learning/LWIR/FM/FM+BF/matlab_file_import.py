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