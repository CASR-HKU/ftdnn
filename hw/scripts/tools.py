import numpy as np
from conf import *


# convert wbuf_idx to w_idx
# Matrix Multiply only
def wbuf_idx_to_w_idx(wbuf_idx, td1_k1=0, td2_k2=0, td3_k2=0):
    w_idx = np.zeros_like(wbuf_idx)
    idx1 = wbuf_idx[:, 0]
    idx2 = wbuf_idx[:, 1]
    w_idx[:, 0] = td1_k1 + idx1 * HW_D1_K1
    S2 = FOR_LOOP_K2 // (HW_D2_K2 * HW_D3_K2)
    w_idx[:, 1] = idx2 + (td3_k2 + td2_k2 * HW_D3_K2) * S2
    return w_idx


# get wbuf from w with specific position
# Matrix Multiply only
def get_wbuf_from_w(w, td1_k1, td2_k2, td3_k2):
    S1 = FOR_LOOP_K1 // HW_D1_K1
    k1_mask = td1_k1 + np.arange(0, S1) * HW_D1_K1
    w_tmp = w[k1_mask, :]
    S2 = FOR_LOOP_K2 // (HW_D2_K2 * HW_D3_K2)
    k2_mask = np.arange(0, S2) + (td3_k2 + td2_k2 * HW_D3_K2) * S2
    wbuf = w_tmp[:, k2_mask]
    print(k1_mask)
    print(k2_mask)
    return wbuf


# convert actbuf_idx to act_idx
# Matrix Multiply only
def actbuf_idx_to_act_idx(actbuf_idx, td1_k1=0, td3_k3=0, x_k1=0, l_k3=0):
    act_idx = np.zeros_like(actbuf_idx)
    idx3 = actbuf_idx[:, 0]
    idx1 = actbuf_idx[:, 1]
    T3 = FOR_LOOP_K3 // (HW_D3_K3 * HW_L_K3)
    act_idx[:, 0] = idx3 + (l_k3 + td3_k3 * HW_L_K3) * T3
    T1 = HW_T_K1
    act_idx[:, 1] = td1_k1 + (idx1 + x_k1 * T1) * HW_D1_K1
    return act_idx
