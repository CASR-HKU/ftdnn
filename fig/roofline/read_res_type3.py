
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
                        fig.set_size_inches(8, 6)
                        # get data
                        data = opt_score[data_set-1]
                        y = data[:1000, 10]*0.65  # y: computation throughput = th_comp
                        x = data[:1000, 10]/data[:1000, 13]*0.5  # x: intensity = th_comp/th_dram_rd
                        z = data[:1000, 3] # z: wram
                        # draw scatter
                        cm = plt.cm.get_cmap('viridis_r')
                        norm = matplotlib.colors.Normalize(vmin=0, vmax=1)
                        sc = ax.scatter(x, y, marker='.', c=z, cmap=cm, norm=norm)
                        cbar = fig.colorbar(sc)
                        # cbar.ax.tick_params(labelsize=12)
                        # cbar.ax.set_yticklabels(np.arange(0, 1.0, 0.2), fontsize=12, weight='bold')
                        ax.grid(linestyle='--', linewidth=0.5)
                        # set label
                        ax.set_xticklabels(ax.get_xticks(), fontsize='x-large', fontweight='bold')
                        ax.set_xlabel('MACC-OP / DRAM Byte-access', fontsize='x-large', fontweight='bold')
                        ax.xaxis.set_major_formatter(FormatStrFormatter('%d'))
                        ax.set_yticklabels(ax.get_yticks(), fontsize='x-large', fontweight='bold')
                        ax.set_ylabel('Attainable Performance (GOPS)', fontsize='x-large', fontweight='bold')
                        ax.yaxis.set_major_formatter(FormatStrFormatter('%d'))
                        cbar.set_label('WBUF Storage Efficiency', fontsize='x-large', rotation=270, va='bottom', fontweight='bold')
                        cbar.ax.set_yticklabels(np.arange(0, 1.2, 0.2), fontsize=12,weight='bold')
                        cbar.ax.yaxis.set_major_formatter(FormatStrFormatter('%.1f'))
                        # draw roofline
                        roof = hw_conf['D1']*hw_conf['D2']*hw_conf['D3']*0.65
                        line1_x = np.arange(-500, 1500)
                        line1_y = np.ones(line1_x.shape)*roof
                        line1 = ax.plot(line1_x, line1_y, c='r', linewidth=3)
                        line2_y = np.arange(-500, 1500)
                        grad = 20/0.5*0.65
                        line2_x = line2_y/grad
                        line2 = ax.plot(line2_x, line2_y, c='r', linewidth=3)
                        # update range at fig1.3.4
                        if data_set != 2:
                            x_range = (x.max() - y.min() / grad) * 0.1
                            y_range = (roof - y.min()) * 0.1
                            x_high = x.max()+x_range
                            x_low = y.min()/grad-x_range
                            y_high = roof+y_range
                            y_low = y.min()-y_range
                        ax.set_ylim([y_low, y_high])
                        ax.set_xlim([x_low, x_high])
                        # out put
                        fig_name = "/home/share/ftdl/fig/testCONV/type3/" + str(item_hw[0])\
                                   + "_" + str(item_workload[0]) + "_" + str(data_set) + '.pdf'
                        plt.savefig(fig_name)
                        # plt.show()
                        plt.close(fig)
                sol_file.close()
        file_workload_config.close()
    file_hw_config.close()
