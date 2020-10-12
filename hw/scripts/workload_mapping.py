# demo of index mapping from loop index to hw index
import numpy as np
import conf


LOOP_LEVEL = conf.LOOP_LEVEL
LOOP_K1 = conf.LOOP_K1      # N
LOOP_K2 = conf.LOOP_K2      # M
LOOP_K3 = conf.LOOP_K3      # P

HW_D1 = conf.HW_D1
HW_D2 = conf.HW_D2
HW_D3 = conf.HW_D3

HW_X = conf.HW_X
HW_L = conf.HW_L
HW_T = conf.HW_T

mapping_matrix = np.array([
    conf.HW_D1_Kx, # D1
    conf.HW_D2_Kx, # D2
    conf.HW_D3_Kx, # D3
    conf.HW_X_Kx, # X
    conf.HW_L_Kx, # L
    conf.HW_T_Kx # T
    ], dtype=np.int)

def loop2trans(loop_idx):
# input: loop_idx (LOOP_LEVEL, )
# output: trans_idx (6, LOOP_LEVEL)
    # decompose loop_idx to get trans_idx
    # D1, T, L, X, D2, D3 [0,5,4,3,1,2]
    # smallest base come out first (left to right)
    trans_idx = np.zeros((6, LOOP_LEVEL), dtype=np.int)
    idx_tmp = loop_idx
    for i in [0,5,4,3,1,2]:
        trans_idx[i,:] = idx_tmp % mapping_matrix[i,:]
        idx_tmp = idx_tmp // mapping_matrix[i,:]
    return trans_idx

def trans2hw(trans_idx):
# input: trans_idx (6, LOOP_LEVEL)
# output: hw_idx (6, )
    # compose trans_idx to get hw_idx
    # KK, ..., K2, K1
    # largest base calculate first (right to left)
    hw_idx = trans_idx[:,0]
    for i in range(1, LOOP_LEVEL):
        hw_idx = trans_idx[:,i] + hw_idx*mapping_matrix[:,i]
    return hw_idx

def loop2hw(loop_idx):
    return trans2hw(loop2trans(loop_idx))

def hw2trans(hw_idx):
# input: hw_idx (6, )
# output: trans_idx (6, LOOP_LEVEL)
    # decompose hw_idx to get trans_idx
    # KK, ..., K2, K1
    # smallest base come out first (left to right)
    trans_idx = np.zeros((6, LOOP_LEVEL), dtype=np.int)
    idx_tmp = hw_idx
    for i in range(LOOP_LEVEL-1, -1, -1):
        trans_idx[:,i] = idx_tmp % mapping_matrix[:,i]
        idx_tmp = idx_tmp // mapping_matrix[:,i]
    return trans_idx

def trans2loop(trans_idx):
    # compose trans_idx to get hw_idx
    # D1, T, L, X, D2, D3 [0,5,4,3,1,2]
    # largest base calculate first (right to left)
    loop_idx = trans_idx[2,:]
    for i in [1,3,4,5,0]:
        loop_idx = trans_idx[i,:] + loop_idx*mapping_matrix[i,:]
    return loop_idx

def hw2loop(hw_idx):
    return trans2loop(hw2trans(hw_idx))

if __name__ == "__main__":
    loop_idx0 = np.zeros(3, dtype=np.int)
    loop_idx1 = np.array([43, 22, 13], dtype=np.int)
    hw_idx1 = loop2hw(loop_idx1)
    loop_idx_r = hw2loop(hw_idx1)
    print(mapping_matrix)
    print(hw_idx1)
    print(loop_idx_r)

