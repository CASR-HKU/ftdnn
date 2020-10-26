import numpy as np
from conf import HW_PARAM
from data_partition import get_actbuf, ACTBUF_SIZE

MEM_FILE_DIR = '../hw/mem/act/'
DAT_FILE_LINE_SUM = np.prod(ACTBUF_SIZE)*HW_PARAM[0]//2

def main():
    # read data from .npy file
    act = np.load('./data/data_actin.npy')
    for loop_tuple in np.ndindex((1, 1, 1, HW_PARAM[3], HW_PARAM[4], 1)):
        hw_idx = np.array(loop_tuple)
        actbuf_out = np.zeros((DAT_FILE_LINE_SUM, 2),dtype=np.int)
        for d1 in range(HW_PARAM[0]):
            hw_idx[0] = d1
            actbuf = get_actbuf(act, hw_idx)
            actbuf_out[d1:DAT_FILE_LINE_SUM:HW_PARAM[0],:] = actbuf.reshape((actbuf.size//2,2))
        file_name = 'actbuf_'+str(hw_idx[1])+'_'+str(hw_idx[2])+'_'+str(hw_idx[3])+'_'+str(hw_idx[4])
        write2dat(actbuf_out, file_name)

def write2dat(data, file_name):
    # combine 2 data into 1 line
    act_file = open(MEM_FILE_DIR+file_name+'.dat', 'w')
    for line_cnt in range(DAT_FILE_LINE_SUM):
        data_str = "%04X%04X\n" % (data[line_cnt,1], data[line_cnt,0])
        act_file.write(data_str)
    act_file.close()
    print(act_file.name+" generated.")

if __name__ == '__main__':
    main()

