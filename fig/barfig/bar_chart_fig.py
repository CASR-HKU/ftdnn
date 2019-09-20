from numpy import genfromtxt
import matplotlib.pyplot as plt
import numpy as np
import os
import csv
import pickle

# generate data
# read data
filename_wl1 = "../../ftdnn/sim/model/testCONV.csv"
data_wl1 = genfromtxt(filename_wl1, delimiter=',')
N_wl1 = data_wl1.shape[0] - 1
filename_wl2 = "../../ftdnn/sim/model/testMM.csv"
data_wl2 = genfromtxt(filename_wl2, delimiter=',')
N_wl2 = data_wl2.shape[0] - 1
N_wl = N_wl1 + N_wl2
filename_hw = "../../ftdnn/sim/hw_config.csv"
data_hw = genfromtxt(filename_hw, delimiter=',')
N_hw = data_hw.shape[0] - 1

data = np.zeros((N_wl, N_hw))

# Read from CONV
n_wl = 0
file_workload_config = open(filename_wl1, "r")
fh_workload_config = csv.reader(file_workload_config)
for item_workload in fh_workload_config:
    if item_workload[0] == "IDX":
        continue
    n_hw = 0
    file_hw_config = open(filename_hw, "r")
    fh_hw_config = csv.reader(file_hw_config)
    for item_hw in fh_hw_config:
        if item_hw[0] == "Config":
            continue
        # open the csv again
        filename_sol = "/home/share/ftdl/data/testCONV/sol_" + \
                       "_".join(str(elem) for elem in item_hw[1:]) + "_" + \
                       "_".join(str(elem) for elem in item_workload[2:9]) + ".pkl"
        if not os.path.exists(filename_sol):
            # print("Missing,hw:"+str(item_hw)+"workload:"+str(item_workload))
            print("Missing: " + filename_sol)
            exit()
        else:
            print("Start: " + filename_sol)
            with open(filename_sol, 'rb') as sol_file:
                [opt_sol, opt_perf, opt_score, hw_conf, workload] = pickle.load(sol_file)
                data[n_wl, n_hw] = opt_score[1][0][10] / 1200.0
                n_hw = n_hw + 1
            sol_file.close()
    file_hw_config.close()
    n_wl = n_wl + 1
file_workload_config.close()

# Read from MM
file_workload_config = open(filename_wl2, "r")
fh_workload_config = csv.reader(file_workload_config)
for item_workload in fh_workload_config:
    if item_workload[0] == "IDX":
        continue
    n_hw = 0
    file_hw_config = open(filename_hw, "r")
    fh_hw_config = csv.reader(file_hw_config)
    for item_hw in fh_hw_config:
        if item_hw[0] == "Config":
            continue
        # open the csv again
        filename_sol = "/home/share/ftdl/data/testMM/sol_" + \
                       "_".join(str(elem) for elem in item_hw[1:]) + "_" + \
                       "_".join(str(elem) for elem in item_workload[2:5]) + ".pkl"
        if not os.path.exists(filename_sol):
            # print("Missing,hw:"+str(item_hw)+"workload:"+str(item_workload))
            print("Missing: " + filename_sol)
            exit()
        else:
            print("Start: " + filename_sol)
            with open(filename_sol, 'rb') as sol_file:
                [opt_sol, opt_perf, opt_score, hw_conf, workload] = pickle.load(sol_file)
                data[n_wl, n_hw] = opt_score[1][0][10] / 1200.0
                n_hw = n_hw + 1
            sol_file.close()
    file_hw_config.close()
    n_wl = n_wl + 1
file_workload_config.close()

# fig
label_hw = ['hw_conf1', 'hw_conf2', 'hw_conf3', 'hw_conf4', 'hw_conf5', 'hw_conf6']
tic_wl = np.arange(1, N_wl+1)
label_wl = ['CONV1', 'CONV2', 'CONV3', 'CONV4', 'CONV5', 'CONV6', 'CONV7', 'MM1', 'MM2', 'MM3']

width = 1.0/(N_hw+1)
interval = 0.95/N_hw
# set step of color
r = 0/256.0
r_step = (1-r)/(N_hw+4)
g = 60/256.0
g_step = (1-g)/(N_hw+4)
b = 108/256.0
b_step = (1-b)/(N_hw+4)
# draw the fig
fig, ax = plt.subplots()
fig.set_size_inches(30, 2)

ax.grid(axis='y', linestyle='--', linewidth=0.5)
for n_hw in np.arange(N_hw):
    ax.bar(tic_wl+interval*(n_hw-(N_hw-1)/2.0), data[:, n_hw],
           color=(1-r_step*(n_hw+4), 1-g_step*(n_hw+4), 1-b_step*(n_hw+4)),
           width=width, label=label_hw[n_hw], zorder=5)

# ax.legend()
ax.set_xticks([])
ax.set_xlim([0.4, 10.6])
#ax.set_xticklabels(label_wl)
# ax.set_ylabel('th_comp')
ax.set_yticks(np.arange(0,1.1,0.2))
ax.set_yticklabels(['0%', '20%', '40%', '60%', '80%', '100%'], fontsize='x-large', fontweight='bold')
ax.set_ylim([0, 1])

fig_name = "/home/share/ftdl/fig/bar_chart_new.pdf"
plt.savefig(fig_name)
plt.show()
