import numpy as np
from conf import HW_PARAM
from data_partition_conv import get_wbuf

MEM_FILE_DIR = '../hw/mem/w/'
# MEM_FILE_LINE_SUM = 128  # BRAM36
MEM_FILE_LINE_SUM = 64  # BRAM18
MEM_FILE_LINE_LEN = 16  # 16 number in one line

def main():
    # read data from .npy file
    w = np.load('./data/data_w.npy')
    for loop_tuple in np.ndindex((HW_PARAM[0], HW_PARAM[1], HW_PARAM[2], 1, 1, 1)):
        hw_idx = np.array(loop_tuple)
        wbuf = get_wbuf(w, hw_idx)
        file_name = 'wbuf_'+str(hw_idx[0])+'_'+str(hw_idx[1])+'_'+str(hw_idx[2])
        write2mem(wbuf, file_name)


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
    print(mem_file.name+" generated.")

if __name__ == '__main__':
    main()
