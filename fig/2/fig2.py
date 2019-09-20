# test debian: fig2
import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter

# read data from csv
data_all = genfromtxt("fig2_data1.csv", delimiter=',')
data_conf1 = data_all[1:8, [10, 12, 13, 14, 15]]
data_conf2 = data_all[8:15, [10, 12, 13, 14, 15]]
data = data_conf2

# generate two fig
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
# axe_left.set_xlabel("Fig2.2")

# conf y axe on left
tic_y_left = np.arange(0, 1100, 100)
axe_left.set_ylim(0,1050)
axe_left.set_yticks(tic_y_left)
axe_left.set_yticklabels(axe_left.get_yticks(),fontsize='x-large')
# axe_left.set_ylabel("Frequency(MHz)")

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
axe_left.legend(loc='upper left', bbox_to_anchor=(0.01, 0.905), fontsize='x-large')
axe_right.legend(loc='upper left', bbox_to_anchor=(0.3, 0.93), ncol=2, fontsize='large')
axe_left.grid(linestyle='--', linewidth=0.5)

# show fig
fig_name = "/home/share/ftdl/fig/other/4.pdf"
plt.savefig(fig_name)
fig.show()
