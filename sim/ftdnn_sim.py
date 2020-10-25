import numpy as np
from conf import HW_PARAM, WL_PARAM, WL_LEVEL, ACTIN_SIZE, W_SIZE, ACTOUT_SIZE, ACTBUF_CAPACITY, WBUF_CAPACITY
from conf import wl2act, wl2w, wl2psum
from idx_transform import wl2map, map2hw, hw2wl, hw2map, map2wl
from data_partition_conv import get_actbuf_data, get_wbuf_data, ACTBUF_SIZE, WBUF_SIZE

act = np.load('./data/data_actin.npy')
w = np.load('./data/data_w.npy')
actout = np.load('./data/data_actout.npy')

def basic_analysis():
    # raw data size
    print("ACT_IN size:", ACTIN_SIZE)
    print("W size:", W_SIZE)
    print("ACT_OUT size:", ACTOUT_SIZE)

    # BUF utilization rate
    actbuf_uti = np.prod(ACTBUF_SIZE)*2
    actbuf_cap = ACTBUF_CAPACITY
    print("ACTBUF size:", ACTBUF_SIZE)
    print("ACTBUF utilization: %d/%d = %.2f%%"%(actbuf_uti, actbuf_cap, actbuf_uti/actbuf_cap*100))
    wbuf_uti = np.prod(WBUF_SIZE)
    wbuf_cap = WBUF_CAPACITY
    print("WBUF size:", WBUF_SIZE)
    print("WBUF utilization: %d/%d = %.2f%%"%(wbuf_uti, wbuf_cap, wbuf_uti/wbuf_cap*100))

def sim_sigle_wl(wl_idx):
    map_idx = wl2map(wl_idx)
    hw_idx = map2hw(map_idx)
    # data from workload
    act_wl = act[tuple(wl2act(wl_idx))]
    w_wl = w[tuple(wl2w(wl_idx))]
    # data from hardware
    act_hw = get_actbuf_data(act, hw_idx)
    w_hw = get_wbuf_data(w, hw_idx)
    # verify actin
    if(act_wl!=act_hw):
        get_actbuf_data(act, hw_idx)
        raise ValueError("ACTIN error")
    # verify w
    if(w_wl!=w_hw):
        get_wbuf_data(w, hw_idx)
        raise ValueError("W error")
    return act_wl, w_wl

def debug_single_sblk(d2, d3):
    psum = np.zeros(ACTOUT_SIZE, dtype=np.int)
    # loop of X, L, T, D1
    for loop_tuple in np.ndindex((HW_PARAM[3], HW_PARAM[4], HW_PARAM[5], HW_PARAM[0])):
        # get index  D1, D2, D3, X, L, T
        hw_idx = np.array([loop_tuple[3], d2, d3, loop_tuple[0], loop_tuple[1], loop_tuple[2]])
        map_idx = hw2map(hw_idx)
        wl_idx = map2wl(map_idx)
        # get data
        psum_in = psum[tuple(wl2psum(wl_idx))]
        act_wl, w_wl = sim_sigle_wl(wl_idx)
        psum_out = psum_in + act_wl*w_wl
        # conditional print
        if (psum_in!=0)&(hw_idx[0]==0):
            print("psum_in", psum_in)
            print("act", act_wl)
            print("w", w_wl)
            print("psum_out", psum_out)
        # update psum
        psum[tuple(wl2psum(wl_idx))] = psum_out

def sim_single_tpe(hw_idx, sim_cycle):
    hw_idx_tmp = hw_idx.copy()
    psum = np.zeros((sim_cycle,))
    # loop of specific T
    for t in range(sim_cycle):
        hw_idx_tmp[5] = hw_idx[5]+t
        act_wl, w_wl = sim_sigle_wl(hw2wl(hw_idx_tmp))
        psum[t] = act_wl*w_wl
        # print(act_wl,w_wl)
    return psum

def sim_single_sblk(hw_idx, sim_cycle):
    hw_idx_tmp = hw_idx.copy()
    psum = np.zeros((sim_cycle,))
    for d1 in range(HW_PARAM[0]):
        hw_idx_tmp[0] = d1
        psum = psum + sim_single_tpe(hw_idx_tmp, sim_cycle)
    return psum

def verify_wl():
    # loop all workload
    psum = np.zeros(ACTOUT_SIZE, dtype=np.int)
    for loop_tuple in np.ndindex(tuple([WL_PARAM[ii] for ii in range(WL_LEVEL)])):
        if loop_tuple[2:]==(0, 0, 0, 0):
            print("k1,K2: %d, %d"%(loop_tuple[0],loop_tuple[1]))
        wl_idx = np.array(loop_tuple)
        act_wl, w_wl = sim_sigle_wl(wl_idx)
        psum[tuple(wl2psum(wl_idx))] = psum[tuple(wl2psum(wl_idx))] + act_wl*w_wl
    # verify actout
    if((actout!=psum).any()): raise ValueError("ACTOUT error")
    print("Verification pass.")

def verify_psum_wr_data(d2, d3):
    psum = np.zeros(ACTOUT_SIZE, dtype=np.int)
    # loop of X, L, T, D1
    for loop_tuple in np.ndindex((HW_PARAM[3], HW_PARAM[4], HW_PARAM[5], HW_PARAM[0])):
        # get index  D1, D2, D3, X, L, T
        hw_idx = np.array([loop_tuple[3], d2, d3, loop_tuple[0], loop_tuple[1], loop_tuple[2]])
        map_idx = hw2map(hw_idx)
        wl_idx = map2wl(map_idx)
        # get data
        psum_in = psum[tuple(wl2psum(wl_idx))]
        act_wl, w_wl = sim_sigle_wl(wl_idx)
        psum_out = psum_in + act_wl*w_wl
        psum[tuple(wl2psum(wl_idx))] = psum_out
        # print condition
        if ((hw_idx[0]==HW_PARAM[0]-1)&(hw_idx[3]==1)&(hw_idx[4]==0)):
            print("psum_out", psum_out)
            # stop condition
            if (hw_idx[5]==(HW_PARAM[5]-1)):
                return()

if __name__ == "__main__":
    # basic_analysis()
    # debug_single_sblk(0, 0)
    # verify_wl()
    verify_psum_wr_data(0, 0)
