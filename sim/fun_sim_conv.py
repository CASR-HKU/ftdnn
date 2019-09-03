# sim for the overall data throughput

from math import floor as floor
from math import ceil as ceil

import pickle

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
    'B': 10,
    'M': 20,
    'N': 100,
    'W': 50,
    'H': 50,
    'I': 3,
    'J': 3,
    'STRIDE': 1
}


if __name__ == '__main__':

    # generate all possible `spatial partition` combinations
    sp_comb = []

    # STEP1: enumerate all possible combinations, regardless of the utilization
    for sp_n_d1 in range(1, min(hw_conf['D1'], workload['N'])+1):
        for sp_i_d1 in range(1, min(floor(hw_conf['D1']/sp_n_d1), workload['I']) + 1):
            for sp_j_d1 in range(1, min(floor(hw_conf['D1'] / sp_n_d1 / sp_i_d1), workload['J']) + 1):
                #
                sp_m_d2 = min(hw_conf['D2'], workload['M'])
                for sp_n_d3 in range(1, min(hw_conf['D3'], ceil(workload['N']/sp_n_d1))+1):
                    for sp_m_d3 in range(1, min(floor(hw_conf['D3']/sp_n_d3), ceil(workload['M']/sp_m_d2)) + 1):
                        for sp_w_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3), workload['W']) + 1):
                            for sp_h_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3 / sp_w_d3), workload['H']) + 1):
                                for sp_b_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3 / sp_w_d3 / sp_h_d3), workload['B']) + 1):
                                    sp_comb.append((sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3, sp_b_d3))


    # with open('objs.pkl', 'rb') as dump_file:
    #     sp_comb, hw_conf, workload = pickle.load(dump_file)
    # dump_file.close()




    cnt = 0
    global_sol = []
    for sp_opt in sp_comb:
        (sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3, sp_b_d3) = sp_opt
        tp_sol = []
        # generate all possible `temporal partition` combinations
        # STEP1: T dim
        # tw starts from 2 due to the weight sharing
        for tw in range(2, min(ceil(workload['W']/sp_w_d3), hw_conf['N_ACT'])+1):
            for th in range(1, min(ceil(workload['H']/sp_h_d3), floor(hw_conf['N_ACT']/tw)+1)):
                for tm in range(1, min(ceil(workload['M']/sp_m_d2/sp_m_d3), floor(hw_conf['N_PSUM']/tw/th))+1):
                    ti = ceil(workload['I']/sp_i_d1)
                    tj = ceil(workload['J'] / sp_j_d1)
                    for tn in range(1, min(ceil(workload['N']/sp_n_d1/sp_n_d3), floor(hw_conf['N_ACT']/tw/th)+1)):
                        # NOTE: ln can be 1 to workload boundary, the larger ln, the less psum I/O
                        for ln in range(1, ceil(workload['N']/sp_n_d1/sp_n_d3/tn)+1):
                            xm = ceil(workload['M'] / sp_m_d2 / sp_m_d2 / tm)
                            xn = ceil(workload['N'] / sp_n_d1 / sp_n_d3 / tn / ln)
                            xw = ceil(workload['W'] / sp_w_d3 / tw )
                            xh = ceil(workload['H'] / sp_h_d3 / th)
                            # FIXME: verify the hw constraints, maybe more than listed
                            ##CONST1: accumulation latency: D1(N_TILE/SBLK) + 4
                            if ((tw*th*tm) < (hw_conf['D1'] + 4)):
                                continue
                            ## CONST2: the weight buffer consumption should be less than N_W
                            if (tj*tj*tm*tn*ln*xn*xm>hw_conf['N_W']):
                                continue
                            ##CONST3:
                            ## ACT BUF REQUIREMENT
                            tmp1 = (abs(ti - workload['STRIDE']) + ti - workload['STRIDE'])/2
                            tmp2 = (abs(tj - workload['STRIDE']) + tj - workload['STRIDE']) / 2
                            act_buf = (ti * tw - tmp1 * (tw-1)) * (tj * th - tmp2 * (th-1))
                            if (act_buf>hw_conf['N_ACT']):
                                continue
                            ##CONST4:
                            if (tw*th*tm>hw_conf['N_PSUM']):
                                continue
                            # pass all requirement verification
                            # append the temporal solution for the current spatial-partition solution
                            tp_sol.append((tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh, act_buf))
        if (cnt%10==0):
            print("Gen for SP_COMB", cnt)
        cnt = cnt + 1
        global_sol.append(tp_sol)

    print("All partition combinations have been generated!")

    # generate the performance with different partition parameters
    global_perf = []
    for ii in range(0, len(global_sol)):
        (sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3, sp_b_d3) = sp_comb[ii]
        sp_opt_sol = global_sol[ii]
        tp_perf = []
        for tp_sol in sp_opt_sol:
            (tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh, act_buf) = tp_sol
            # TIME1: computation time
            ##FIXME: whether add the latency or not?
            time_comp = (tj*tj*tm*tw*th*tn*ln+hw_conf['D1']+4)*xm*xn*xw*xh
            # weight ram consumption for each TILE
            w_ram_consump = tj*tj*tm*tn*ln*xn*xm
            # partial sum buffer consumption for each SBLK
            psum_ram_consump = tw*th*tm
            # act read amount
            # FIXME: NOTE: we assume reuse the act `xm` times and set a buffer with a size of tp*tn*lp
            # act_rd = tp * tn * lp * xm * xn * xp * sp_n_d1 * sp_n_d3 * sp_p_d3
            act_rd = act_buf * ln * xw * xh * xn * xm * sp_n_d3 * sp_w_d3 * sp_h_d3 * sp_n_d1 * sp_i_d1 * sp_j_d1
            # psum write amount
            psum_wr = psum_ram_consump * xm * xn * xw * xh * sp_m_d2 * sp_m_d3 * sp_w_d3 * sp_h_d3
            # psum rd amount (for accumulation)
            psum_rd = psum_ram_consump * xm * (xn-1) * xw * xh * sp_m_d2 * sp_m_d3 * sp_w_d3 * sp_h_d3
            # record data
            tp_perf.append((time_comp, w_ram_consump, psum_ram_consump, act_rd, psum_wr, psum_rd))
        #
        global_perf.append(tp_perf)
    print("Performance for all partition solution has been generated!")

    with open('objs.pkl', 'wb') as dump_file:
        pickle.dump([sp_comb, global_sol, global_perf, hw_conf, workload], dump_file)
    dump_file.close()


