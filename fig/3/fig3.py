import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter

# read data from csv
data = genfromtxt("fig3_data1.csv", delimiter=',')[1:7, [5, 7, 8, 9, 10]]

# generate two axes
fig, axe_left = plt.subplots()
fig.set_size_inches(12, 9)
axe_right = axe_left.twinx()

# conf title
# axe_left.set_title("Experiment xxxx on xxxx", fontweight='bold')

# conf x axe
N_x = data.shape[0]
tic_x = np.arange(1, N_x+1)
axe_left.set_xlim([0.5,N_x+0.5])
axe_left.set_xticks(tic_x)
# axe_left.set_xticklabels(axe_left.get_xticks(),fontsize='xx-large', fontweight='bold')
axe_left.set_xticklabels([])
# axe_left.set_xlabel("Fig1.2")

# conf y axe on left
tic_y_left = np.arange(200, 410, 50)
axe_left.set_ylim(200,410)
axe_left.set_yticks(tic_y_left)
axe_left.set_yticklabels(axe_left.get_yticks(),fontsize=23, fontweight='bold')
# axe_left.set_ylabel("Frequency(MHz)", fontweight='bold')

# conf y axe on right
tic_y_right = np.arange(0, 1.1, 0.25)
axe_right.set_ylim([0, 1.05])
axe_right.set_yticks(tic_y_right)
axe_right.set_yticklabels(axe_right.get_yticks(),fontsize=23, fontweight='bold')
axe_right.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))
# axe_right.set_ylabel("Ratio")

# draw lines
label_line = ['fmax', 'LUT Ratio', 'FF Ratio', 'BRAM Ratio', 'DSP Ratio']
line1 = axe_left.plot(tic_x, data[:, 0], color='b', ls='-', marker='v', label=label_line[0], linewidth=5, markersize=24)  # Freq
line2 = axe_right.plot(tic_x, data[:, 1], ls='--', marker='x', label=label_line[1], linewidth=5, markersize=16)  # LUT
line3 = axe_right.plot(tic_x, data[:, 2], ls='--', marker='*', label=label_line[2], linewidth=5, markersize=16)  # FF
line4 = axe_right.plot(tic_x, data[:, 3], ls='--', marker='+', label=label_line[3], linewidth=5, markersize=16)  # BRAM
line5 = axe_right.plot(tic_x, data[:, 4], ls='--', marker='o', label=label_line[4], linewidth=5, markersize=16)  # DSP

# draw legend
font1 = {'size': '25',
         'weight': 'bold'
         }
font2 = {'size': '23',
         'weight': 'bold'
         }
axe_left.legend(loc='upper left', bbox_to_anchor=(0.01, 0.98), prop=font1)
axe_right.legend(loc='upper left', bbox_to_anchor=(0.26, 0.99), ncol=2, prop=font2)
axe_left.grid(linestyle='--', linewidth=0.5)

# show fig
# plt.show()
fig_name = "/home/share/ftdl/fig/other/5.pdf"
plt.savefig(fig_name)
plt.show()
