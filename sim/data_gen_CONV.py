import numpy as np
import torch
import torch.nn.functional as F
from conf import ACTIN_SIZE, W_SIZE, ACTOUT_SIZE

# general
torch.random.manual_seed(0)
max = 0x000f

# data_actin
data_actin = torch.randint(0, max, tuple(ACTIN_SIZE))
# data_w
data_w = torch.randint(0, max, tuple(W_SIZE))
# calculate data_actout CONV
data_actout = F.conv2d(data_actin, data_w, stride=1)
if data_actout.size() != torch.Size(ACTOUT_SIZE): raise ValueError("Output size not match")

np.save('./data/data_actin', data_actin.numpy())
print("data_actin generated.")
np.save('./data/data_w', data_w.numpy())
print("data_w generated.")
np.save('./data/data_actout', data_actout.numpy())
print("data_actout generated.")
