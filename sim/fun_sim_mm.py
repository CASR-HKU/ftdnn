# sim for the overall data throughput


from math import floor as floor
from math import ceil as ceil

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
    'N': 8,
    'M': 200,
    'P': 512,
}


if __name__ == '__main__':

    # generate all possible `spatial partition` combinations
    sp_comb = []

    # STEP1: set up the fixed partition dim
    sp_n_d1 = min(hw_conf['D1'], workload['N'])
    sp_m_d2 = min(hw_conf['D2'], workload['M'])
    # STEP2: enumerate all possible combinations, regardless of the utilization
    for sp_n_d3 in range(1, min(hw_conf['D3'], ceil(workload['N']/sp_n_d1)) +1):
        for sp_m_d3 in range(1, min(floor(hw_conf['D3']/sp_n_d3), ceil(workload['M']/sp_m_d2))+1):
            sp_p_d3 = min(floor(hw_conf['D3']/sp_n_d3/sp_m_d3), workload['P'])
            sp_comb.append((sp_n_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_p_d3))



    global_sol = []
    for sp_opt in sp_comb:
        (sp_n_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_p_d3) = sp_opt
        tp_sol = []
        # generate all possible `temporal partition` combinations
        # STEP1: T dim
        # p starts from 2 due to the weight sharing
        for tp in range(2, min(ceil(workload['P']/sp_p_d3), hw_conf['N_ACT'])+1):
            for tn in range(1, min(ceil(workload['N']/sp_n_d1/sp_n_d3), floor(hw_conf['N_ACT']/tp))+1):
                for tm in range(1, min(ceil(workload['M']/sp_m_d2/sp_m_d3), floor(hw_conf['N_PSUM']/tp))+1):
                    for ln in range(1, ceil(workload['N']/sp_n_d1/sp_n_d3/tn)+1):
                        # the size of lp is constrainted by the psum_buf
                        lp = min(ceil(workload['P']/sp_p_d3/tp), floor(hw_conf['N_PSUM']/tm/tp))
                        # calculate how many times the previous block should be executed
                        xm = ceil(workload['M']/sp_m_d2/sp_m_d3/tm)
                        xn = ceil(workload['N']/sp_n_d1/sp_n_d3/tn/ln)
                        xp = ceil(workload['P']/sp_p_d3/lp/tp)
                        #FIXME: verify the hw constraints, maybe more than listed
                        ## CONST1: accumulation latency: D1(N_TILE/SBLK) + 4
                        if ((tp*tm)<(hw_conf['D1']+4)):
                            continue
                        ## CONST2: the weight buffer consumption should be less than N_W
                        if (tn*ln*tm*xm*xn>hw_conf['N_W']):
                            continue
                        ## CONST3:
                        if (tn*tm>hw_conf['N_ACT']):
                            continue
                        if (tp*tm*lp>hw_conf['N_PSUM']):
                            continue
                        # append the temporal solution for the current spatial-partition solution
                        tp_sol.append((xm, xn, xp, ln, lp, tm, tn, tp))
        # append to the global_sol which is coupled to the sp_comb
        global_sol.append(tp_sol)

    print("All partition combinations have been generated!")

    # generate the performance with different partition parameters
    global_perf = []
    for ii in range(0, len(global_sol)):
        (sp_n_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_p_d3) = sp_comb[ii]
        sp_opt_sol = global_sol[ii]
        tp_perf = []
        for tp_sol in sp_opt_sol:
            (xm, xn, xp, ln, lp, tm, tn, tp) = tp_sol
            # TIME1: computation time
            time_comp = (tp*tn*tm*ln*lp+hw_conf['D1']+4)*xm*xn*xp
            # weight ram consumption for each TILE
            w_ram_consump = tn*tm*ln*xm*xn
            # partial sum buffer consumption for each SBLK
            psum_ram_consump = tp*tm*lp
            # act read amount
            # FIXME: NOTE: we assume reuse the act `xm` times and set a buffer with a size of tp*tn*lp*ln
            # act_rd = tp * tn * ln * lp * xm * xn * xp * sp_n_d1 * sp_n_d3 * sp_p_d3
            act_rd =tp*tn*ln*lp*xn*xp*sp_n_d1*sp_n_d3*sp_p_d3
            # psum write amount
            psum_wr = psum_ram_consump * xm * xn * xp * sp_m_d2 * sp_m_d3 * sp_p_d3
            # psum rd amount (for accumulation)
            psum_rd = psum_ram_consump * xm * (xn-1) * xp * sp_m_d2 * sp_m_d3 * sp_p_d3
            # record data
            tp_perf.append((time_comp, w_ram_consump, psum_ram_consump, act_rd, psum_wr, psum_rd))
        #
        global_perf.append(tp_perf)
    print("Performance for all partition solution has been generated!")




