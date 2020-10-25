import numpy as np
from conf import *
from idx_transform import *
from data_partition_conv import ACTBUF_SIZE, WBUF_SIZE, get_actbuf_pos, get_wbuf_pos

# BUF utilization ratio: used / capacity
actbuf_uti = np.prod(ACTBUF_SIZE)*2
print("ACTBUF utilization: %d/%d = %.2f%%"%(actbuf_uti, ACTBUF_CAPACITY, actbuf_uti/ACTBUF_CAPACITY*100))
wbuf_uti = np.prod(WBUF_SIZE)
print("WBUF utilization: %d/%d = %.2f%%"%(wbuf_uti, WBUF_CAPACITY, wbuf_uti/WBUF_CAPACITY*100))

# ACT data overlap on D1 dim: 

# data reuse ratio: 

for d1 in range(HW_PARAM[0]):
    hw_idx = np.array([d1,0,0,0,0,0])
    print("TPE%d"%(d1))
    # size: [minibatch, input channel, input H, input W]
    # pos: [0, k2, (k4*s+k6), (k3*s+k5)]
    actbuf_pos = get_actbuf_pos(hw_idx)
    print("ACTBUF", ACTIN_SIZE, actbuf_pos, ACTBUF_SIZE)
    # size: [output channel, input channel, weight H, weight W]
    # pos: [k1, k2, k6, k5]
    wbuf_pos = get_wbuf_pos(hw_idx)
    print("WBUF", W_SIZE, wbuf_pos, WBUF_SIZE)

