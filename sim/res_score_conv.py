# dump log file
import pickle
# argument passer
import argparse

import numpy as np

# set the hardware config
hw_conf = {
    'D1': 8,
    'D2': 10,
    'D3': 10,
    'N_ACT': 32, #NOTE: half of act_buf size (double buffering)
    'N_W': 1024, #NOTE: should be an integer times of 1K
    'N_PSUM': 1024, #NOTE: should be an integer times of 1K
}


workload = {
    'M': 20,
    'N': 100,
    'W': 50,
    'H': 50,
    'I': 3,
    'J': 3,
    'STRIDE': 1
}

dram_rd_bw = 20
dram_wr_bw = 20

sol_file_name = './data/sol_' + str(hw_conf['D1']) + '_' + str(hw_conf['D2']) + '_' + str(hw_conf['D3']) + '_' + str(hw_conf['N_ACT']) + '_' + str(hw_conf['N_W']) + '_' + str(hw_conf['N_PSUM']) + '_' + str(workload['M']) + '_' + str(workload['N']) + '_' + str(workload['W']) + '_' + str(workload['H']) + '_' + str(workload['I']) + '_' + str(workload['J']) + '_' + str(workload['STRIDE']) + '.pkl'

if __name__ == '__main__':

    # load data
    with open(sol_file_name, 'rb') as sol_file:
        sol, perf, hw_conf, workload = pickle.load(sol_file)
    sol_file.close()

    # theoretical number
    n_op = workload['M']*workload['N']*workload['W']*workload['H']*workload['I']*workload['J']
    theo_th = hw_conf['D1']*hw_conf['D2']*hw_conf['D3']
    theo_time = int(n_op/theo_th)
    theo_act_rd = workload['N'] *((workload['W']-1)*workload['STRIDE']+workload['I'])*((workload['H']-1)*workload['STRIDE']+workload['J'])
    theo_psum_wr = workload['M']*workload['W']*workload['H']
    theo_w_consumption =  workload['M']*workload['N']*workload['I']*workload['J'] / (hw_conf['D1']*hw_conf['D2']*hw_conf['D3'])

    # temp
    # sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3, tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh = sol[3217839]

    # score list initialize with different types
    score = []
    score_avg_list = []
    score_exe_list = []
    score_bw_list = []
    score_wram_list = []

    for idx in range(0, len(perf)):
        time_comp, w_ram_consump, psum_ram_consump, act_rd, psum_wr, psum_rd = perf[idx]
        ratio_time_comp = time_comp / theo_time
        ratio_act_rd = act_rd / theo_act_rd
        ratio_psum_wr = psum_wr / theo_psum_wr
        # th_dram_act_rd = act_rd / time_comp
        # th_dram_psum_wr = psum_wr / time_comp
        # th_dram_psum_rd = psum_rd / time_comp
        # the rd amount on bus should *sp_m_d3
        timebound_bus_act_rd = act_rd * sol[idx][5] / hw_conf['D3']
        timebound_bus_psum_wr = psum_wr / hw_conf['D2']
        timebound_dram_rd = (act_rd + psum_rd)/dram_rd_bw
        timebound_dram_wr = psum_wr / dram_wr_bw

        # decide the real time consumption considering the data bandwidth
        real_time = max(time_comp, timebound_bus_act_rd, timebound_bus_psum_wr, timebound_dram_rd, timebound_dram_wr)
        bound_item = [time_comp, timebound_bus_act_rd, timebound_bus_psum_wr, timebound_dram_rd, timebound_dram_wr].index(real_time)
        th_comp = n_op / real_time
        th_bus_act_rd = act_rd / real_time
        th_bus_psum_wr = psum_wr / real_time
        th_dram_rd = (act_rd + psum_rd) / real_time
        th_dram_wr = psum_wr / real_time

        # score computation, considering: 1.time_comp 2.w_ram_consumption, the less, the better
        ratio_w_consumption = w_ram_consump / hw_conf['N_W']

        #
        score_exe = theo_time / real_time
        score_bw = (th_dram_rd + th_dram_wr) / (dram_rd_bw + dram_wr_bw)
        score_wram = theo_w_consumption / w_ram_consump
        score_avg = score_exe*20 + score_bw + score_wram*10

        # record the overall score and other items
        score.append((score_avg, score_exe, score_bw, score_wram, ratio_w_consumption, ratio_time_comp, ratio_act_rd, ratio_psum_wr, real_time, bound_item, th_comp, th_bus_act_rd, th_bus_psum_wr, th_dram_rd, th_dram_wr))

    # trans the list to ndarry for sorting
    score = np.array(score)
    # pickup the Top-K
    opt_avg_idx = score[:,0].argsort()[::-1][:200]
    opt_exe_idx = score[:, 1].argsort()[::-1][:200]
    opt_bw_idx = score[:, 2].argsort()[::-1][:200]
    opt_wram_idx = score[:, 3].argsort()[::-1][:200]

    opt_avg_score = score[opt_avg_idx]
    opt_avg_sol = np.array(sol)[opt_avg_idx]

    print("End")


