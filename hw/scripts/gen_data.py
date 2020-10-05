import numpy as np
import conf

np.random.seed(0)

LOOP_K1 = conf.LOOP_K1      # N
LOOP_K2 = conf.LOOP_K2      # M
LOOP_K3 = conf.LOOP_K3      # P

max = 0x000f

data_act_in = np.random.randint(0, max, (LOOP_K3, LOOP_K1))
data_w = np.random.randint(0, max, (LOOP_K1, LOOP_K2))
data_act_out = np.matmul(data_act_in,data_w)

np.save('./data/data_act_in', data_act_in)
np.save('./data/data_w', data_w)
np.save('./data/data_act_out', data_act_out)
