import numpy as np
import conf

from conf import MAP_PARAM, WL_PARAM, WL_LEVEL, HW_PARAM

# transform base:
wl_base_ascend = conf.WL_BASE  # small to large
wl_base_descend = [wl_base_ascend[ii] for ii in range(5,-1,-1)]  # large to small
hw_base_ascend = conf.HW_BASE  # small to large
hw_base_descend = [hw_base_ascend[ii] for ii in range(5,-1,-1)]  # large to small

def wl2map(wl_idx):
# input: wl_idx (WL_LEVEL, )
# output: map_idx (6, WL_LEVEL)
    # decompose wl_idx to get map_idx
    # smallest base come out first
    if (wl_idx>(WL_PARAM-1)).any(): raise ValueError("Workload index error")
    map_idx = np.zeros((6, WL_LEVEL), dtype=np.int)
    idx_tmp = wl_idx
    for base in hw_base_ascend:
        map_idx[base,:] = idx_tmp % MAP_PARAM[base,:]
        idx_tmp = idx_tmp // MAP_PARAM[base,:]
    return map_idx

def map2hw(map_idx):
# input: map_idx (6, WL_LEVEL)
# output: hw_idx (6, )
    # compose map_idx to get hw_idx
    # largest base calculate first
    if (map_idx>(MAP_PARAM-1)).any(): raise ValueError("Mapping index error")
    base = wl_base_descend[0]
    hw_idx = map_idx[:, base]
    for base in wl_base_descend[1:]:
        hw_idx = map_idx[:,base] + hw_idx*MAP_PARAM[:,base]
    return hw_idx

def wl2hw(wl_idx):
    return map2hw(wl2map(wl_idx))

def hw2map(hw_idx):
# input: hw_idx (6, )
# output: map_idx (6, WL_LEVEL)
    # decompose hw_idx to get map_idx
    # smallest base come out first
    if (hw_idx>(HW_PARAM-1)).any(): raise ValueError("Hardware index error")
    map_idx = np.zeros((6, WL_LEVEL), dtype=np.int)
    idx_tmp = hw_idx
    for base in wl_base_ascend:
        map_idx[:,base] = idx_tmp % MAP_PARAM[:,base]
        idx_tmp = idx_tmp // MAP_PARAM[:,base]
    return map_idx

def map2wl(map_idx):
    # compose map_idx to get hw_idx
    # largest base calculate first
    if (map_idx>(MAP_PARAM-1)).any(): raise ValueError("Mapping index error")
    base = hw_base_descend[0]
    wl_idx = map_idx[base,:]
    for base in hw_base_descend[1:]:
        wl_idx = map_idx[base, :] + wl_idx*MAP_PARAM[base, :]
    return wl_idx

def hw2wl(hw_idx):
    return map2wl(hw2map(hw_idx))

def debug():
    # wl -> map -> hw
    wl_idx1 = np.array([0,0,0,0,1,2])
    map_idx1 = wl2map(wl_idx1)
    hw_idx1 = map2hw(map_idx1)
    print('wl_idx1\n', wl_idx1)
    print('map_idx1\n', map_idx1)
    print('hw_idx1\n', hw_idx1)
    # hw -> map -> wl
    hw_idx2 = np.array([1,0,0,0,1,2])
    map_idx2 = hw2map(hw_idx2)
    wl_idx2 = map2wl(map_idx2)
    print('hw_idx2\n', hw_idx2)
    print('map_idx2\n', map_idx2)
    print('wl_idx2\n', wl_idx2)

def test():
    hw_idx = np.array([np.random.randint(0,HW_PARAM[ii]) for ii in range(6)], dtype=np.int)
    if (hw_idx != wl2hw(hw2wl(hw_idx))).any():
        print(hw_idx)
        raise ValueError('Different value')

if __name__ == "__main__":
    # debug
    debug()
    # test
    for i in range(1000): test()
    print('Random test pass')
    