# sim for the overall data throughput

from math import floor as floor
from math import ceil as ceil
from res_score_mm import res_score_mm

# dump log file
import pickle
# argument passer
import argparse
import os


parser = argparse.ArgumentParser(description='Input parameters of hardware config and workload.')
parser.add_argument('--hw_conf', type=int, nargs='+', help='hardware config [D1, D2, D3, N_ACT, N_W, N_PSUM]')
parser.add_argument('--workload', type=int, nargs='+', help='workload config [M, N, W, H, I, J, STRIDE]')
parser.add_argument('--model_name', type=str, nargs=1, help='network model name')
parser.add_argument('--print', type=bool, nargs=1, default=False, help='print flag')

args = parser.parse_args()


# set the hardware config
hw_conf = {
    'D1': args.hw_conf[0],
    'D2': args.hw_conf[1],
    'D3': args.hw_conf[2],
    'N_ACT': args.hw_conf[3], #NOTE: half of act_buf size (double buffering)
    'N_W': args.hw_conf[4], #NOTE: should be an integer times of 1K
    'N_PSUM': args.hw_conf[5], #NOTE: should be an integer times of 1K
}

workload = {
    'M': args.workload[0],
    'N': args.workload[1],
    'P': args.workload[2],
}

dump_name = './data/' +  str(args.model_name[0]) + '/sol_' + str(hw_conf['D1']) + '_' + str(hw_conf['D2']) + '_' + str(hw_conf['D3']) + '_' + str(hw_conf['N_ACT']) + '_' + str(hw_conf['N_W']) + '_' + str(hw_conf['N_PSUM']) + '_' + str(workload['M']) + '_' + str(workload['N']) + '_' + str(workload['P'])  + '.pkl'


if __name__ == '__main__':

    # if (not os.path.exists(dump_name)):

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


        # generate the performance with different partition parameters
        perf = []
        sol = []
        for ii in range(len(global_sol)-1, -1, -1):
            (sp_n_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_p_d3) = sp_comb[ii]
            sp_opt_sol = global_sol[ii]
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
                perf.append((time_comp, w_ram_consump, psum_ram_consump, act_rd, psum_wr, psum_rd))
                sol.append((sp_n_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_p_d3, xm, xn, xp, ln, lp, tm, tn, tp))
            # pop the item in global_sol to save memory
            global_sol.pop(ii)

        [opt_sol, opt_perf, opt_score] = res_score_mm(sol, perf, hw_conf, workload)

        with open(dump_name, 'wb') as dump_file:
            pickle.dump([opt_sol, opt_perf, opt_score, hw_conf, workload], dump_file)
        dump_file.close()

        # release memory
        del sol
        del perf
        del global_sol
        del sp_comb
        del opt_sol
        del opt_perf
        del opt_score
    #
    # else:
    #     print("[File exist: ]"+dump_name)





