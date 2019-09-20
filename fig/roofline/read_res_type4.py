
# dump log file
import pickle
# argument passer
import argparse
import csv
import os

# for fig
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
from matplotlib.ticker import FormatStrFormatter

parser = argparse.ArgumentParser(description='Input parameters of hardware config and workload.')
parser.add_argument('--hw_conf', type=str, nargs='+', help='hardware config .csv file')
parser.add_argument('--workload', type=str, nargs='+', help='workload config .csv file')
parser.add_argument('--print', type=bool, nargs=1, default=False, help='print flag')
args = parser.parse_args()

if __name__ == '__main__':
    file_hw_config = open(args.hw_conf[0], "r")
    fh_hw_config = csv.reader(file_hw_config)
    for item_hw in fh_hw_config:
        if item_hw[0] == "Config":
            continue
        # open the csv again
        file_workload_config = open(args.workload[0], "r")
        fh_workload_config = csv.reader(file_workload_config)
        for item_workload in fh_workload_config:
            if item_workload[0] == "IDX":
                continue
            fname_sol = "/home/share/ftdl/data/testCONV/sol_" +\
                        "_".join(str(elem) for elem in item_hw[1:]) + "_" +\
                        "_".join(str(elem) for elem in item_workload[2:9]) + ".pkl"
            # actually there is no missing files: the layer size is the same
            if not os.path.exists(fname_sol):
                # print("Missing,hw:"+str(item_hw)+"workload:"+str(item_workload))
                print("Missing: "+fname_sol)
                exit()
            else:
                print("Start: "+fname_sol)
                with open(fname_sol, 'rb') as sol_file:
                    [opt_sol, opt_perf, opt_score, hw_conf, workload] = pickle.load(sol_file)
                    # draw the fig
                    if len(opt_score) == 0:
                        continue
                    # select
                    # if item_hw[0] != 1 or item_workload[0] !=4:
                    #    continue
                    for data_set in np.arange(1,5):
                        # new fig
                        fig, ax = plt.subplots()
                        fig.set_size_inches(8.8, 6.6)
                        # get data
                        data = opt_score[data_set-1]
                        y = data[:1000, 10]*0.65  # y: computation throughput = th_comp
                        x = data[:1000, 10]/data[:1000, 13]*0.5  # x: intensity = th_comp/th_dram_rd
                        color_v = data[:1000, 9] # z: bound_item
                        # draw scatter
                        colorSet = [(0/256.0, 102/256.0, 180/256.0),
                                    (185/256.0, 34/256.0, 40/256.0),
                                    (255/256.0, 136/256.0, 28/256.0),
                                    (64/256.0, 155/256.0, 99/256.0)]
                        labelSet = ['bounded by Computation',
                                    'bounded by ActBUS',
                                    'bounded by PSumBUS',
                                    'bounded by DRAM']
                        for value in np.arange(4):
                            idx_v = [i for i,tmp in enumerate(color_v) if tmp == value]
                            ax.scatter(x[idx_v], y[idx_v], marker='.', c=colorSet[value], label=labelSet[value])
                        ax.grid(linestyle='--', linewidth=0.5)
                        # set label
                        ax.set_xticklabels(ax.get_xticks(), fontsize='x-large', fontweight='bold')
                        ax.set_xlabel('MACC-OP / DRAM Byte-access', fontsize='x-large', fontweight='bold')
                        ax.xaxis.set_major_formatter(FormatStrFormatter('%d'))
                        ax.set_yticklabels(ax.get_yticks(), fontsize='x-large', fontweight='bold')
                        ax.set_ylabel('Attainable Performance (GOPS)', fontsize='x-large', fontweight='bold')
                        ax.yaxis.set_major_formatter(FormatStrFormatter('%d'))
                        font1 = {'size': '14',
                                 'weight': 'bold'
                                 }
                        ax.legend(loc=9, fontsize='x-large', markerscale=2.0, ncol=2, prop=font1)
                        # draw roof line
                        roof = hw_conf['D1']*hw_conf['D2']*hw_conf['D3']*0.65
                        grad = 20/0.5*0.65
                        line1_x = np.arange(roof/grad, 1500)  # roof/grad
                        line1_y = np.ones(line1_x.shape)*roof
                        line1 = ax.plot(line1_x, line1_y, c='r', linewidth=3)
                        line2_y = np.arange(-500, roof)
                        line2_x = line2_y/grad
                        line2 = ax.plot(line2_x, line2_y, c='r', linewidth=3)
                        # set limit
                        if data_set != 2:
                            x_range = (x.max() - y.min() / grad) * 0.1
                            y_range = (roof - y.min()) * 0.1
                            x_high = x.max() + x_range
                            x_low = y.min() / grad - x_range
                            y_high = roof + y_range*3
                            y_low = y.min() - y_range
                        ax.set_ylim([y_low, y_high])
                        ax.set_xlim([x_low, x_high])
                        # add text
                        #ax.text(x_low+x_range*0.3, roof+y_range*0.3,
                        #        "$(D_1, D_2, D_3)=$"+'(' + str(hw_conf['D1'])+', ' +
                        #        str(hw_conf['D2'])+', '+str(hw_conf['D3'])+')',
                        #        fontsize='x-large')
                        # out put
                        fig_name = "/home/share/ftdl/fig/testCONV/type4/" + str(item_hw[0])\
                                   + "_" + str(item_workload[0]) + "_" + str(data_set) + '.pdf'
                        plt.savefig(fig_name)
                        # plt.show()
                        plt.close(fig)
                        # if item_hw[0]=='1' and item_workload[0]=='2' and data_set==1:
                        #      a = 1
                sol_file.close()
        file_workload_config.close()
    file_hw_config.close()
