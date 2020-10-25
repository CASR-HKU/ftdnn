import numpy as np

# Data structure define
WID_W = 16
WID_ACT = 16

# TPE architecture define
RAMB18_CAPACITY = 2**14       # RAMB18E2, 14-bit bit addressable
RAM128_CAPACITY = 128       # RAM128X1D, 7-bit bit addressable
WBUF_CAPACITY = RAMB18_CAPACITY//WID_W
ACTBUF_CAPACITY = RAM128_CAPACITY
WID_WBUF_ADDR = np.int(np.log2(WBUF_CAPACITY))
WID_ACTBUF_ADDR = np.int(np.log2(ACTBUF_CAPACITY))

# MAP PARAM
MAP_PARAM = np.array([
    #K1,K2,K3,K4,K5,K6
    #M, N, W, H, I, J
    [1, 1, 1, 1, 3, 3],  # D1
    [8, 1, 1, 1, 1, 1],  # D2
    [1, 1, 4, 2, 1, 1],  # D3
    [1, 4, 2, 7, 1, 1],  # X
    [1, 8, 1, 1, 1, 1],  # L
    [8, 2, 7, 4, 1, 1],  # T
], dtype=np.int)

adjacency_mat = (MAP_PARAM==1)

# Workload PARAM
WL_PARAM = np.prod(MAP_PARAM, axis=0)
WL_LEVEL = MAP_PARAM.shape[1]
# WL transform base: Kmax(smallest base), ..., K2, K1
WL_BASE = [5, 4, 3, 2, 1, 0]  # small to large

# Hardware PARAM
HW_PARAM = np.prod(MAP_PARAM, axis=1)
HW_LEVEL = MAP_PARAM.shape[0]
# HW transform base: T(smallest base), X, L, D3, D2, D1
HW_BASE = [5, 4, 3, 2, 1, 0]  # small to large

# data size
CONV_STRIDE = 1


def wl2act_1d(wl):
# input:    wl_idx: [k1, k2, k3, k4, k5, k6]
# output:   [0, k2, (k4*s+k6), (k3*s+k5)]
    if len(wl.shape)!=1:    raise ValueError("Shape not match")
    return np.array([0, wl[1], wl[3]*CONV_STRIDE+wl[5], wl[2]*CONV_STRIDE+wl[4]], dtype=np.int)

def wl2act(wl):
# n-dim wl2act
    if len(wl.shape)==1:
        return wl2act_1d(wl)
    else:
        return np.array([wl2act_1d(wl[ii]) for ii in range(wl.shape[0])], dtype=np.int)

def wl2act_size(wl):
    return  wl2act(wl-1)+1

# ACTIN_SIZE: [minibatch, input channel, input H, input W]
#             [0+1, (K2-1)+1, ((K4-1)*s+(K6-1)+1), ((K3-1)*s+(K5-1)+1)]
ACTIN_SIZE = wl2act_size(WL_PARAM)

def wl2w_1d(wl):
# input:    wl_idx: [k1, k2, k3, k4, k5, k6]
# output:   [k1, k2, k6, k5]
    if len(wl.shape)!=1:    raise ValueError("Shape not match")
    return np.array([wl[0], wl[1], wl[5], wl[4]], dtype=np.int)

def wl2w(wl):
# n-dim wl2w
    if len(wl.shape)==1:
        return wl2w_1d(wl)
    else:
        return np.array([wl2w_1d(wl[ii]) for ii in range(wl.shape[0])], dtype=np.int)

def wl2w_size(wl):
    return  wl2w(wl-1)+1

# W_SIZE: [output channel, input channel, weight H, weight W]
#         [K1, K2, K6, K5]
W_SIZE = wl2w_size(WL_PARAM)

def wl2psum_1d(wl):
# input:    wl_idx or WL_PARAM: [k1, k2, k3, k4, k5, k6]
# output:   [0, k1, k4, k3]
    if len(wl.shape)!=1:    raise ValueError("Shape not match")
    return np.array([0, wl[0], wl[3], wl[2]], dtype=np.int)

def wl2psum(wl):
# n-dim wl2psum
    if len(wl.shape)==1:
        return wl2psum_1d(wl)
    else:
        return np.array([wl2psum_1d(wl[ii]) for ii in range(wl.shape[0])], dtype=np.int)

def wl2psum_size(wl):
    return  wl2psum(wl-1)+1

# ACTOUT_SIZE: [minibatch, output channel, output H, output W]
#              [1, K1, K4, K3]
ACTOUT_SIZE = wl2psum_size(WL_PARAM)
