# dump log file
import pickle
# argument passer
import argparse

import numpy as np

# # set the hardware config
# hw_conf = {
#     'D1': 8,
#     'D2': 10,
#     'D3': 10,
#     'N_ACT': 32, #NOTE: half of act_buf size (double buffering)
#     'N_W': 1024, #NOTE: should be an integer times of 1K
#     'N_PSUM': 1024, #NOTE: should be an integer times of 1K
# }
#
#
# workload = {
#     'M': 20,
#     'N': 100,
#     'W': 50,
#     'H': 50,
#     'I': 3,
#     'J': 3,
#     'STRIDE': 1
# }


def res_score_conv(sol, perf, hw_conf, workload, dram_rd_bw=20, dram_wr_bw=20, remain_len=5000, w_exe=1, w_bw=1, w_wbram=1):

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

    num_sol = len(perf)
    for idx in range(0, num_sol):
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
        score_avg = score_exe*w_exe + score_wram*w_wbram

        # record the overall score and other items
        score.append((score_avg, score_exe, score_bw, score_wram, ratio_w_consumption, ratio_time_comp, ratio_act_rd, ratio_psum_wr, real_time, bound_item, th_comp, th_bus_act_rd, th_bus_psum_wr, th_dram_rd, th_dram_wr))

        # if idx%10000==0:
        #     print("IDX=", idx)

    # trans the list to ndarry for sorting
    score = np.array(score)
    # pickup the Top-K
    if len(sol)==0:
        return [[], [], []]
    remain_len = min(remain_len, len(sol))
    opt_avg_idx = score[:,0].argsort()[::-1][:remain_len]
    opt_exe_idx = score[:, 1].argsort()[::-1][:remain_len]
    opt_bw_idx = score[:, 2].argsort()[::-1][:remain_len]
    opt_wram_idx = score[:, 3].argsort()[::-1][:remain_len]

    np_sol = np.array(sol)
    np_perf = np.array(perf)
    np_score = score

    opt_avg_sol = np_sol[opt_avg_idx]
    opt_exe_sol = np_sol[opt_exe_idx]
    opt_bw_sol = np_sol[opt_bw_idx]
    opt_wram_sol = np_sol[opt_wram_idx]
    opt_sol=[opt_avg_sol, opt_exe_sol, opt_bw_sol, opt_wram_sol]

    opt_avg_perf = np_perf[opt_avg_idx]
    opt_exe_perf = np_perf[opt_exe_idx]
    opt_bw_perf = np_perf[opt_bw_idx]
    opt_wram_perf = np_perf[opt_wram_idx]
    opt_perf=[opt_avg_perf, opt_exe_perf, opt_bw_perf, opt_wram_perf]

    opt_avg_score = np_score[opt_avg_idx]
    opt_exe_score = np_score[opt_exe_idx]
    opt_bw_score = np_score[opt_bw_idx]
    opt_wram_score = np_score[opt_wram_idx]
    opt_score=[opt_avg_score, opt_exe_score, opt_bw_score, opt_wram_score]

    return [opt_sol, opt_perf, opt_score]


