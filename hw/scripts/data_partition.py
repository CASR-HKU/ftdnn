import numpy as np
import conf


LOOP_K1 = conf.LOOP_K1      # N
LOOP_K2 = conf.LOOP_K2      # M
LOOP_K3 = conf.LOOP_K3      # P

[HW_D1_1,HW_D1_2,HW_D1_3] = conf.HW_D1_Kx
[HW_D2_1,HW_D2_2,HW_D2_3] = conf.HW_D2_Kx
[HW_D3_1,HW_D3_2,HW_D3_3] = conf.HW_D3_Kx
[HW_X_1,HW_X_2,HW_X_3] = conf.HW_X_Kx
[HW_L_1,HW_L_2,HW_L_3] = conf.HW_L_Kx
[HW_T_1,HW_T_2,HW_T_3] = conf.HW_T_Kx

# convert wbuf index to slice in w
def idx2slc_wbuf_k1(wbuf_idx_k1):
# input:    wbuf_idx_k1 [td1_1, td2_1, td3_1]
# output:   slice in w
    # fixed (d1, d2, d3) with all possible (t, l, x)
    # count order: D1, T, L, X, D2, D3
    step_k1 = HW_D1_1
    size_k1 = HW_T_1*HW_L_1*HW_X_1
    base_k1 = wbuf_idx_k1[0] + wbuf_idx_k1[1]*size_k1*step_k1 + wbuf_idx_k1[2]*HW_D2_1*size_k1*step_k1
    slc_k1 = slice(base_k1, base_k1+size_k1*step_k1, step_k1)
    return slc_k1

# convert wbuf index to slice in w
def idx2slc_wbuf_k2(wbuf_idx_k2):
# input:    wbuf_idx_k2 [td1_2, td2_2, td3_2]
# output:   slice in w
    # fixed (d1, d2, d3) with all possible (t, l, x)
    # count order: D1, T, L, X, D2, D3
    step_k2 = HW_D1_2
    size_k2 = HW_T_2*HW_L_2*HW_X_2
    base_k2 = wbuf_idx_k2[0] + wbuf_idx_k2[1]*size_k2*step_k2 + wbuf_idx_k2[2]*HW_D2_2*size_k2*step_k2
    slc_k2 = slice(base_k2, base_k2+size_k2*step_k2, step_k2)
    return slc_k2

# test func
def idx2slc_wbuf_test():
    # variable loop only, ignore T, L, X
    for td3_1 in range(HW_D3_1):
        for td3_2 in range(HW_D3_2):
            for td2_1 in range(HW_D2_1):
                for td2_2 in range(HW_D2_2):
                    for td1_1 in range(HW_D1_1):
                        for td1_2 in range(HW_D1_2):
                                print([td1_1, td2_1, td3_1], [td1_2, td2_2, td3_2])
                                # print(idx2slc_wbuf_k1([td1_1, td2_1, td3_1]), idx2slc_wbuf_k2([td1_2, td2_2, td3_2]))

# get wbuf from w with a specific index
def get_wbuf(w, wbuf_idx_k1, wbuf_idx_k2):
# input:    w (LOOP_K1, LOOP_K2)
#           wbuf_idx_k1 [td1_1, td2_1, td3_1]
#           wbuf_idx_k2 [td1_2, td2_2, td3_2]
# output:   wbuf
    slc_k1 = idx2slc_wbuf_k1(wbuf_idx_k1)
    slc_k2 = idx2slc_wbuf_k2(wbuf_idx_k2)
    w_out = w[slc_k1, slc_k2]
    return w_out

# test func
def wbuf_test():
    # conversion test
    idx2slc_wbuf_test()

    # data slice test
    w = np.load('hw/scripts/data/data_w.npy')
    wbuf_idx_k1 = [0, 0, 0]  # [td1_1, td2_1, td3_1]
    wbuf_idx_k2 = [0, 0, 0]  # [td1_2, td2_2, td3_2]
    w_out = get_wbuf(w,wbuf_idx_k1,wbuf_idx_k2)

# convert actbuf index to slice in act
def idx2slc_actbuf_k3(actbuf_idx_k3):
# input:    actbuf_idx_k3 [td1_3, tl_3, tx_3, td3_3]
# output:   slice inact
    # fixed (d1, l, x, d3) with all possible (t)
    # count order: D1, T, L, X, D2, D3
    step_k3 = HW_D1_3
    size_k3 = HW_T_3
    base_k3 = actbuf_idx_k3[0] + actbuf_idx_k3[1]*size_k3*step_k3 + actbuf_idx_k3[2]*HW_L_3*size_k3*step_k3 + actbuf_idx_k3[3]*HW_X_3*HW_L_3*size_k3*step_k3
    slc_k3 = slice(base_k3, base_k3+size_k3*step_k3, step_k3)
    return slc_k3

# convert actbuf index to slice in act
def idx2slc_actbuf_k1(actbuf_idx_k1):
# input:    actbuf_idx_k1 [td1_1, tl_1, tx_1, td3_1]
    # fixed (d1, l, x, d3) with all possible (t)
    # count order: D1, T, L, X, D2, D3
    step_k1 = HW_D1_1
    size_k1 = HW_T_1
    base_k1 = actbuf_idx_k1[0] + actbuf_idx_k1[1]*size_k1*step_k1 + actbuf_idx_k1[2]*HW_L_1*size_k1*step_k1 + actbuf_idx_k1[3]*HW_X_1*HW_L_1*size_k1*step_k1
    slc_k1 = slice(base_k1, base_k1+size_k1*step_k1, step_k1)
    return slc_k1

def idx2slc_actbuf_test():
    for td3_1 in range(HW_D3_1):
        for td3_3 in range(HW_D3_3):
            for tx_1 in range(HW_X_1):
                for tx_3 in range(HW_X_3):
                    for tl_1 in range(HW_L_1):
                        for tl_3 in range(HW_L_3):
                            for td1_1 in range(HW_D1_1):
                                for td1_3 in range(HW_D1_3):
                                    print([td1_3, tl_3, tx_3, td3_3], [td1_1, tl_1, tx_1, td3_1])
                                    # print(idx2slc_actbuf_k3([td1_3, tl_3, tx_3, td3_3]), idx2slc_actbuf_k1([td1_1, tl_1, tx_1, td3_1]))

# get actbuf from act with a specific index
def get_actbuf(act, actbuf_idx_k3, actbuf_idx_k1):
# input:    act (LOOP_K3, LOOP_K1)
#           actbuf_idx_k3 [td1_3, tl_3, tx_3, td3_3]
#           actbuf_idx_k1 [td1_1, tl_1, tx_1, td3_1]
# output:   actbuf
    slc_k3 = idx2slc_actbuf_k3(actbuf_idx_k3)
    slc_k1 = idx2slc_actbuf_k1(actbuf_idx_k1)
    act_out = act[slc_k3, slc_k1]
    return act_out

# test func
def actbuf_test():
    # conversion test
    idx2slc_actbuf_test()

    # data slice test
    act = np.load('hw/scripts/data/data_act_in.npy')
    actbuf_idx_k3 = [0, 0, 0, 0]  # [td1_3, tl_3, tx_3, td3_3]
    actbuf_idx_k1 = [0, 0, 0, 0]  # [td1_1, tl_1, tx_1, td3_1]
    act_out = get_actbuf(act,actbuf_idx_k3,actbuf_idx_k1)


if __name__ == '__main__':
    # actbuf_test()
    # print("actbuf_test finish")
    wbuf_test()
    print("wbuf_test finish")
