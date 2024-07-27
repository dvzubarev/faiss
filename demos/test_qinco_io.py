import sys
import torch
import faiss
import numpy as np

sys.path.append("/tmp/Qinco")
import model_qinco
qinco = torch.load("/tmp/bigann_8x8_L2.pt")
qinco_faiss = faiss.QINCo(qinco)
qinco_index = faiss.IndexQINCo(qinco_faiss.d, qinco_faiss.M, 8, qinco_faiss.L, qinco_faiss.h)
qinco_index.qinco = qinco_faiss
qinco_index.is_trained = True
faiss.write_index(qinco_index, '/tmp/test.faiss')
read_index = faiss.read_index('/tmp/test.faiss')

from faiss.contrib import datasets
ds = datasets.SyntheticDataset(128, 0, 100, 30)

# ref_codes = qinco_index.sa_encode(ds.get_database())
# print("ref_codes 0 ", ref_codes[0])
# read_codes = read_index.sa_encode(ds.get_database())
# print("read_codes 0 ", read_codes[0])

# np.testing.assert_array_equal(ref_codes,read_codes)
# print("encoding the same")

# ref_decoded = qinco_index.sa_decode(ref_codes)
# new_decoded = read_index.sa_decode(ref_codes)
# np.testing.assert_allclose(ref_decoded, new_decoded, atol=2e-6)
# print("decoding the same")

qinco_index.add(ds.get_database())
read_index.add(ds.get_database())

Dref, Iref = qinco_index.search(ds.get_queries(), 5)
Dnew, Inew = read_index.search(ds.get_queries(), 5)


np.testing.assert_array_equal(Iref, Inew)
np.testing.assert_allclose(Dref, Dnew, atol=2e-6)
