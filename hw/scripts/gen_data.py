import numpy as np
from conf import *

np.random.seed(0)

max = 0x000f

data_act_in = np.random.randint(0, max, (FOR_LOOP_K3, FOR_LOOP_K1))
data_w = np.random.randint(0, max, (FOR_LOOP_K1, FOR_LOOP_K2))
data_act_out = np.matmul(data_act_in,data_w)

np.save('./data/data_act_in', data_act_in)
np.save('./data/data_w', data_w)
np.save('./data/data_act_out', data_act_out)
