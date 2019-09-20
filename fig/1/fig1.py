# test git from debian
# test github: fig1
import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter

# read data from csv
data_dev1 = genfromtxt("fig1_data1.csv", delimiter=',')[1:8, [8, 10, 11, 12, 13]]
data_dev2 = genfromtxt("fig1_data2.csv", delimiter=',')[1:8, [8, 10, 11, 12, 13]]
data = data_dev1

# generate two axes
fig, axe_left = plt.subplots()
axe_right = axe_left.twinx()

# conf title
# axe_left.set_title("Experiment xxxx on xxxx", fontweight='bold')

# conf x axe
N_x = data.shape[0]
tic_x = np.arange(1, N_x+1)
axe_left.set_xlim([0.5,N_x+0.5])
axe_left.set_xticks(tic_x)
axe_left.set_xticklabels(axe_left.get_xticks(),fontsize='x-large')
# axe_left.set_xlabel("Fig1.2")

# conf y axe on left
tic_y_left = np.arange(0, 1100, 100)
axe_left.set_ylim(0,1050)
axe_left.set_yticks(tic_y_left)
axe_left.set_yticklabels(axe_left.get_yticks(),fontsize='x-large')
# axe_left.set_ylabel("Frequency(MHz)", fontweight='bold')

# conf y axe on right
tic_y_right = np.arange(0, 1.1, 0.1)
axe_right.set_ylim([0, 1.05])
axe_right.set_yticks(tic_y_right)
axe_right.set_yticklabels(axe_right.get_yticks(),fontsize='x-large')
axe_right.yaxis.set_major_formatter(FormatStrFormatter('%.1f'))
# axe_right.set_ylabel("Ratio")

# draw lines
label_line = ['$f_{max}$', 'LUT Ratio', 'FF Ratio', 'BRAM Ratio', 'DSP Ratio']
line1 = axe_left.plot(tic_x, data[:, 0], color='b', ls='-', marker='v', label=label_line[0], linewidth=2, markersize=12)  # Freq
line2 = axe_right.plot(tic_x, data[:, 1], ls='--', marker='x', label=label_line[1], linewidth=2, markersize=12)  # LUT
line3 = axe_right.plot(tic_x, data[:, 2], ls='--', marker='*', label=label_line[2], linewidth=2, markersize=12)  # FF
line4 = axe_right.plot(tic_x, data[:, 3], ls='--', marker='+', label=label_line[3], linewidth=2, markersize=12)  # BRAM
line5 = axe_right.plot(tic_x, data[:, 4], ls='--', marker='o', label=label_line[4], linewidth=2, markersize=12)  # DSP

# draw legend
axe_left.legend(loc='upper left', bbox_to_anchor=(0.01, 0.965), fontsize='x-large')
axe_right.legend(loc='upper left', bbox_to_anchor=(0.3, 0.99), ncol=2, fontsize='large')
axe_left.grid(linestyle='--', linewidth=0.5)

# show fig
fig_name = "/home/share/ftdl/fig/other/1.pdf"
plt.savefig(fig_name)
plt.show()
