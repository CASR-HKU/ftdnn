
# dump log file
import pickle
# argument passer
import argparse
import csv
import os

# for fig
import numpy as np
import matplotlib.pyplot as plt

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
            fname_sol = "/home/share/ftdl/data/testMM/sol_" + "_".join(str(elem) for elem in item_hw[1:]) + "_" + "_".join(str(elem) for elem in item_workload[2:5]) + ".pkl"
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
                        # get data
                        data = opt_score[data_set-1]
                        y = data[:1000, 10]  # y: computation throughput = th_comp
                        # x = y/(data[:1000, 13]+data[:1000, 14])  # x: intensity = th_comp/(th_dram_rd+th_dram_wr)
                        x = y/data[:1000, 13]  # x: intensity = th_comp/th_dram_rd
                        # draw scatter
                        sc = ax.scatter(x, y, marker='.', c='b')
                        # set title
                        ax.set_title(fname_sol[31:])
                        # set label
                        ax.set_xlabel('Intensity')
                        ax.set_ylabel('Computation throughput')
                        # draw roofline
                        roof = hw_conf['D1']*hw_conf['D2']*hw_conf['D3']
                        line1_x = np.arange(0, 1500)
                        line1_y = np.ones(line1_x.shape)*roof
                        line1 = ax.plot(line1_x, line1_y, c='r')
                        line2_y = np.arange(0, 1500)
                        line2_x = line2_y/20
                        line2 = ax.plot(line2_x, line2_y, c='r')
                        # line3_x = np.arange(0, 1500)
                        # line3_y = line3_x * hw_conf['D3']
                        # line3 = ax.plot(line3_x, line3_y, c='r')
                        # set limit
                        ax.set_xlim([y.min()/40*0.9, x.max()*1.1])
                        ax.set_ylim([y.min()*0.9, roof*1.1])
                        # set scale
                        # ax.set_xscale('log', basex=2)
                        # ax.set_yscale('log', basey=10)
                        fig_name = "/home/share/ftdl/fig/testMM/type1/" + str(item_hw[0])\
                                   + "_" + str(item_workload[0]) + "_" + str(data_set) + '.png'
                        plt.savefig(fig_name)
                        # plt.show()
                        plt.close(fig)
                sol_file.close()
        file_workload_config.close()
    file_hw_config.close()
