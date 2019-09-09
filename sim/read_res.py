from math import floor as floor
from math import ceil as ceil
from res_score_conv import res_score_conv

# dump log file
import pickle
# argument passer
import argparse
import csv
import os

parser = argparse.ArgumentParser(description='Input parameters of hardware config and workload.')
parser.add_argument('--hw_conf', type=str, nargs='+', help='hardware config .csv file')
parser.add_argument('--workload', type=str, nargs='+', help='workload config .csv file')
parser.add_argument('--print', type=bool, nargs=1, default=False, help='print flag')
args = parser.parse_args()

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
        fname_sol = "/home/share/ftdl/data/GoogLeNet/sol_" + "_".join(str(elem) for elem in item_hw[1:]) + "_" + "_".join(str(elem) for elem in item_workload[2:9]) + ".pkl"
        # actually there is no missing files: the layer size is the same
        if (not os.path.exists(fname_sol)):
            print("Missing,hw:"+str(item_hw)+"workload:"+str(item_workload))
        with open(fname_sol, 'rb') as sol_file:
            [opt_sol, opt_perf, opt_score, hw_conf, workload] = pickle.load(sol_file)
        sol_file.close()
    file_workload_config.close()