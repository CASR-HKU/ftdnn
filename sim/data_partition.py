import numpy as np
from idx_transform import hw2wl, hw2map
from conf import MAP_PARAM, wl2act, wl2act_size, wl2w, wl2w_size


def get_segment(data, segment_pos, segment_size):
# input:    data: raw data
#           segment_pos
#           segment_size
# output:   data_segment
    data_slice = [slice(segment_pos[ii],segment_pos[ii]+segment_size[ii]) for ii in range(len(data.shape))]
    data_segment = data[tuple(data_slice)]
    return data_segment

# ACTBUF
# pos: [d1,d2,d3,x,l]
def get_actbuf_pos(hw_idx):
    hw_idx_pos=hw_idx.copy()
    hw_idx_pos[5]=0  # fix idx that is not related to pos to 0
    return wl2act(hw2wl(hw_idx_pos))

# size: [T]
ACTBUF_SIZE = wl2act_size(MAP_PARAM[5,:])

# addr: [t]
def get_actbuf_addr(hw_idx):
    return wl2act(hw2map(hw_idx)[5,:])  # only count [t]

# WBUF
# pos: [d1,d2,d3]
def get_wbuf_pos(hw_idx):
    hw_idx_pos=hw_idx.copy()
    hw_idx_pos[3:]=0  # fix idx that is not related to pos to 0
    return wl2w(hw2wl(hw_idx_pos))

# size: [X,L,T]
WBUF_SIZE = wl2w_size(np.prod(MAP_PARAM[3:,:], axis=0))

# addr: [x,l,t]
def get_wbuf_addr(hw_idx):
    hw_idx_addr=hw_idx.copy()
    hw_idx_addr[:3]=0  # fix idx that is not related to addr to 0
    return wl2w(hw2wl(hw_idx_addr))

# get actbuf from act with a specific HW index
def get_actbuf(act, hw_idx):
# input:    act: raw data
#           hw_idx: [d1, d2, d3, x, l, t]
# output:   actbuf
    buf_pos = get_actbuf_pos(hw_idx)
    return get_segment(act, buf_pos, ACTBUF_SIZE)

# get wbuf from w with a specific HW index
def get_wbuf(w, hw_idx):
# input:    w: raw data
#           hw_idx: [d1, d2, d3, x, l, t]
# output:   wbuf
    buf_pos = get_wbuf_pos(hw_idx)
    return get_segment(w, buf_pos, WBUF_SIZE)

# get actbuf data from act with a specific HW index
def get_actbuf_data(act, hw_idx):
# input:    act: raw data
#           hw_idx: [d1, d2, d3, x, l, t]
# output:   actbuf data
    buf = get_actbuf(act, hw_idx)
    buf_addr = get_actbuf_addr(hw_idx)
    return buf[tuple(buf_addr)]

# get wbuf data from w with a specific HW index
def get_wbuf_data(w, hw_idx):
# input:    w: raw data
#           hw_idx: [d1, d2, d3, x, l, t]
# output:   wbuf data
    buf = get_wbuf(w, hw_idx)
    buf_addr = get_wbuf_addr(hw_idx)
    return buf[tuple(buf_addr)]

# test func
def actbuf_debug():
    act = np.load('./data/data_actin.npy')
    hw_idx = np.array([5,2,1,3,1,0], dtype=int)
    actbuf = get_actbuf(act,hw_idx)
    print("ACTin shape:", act.shape)
    print("ACTBUF shape:", actbuf.shape)

# test func
def wbuf_debug():
    w = np.load('./data/data_w.npy')
    hw_idx = np.array([5,2,1,0,0,0], dtype=int)
    wbuf = get_wbuf(w,hw_idx)
    print("W shape:", w.shape)
    print("WBUF shape:", wbuf.shape)

# test
def test():
    act = np.load('./data/data_actin.npy')
    act_pos_hw_param = np.prod(MAP_PARAM[:,1:], axis=1)  # only count K2 to K6
    # loop all related hw param (D1, D2, D3, X, L, 1)
    for idx_loop in np.ndindex(act_pos_hw_param[0], act_pos_hw_param[1], act_pos_hw_param[2], act_pos_hw_param[3], act_pos_hw_param[4], 1):
        hw_idx = np.array(idx_loop)
        get_actbuf(act, hw_idx)
    w = np.load('./data/data_w.npy')
    w_pos_hw_param = np.prod(MAP_PARAM[:,(0,1,4,5)], axis=1)  # only count K1, K2, K5, K6
    # loop all related hw param (D1, D2, D3, 1, 1, 1)
    for idx_loop in np.ndindex(w_pos_hw_param[0], w_pos_hw_param[1], w_pos_hw_param[2], 1, 1, 1):
        hw_idx = np.array(idx_loop)
        get_actbuf(w, hw_idx)


if __name__ == '__main__':
    actbuf_debug()
    wbuf_debug()
    test()
