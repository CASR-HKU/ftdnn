import numpy as np
from conf import *
from tools import get_wbuf_from_w

# set .mem file param
MEM_FILE_DIR = '../mem/'
# MEM_FILE_LINE_SUM = 128  # BRAM36
MEM_FILE_LINE_SUM = 64  # BRAM18
MEM_FILE_LINE_LEN = 16  # 16 number in one line


def main():
    # read data from .npy file
    w = np.load('./data/data_w.npy')  # size: FOR_LOOP_K1 * FOR_LOOP_K2
    # separate into w_slice based on FOR_LOOP_K1, FOR_LOOP_K2
    # and write to .mem based on HW_D1, HW_D2, HW_D3
    for td1_k1 in range(HW_D1_K1):
        for td2_k2 in range(HW_D2_K2):  # td2_k2 is also td2
            for td3_k2 in range(HW_D3_K2):
                wbuf = get_wbuf_from_w(w, td1_k1, td2_k2, td3_k2)
                for td3_k3 in range(HW_D3_K3):
                    td3 = td3_k2*HW_D3_K3 + td3_k3
                    file_name = 'wbuf_'+str(td1_k1)+'_'+str(td2_k2)+'_'+str(td3)+'.mem'
                    write2mem(wbuf, file_name)


def write2mem(data, file_name):
    data_len = data.size
    mem_len = MEM_FILE_LINE_SUM*MEM_FILE_LINE_LEN
    # transform data to .mem size
    if mem_len<data_len:
        print("Data size exceed.")
        exit(-1)
    mem = np.concatenate((np.reshape(data, data_len), np.zeros(mem_len - data_len, dtype=np.int)), axis=None)
    mem = np.reshape(mem, (MEM_FILE_LINE_SUM, MEM_FILE_LINE_LEN))
    # write to .mem file
    mem_file = open(MEM_FILE_DIR + file_name, 'w')
    for line_idx in np.arange(MEM_FILE_LINE_SUM):
        for len_idx in np.arange(MEM_FILE_LINE_LEN):
            data_str = "%04X " % mem[line_idx][len_idx]
            mem_file.write(data_str)
        mem_file.write('\n')
    mem_file.close()


if __name__ == '__main__':
    main()
