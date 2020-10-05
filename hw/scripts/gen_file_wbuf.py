import numpy as np
import conf
from data_partition import get_wbuf

# set file param
[HW_D1_1,HW_D1_2,HW_D1_3] = conf.HW_D1_Kx
[HW_D2_1,HW_D2_2,HW_D2_3] = conf.HW_D2_Kx
[HW_D3_1,HW_D3_2,HW_D3_3] = conf.HW_D3_Kx
[HW_X_1,HW_X_2,HW_X_3] = conf.HW_X_Kx
[HW_L_1,HW_L_2,HW_L_3] = conf.HW_L_Kx
[HW_T_1,HW_T_2,HW_T_3] = conf.HW_T_Kx

MEM_FILE_DIR = 'hw/mem/w/'
# MEM_FILE_LINE_SUM = 128  # BRAM36
MEM_FILE_LINE_SUM = 64  # BRAM18
MEM_FILE_LINE_LEN = 16  # 16 number in one line

def main():
    # read data from .npy file
    w = np.load('hw/scripts/data/data_w.npy')  # size: FOR_LOOP_K1 * FOR_LOOP_K2
    td1_2 = 0
    td2_1 = 0
    td3_1 = 0
    for td1_1 in range(HW_D1_1):
        d1 = td1_1
        for td2_2 in range(HW_D2_2):
            d2 = td2_2
            for td3_2 in range(HW_D3_2):
                wbuf_idx_k2 = [td1_2, td2_2, td3_2]
                wbuf_idx_k1 = [td1_1, td2_1, td3_1]
                wbuf_tmp = get_wbuf(w, wbuf_idx_k1, wbuf_idx_k2)
                # all data in sequence
                wbuf_out = wbuf_tmp.reshape((wbuf_tmp.size))
                for d3_k3 in range(HW_D3_3):
                    d3 = d3_k3 + td3_2*HW_D3_3
                    file_name = 'wbuf_'+str(d3)+'_'+str(d2)+'_'+str(d1)
                    write2mem(wbuf_out, file_name)


def write2mem(data, file_name):
    # fill empty position in data with 0
    mem = np.concatenate((data.reshape(data.size), np.zeros(MEM_FILE_LINE_SUM*MEM_FILE_LINE_LEN - data.size, dtype=np.int)), axis=None)
    mem = mem.reshape((MEM_FILE_LINE_SUM, MEM_FILE_LINE_LEN))
    # write to .mem file
    mem_file = open(MEM_FILE_DIR + file_name+'.mem', 'w')
    for line_idx in np.arange(MEM_FILE_LINE_SUM):
        for len_idx in np.arange(MEM_FILE_LINE_LEN):
            data_str = "%04X " % mem[line_idx][len_idx]
            mem_file.write(data_str)
        if line_idx != MEM_FILE_LINE_SUM-1:
            mem_file.write('\n')
    mem_file.close()
    print(mem_file.name+" printed.")


def write2dat(data, file_name):
    data_len = data.size
    mem_len = MEM_FILE_LINE_SUM*MEM_FILE_LINE_LEN
    # transform data to .dat size
    if mem_len<data_len:
        print("Data size exceed.")
        exit(-1)
    mem = np.concatenate((np.reshape(data, data_len), np.zeros(mem_len - data_len, dtype=np.int)), axis=None)
    mem = np.reshape(mem, (MEM_FILE_LINE_SUM, MEM_FILE_LINE_LEN))
    # write to .dat file
    mem_file = open(MEM_FILE_DIR + file_name+'.dat', 'w')
    for line_idx in np.arange(MEM_FILE_LINE_SUM):
        # according to BRAM address mapping and INIT_xx format
        # data should write backward intra-line
        for len_idx in np.arange(MEM_FILE_LINE_LEN):
            data_str = "%04X" % mem[line_idx][MEM_FILE_LINE_LEN-1-len_idx] # backward intra-line
            mem_file.write(data_str)
        if line_idx != MEM_FILE_LINE_SUM-1:
            mem_file.write('\n')
    mem_file.close()


if __name__ == '__main__':
    main()
