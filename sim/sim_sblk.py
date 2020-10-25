# given (D3, D2), simulate the sequence of calculation in sblk
import numpy as np
import conf
from data_partition import get_wbuf, get_actbuf
from workload_mapping import trans2loop, trans2hw

LOOP_K1 = conf.LOOP_K1      # N
LOOP_K2 = conf.LOOP_K2      # M
LOOP_K3 = conf.LOOP_K3      # P

[HW_D1_1,HW_D1_2,HW_D1_3] = conf.HW_D1_Kx
[HW_D2_1,HW_D2_2,HW_D2_3] = conf.HW_D2_Kx
[HW_D3_1,HW_D3_2,HW_D3_3] = conf.HW_D3_Kx
[HW_X_1,HW_X_2,HW_X_3] = conf.HW_X_Kx
[HW_L_1,HW_L_2,HW_L_3] = conf.HW_L_Kx
[HW_T_1,HW_T_2,HW_T_3] = conf.HW_T_Kx


def workload_sim(w,act,td1,td2,td3,tx,tl,tt):
    [td1_1, td1_2, td1_3] = td1
    [td2_1, td2_2, td2_3] = td2
    [td3_1, td3_2, td3_3] = td3
    [tx_1, tx_2, tx_3] = tx
    [tl_1, tl_2, tl_3] = tl
    [tt_1, tt_2, tt_3] = tt
    trans_idx = np.array([td1,td2,td3,tx,tl,tt])
    loop_idx = trans2loop(trans_idx)
    [k1, k2, k3] = loop_idx
    hw_idx = trans2hw(trans_idx)
    [d1, d2, d3, x, l, t] = hw_idx
    # wbuf
    wbuf_idx_k1 = [td1_1, td2_1, td3_1]
    wbuf_idx_k2 = [td1_2, td2_2, td3_2]
    wbuf = get_wbuf(w,wbuf_idx_k1,wbuf_idx_k2)
    # wbuf_addr
    wbuf_addr = tt_2 + tt_1*HW_T_2 + tl_1*HW_T_1*HW_T_2 + tx_2*HW_L_1*HW_T_1*HW_T_2 + tx_1*HW_X_2*HW_L_1*HW_T_1*HW_T_2 
    # wbuf_data(dsp_a)
    wbuf_idx = (tt_1 + tl_1*HW_T_1 + tx_1*HW_L_1*HW_T_1, tt_2 + tx_2*HW_T_2)
    wbuf_data = wbuf[wbuf_idx]
    w_data = w[k1, k2]

    # actbuf
    actbuf_idx_k3 = [td1_3, tl_3, tx_3, td3_3]
    actbuf_idx_k1 = [td1_1, tl_1, tx_1, td3_1]
    actbuf = get_actbuf(act,actbuf_idx_k3,actbuf_idx_k1)
    # actbuf_addr
    actbuf_addr = tt_3 + tt_1*HW_T_3
    # actbuf_data
    actbuf_idx = (tt_3, tt_1)
    actbuf_data = actbuf[actbuf_idx]
    act_data = act[k3,k1]
    if (wbuf_data==w_data)&(actbuf_data==act_data):
        return w_data*act_data
    else:
        print('wrong')
        exit()


if __name__ == "__main__":
    w = np.load('./data/data_w.npy')  # size: LOOP_K1 * LOOP_K2
    act = np.load('./data/data_act_in.npy')  # size: LOOP_K3 * LOOP_K1
    pbuf = np.zeros((2, HW_T_3*HW_T_2*HW_L_3*HW_L_2//2),dtype=np.int)
    # constant sblk(d2, d3)
    d2_1 = 0
    d2_2 = 0
    d2_3 = 0
    d3_1 = 0
    d3_2 = 0
    d3_3 = 0

    # temporal X loop
    x_2 = 0
    x_3 = 0
    for x_1 in range(HW_X_1):
        # temporal L loop
        l_1 = 0
        l_2 = 0
        for l_3 in range(HW_L_3):
            # temporal T loop
            for t_1 in range(HW_T_1):
                for t_2 in range(HW_T_2):
                    for t_3 in range(HW_T_3):
                        t = t_3 + HW_T_3*t_2 + HW_T_3*HW_T_2*t_1
                        # spatial D1 loop
                        d1_2 = 0
                        d1_3 = 0
                        pbuf_addr = (t_3+t_2*HW_T_3+l_3*HW_T_2*HW_T_3+l_2*HW_L_3*HW_T_2*HW_T_3)//2
                        clkh_toggle = t_3%2
                        psum = pbuf[clkh_toggle,pbuf_addr]
                        for d1_1 in range(HW_D1_1):
                            td1 = [d1_1, d1_2, d1_3]
                            td2 = [d2_1, d2_2, d2_3]
                            td3 = [d3_1, d3_2, d3_3]
                            tx = [x_1, x_2, x_3]
                            tl = [l_1, l_2, l_3]
                            tt = [t_1, t_2, t_3]
                            psum = psum + workload_sim(w,act,td1,td2,td3,tx,tl,tt)
                        print(pbuf_addr, psum)
                        pbuf[clkh_toggle,pbuf_addr] = psum
    print("finish")