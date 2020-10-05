import numpy as np
import conf
from data_partition import get_actbuf

# set file param
[HW_D1_1,HW_D1_2,HW_D1_3] = conf.HW_D1_Kx
[HW_D2_1,HW_D2_2,HW_D2_3] = conf.HW_D2_Kx
[HW_D3_1,HW_D3_2,HW_D3_3] = conf.HW_D3_Kx
[HW_X_1,HW_X_2,HW_X_3] = conf.HW_X_Kx
[HW_L_1,HW_L_2,HW_L_3] = conf.HW_L_Kx
[HW_T_1,HW_T_2,HW_T_3] = conf.HW_T_Kx

MEM_FILE_DIR = 'hw/mem/act/'

def main():
    # read data from .npy file
    act = np.load('hw/scripts/data/data_act_in.npy')  # size: LOOP_K3 * LOOP_K1
    td3_1 = 0 # HW_D3_1 = 1
    td3_3 = 0
    tx_1 = 0
    tx_3 = 0 # HW_X_3 = 1
    tl_1 = 0 # HW_L_1 = 1
    tl_3 = 0
    td1_3 = 0 # HW_D1_3 = 1
    # line sum in actbuf file
    line_sum = HW_D1_1*HW_T_3*HW_T_1//2
    # combine actbuf from different D1
    actbuf_out = np.zeros((line_sum,2),dtype=np.int)
    for td1_1 in range(HW_D1_1):
        actbuf_idx_k3 = [td1_3, tl_3, tx_3, td3_3]  # [td1_3, tl_3, tx_3, td3_3]
        actbuf_idx_k1 = [td1_1, tl_1, tx_1, td3_1]  # [td1_1, tl_1, tx_1, td3_1]
        actbuf_tmp = get_actbuf(act,actbuf_idx_k3,actbuf_idx_k1)
        actbuf_tmp = actbuf_tmp.T.reshape((actbuf_tmp.size//2,2))
        actbuf_out[td1_1:line_sum:HW_D1_1,:] = actbuf_tmp
    # combine 2 data into 1 line
    act_file = open(MEM_FILE_DIR + 'actbuf_'+str(td3_3)+'_'+str(tx_1)+'_'+str(tl_3)+'.dat', 'w')
    for line_cnt in range(line_sum):
        data_str = "%04X%04X\n" % (actbuf_out[line_cnt,1], actbuf_out[line_cnt,0])
        act_file.write(data_str)
    act_file.close()
    print(act_file.name+" printed.")

if __name__ == '__main__':
    main()

