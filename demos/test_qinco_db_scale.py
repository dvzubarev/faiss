# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.


#based on demo_qinco.py

import numpy as np
from faiss.contrib.vecs_io import bvecs_mmap
import sys
import time
import torch
import faiss

# make sure pickle deserialization will work
sys.path.append("/tmp/Qinco")
import model_qinco

with torch.no_grad():

    qinco = torch.load("/tmp/bigann_8x8_L2.pt")
    qinco.eval()
    # print(qinco)
    if True:
        torch.set_num_threads(8)
        faiss.omp_set_num_threads(8)

    x_base = bvecs_mmap("/tmp/bigann1M.bvecs")[:1000].astype('float32')
    x_scaled = torch.from_numpy(x_base) / qinco.db_scale

    t0 = time.time()
    codes, _ = qinco.encode(x_scaled)
    x_decoded_scaled = qinco.decode(codes)
    print(f"Pytorch encode {time.time() - t0:.3f} s")
    # multi-thread: 1.13s, single-thread: 7.744

    x_decoded = x_decoded_scaled.numpy() * qinco.db_scale

    err = ((x_decoded - x_base) ** 2).sum(1).mean()
    print("MSE=", err)  # = 14211.956, near the L=2 result in Fig 4 of the paper

    qinco_faiss = faiss.QINCo(qinco)
    qinco_index = faiss.IndexQINCo(qinco_faiss.d, qinco_faiss.M, 8, qinco_faiss.L, qinco_faiss.h)
    qinco_index.qinco = qinco_faiss
    qinco_index.is_trained = True
    qinco_index.db_scale = qinco.db_scale

    faiss.write_index(qinco_index, '/tmp/test.faiss')
    index = faiss.read_index('/tmp/test.faiss')

    t0 = time.time()
    codes2 = index.sa_encode(x_base)
    x_decoded2 = index.sa_decode(codes2)
    print(f"Faiss encode {time.time() - t0:.3f} s")
    ndiff = (codes.numpy() != codes2).sum() / codes.numel()
    assert ndiff < 0.01
    ndiff = (((x_decoded - x_decoded2) ** 2).sum(1) > 1e-5).sum()
    assert ndiff / len(x_base) < 0.01


    err = ((x_decoded2 - x_base) ** 2).sum(1).mean()
    print("MSE=", err)  # = 14213.551
