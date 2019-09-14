# sim for the overall data throughput

from math import floor as floor
from math import ceil as ceil
from res_score_conv import res_score_conv

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
    'W': args.workload[2],
    'H': args.workload[3],
    'I': args.workload[4],
    'J': args.workload[5],
    'STRIDE': args.workload[6]
}

dump_name = './data/' +  str(args.model_name[0]) + '/sol_' + str(hw_conf['D1']) + '_' + str(hw_conf['D2']) + '_' + str(hw_conf['D3']) + '_' + str(hw_conf['N_ACT']) + '_' + str(hw_conf['N_W']) + '_' + str(hw_conf['N_PSUM']) + '_' + str(workload['M']) + '_' + str(workload['N']) + '_' + str(workload['W']) + '_' + str(workload['H']) + '_' + str(workload['I']) + '_' + str(workload['J']) + '_' + str(workload['STRIDE']) + '.pkl'

if __name__ == '__main__':

    if (not os.path.exists(dump_name)):
        
        # generate all possible `spatial partition` combinations
        sp_comb = []

        # STEP1: enumerate all possible combinations, regardless of the utilization
        for sp_n_d1 in range(1, min(hw_conf['D1'], workload['N'])+1):
            for sp_i_d1 in range(1, min(floor(hw_conf['D1']/sp_n_d1), workload['I']) + 1):
                for sp_j_d1 in range(1, min(floor(hw_conf['D1'] / sp_n_d1 / sp_i_d1), workload['J']) + 1):
                    #FIXME: check if the `sp_m_d2` can be other values, i.e. not fully utilize the D2 but achieve better score
                    # for sp_m_d2 in range(1, min(hw_conf['D2'], workload['M'])+1):
                    sp_m_d2 = min(hw_conf['D2'], workload['M'])
                    for sp_n_d3 in range(1, min(hw_conf['D3'], ceil(workload['N']/sp_n_d1))+1):
                        for sp_m_d3 in range(1, min(floor(hw_conf['D3']/sp_n_d3), ceil(workload['M']/sp_m_d2)) + 1):
                            for sp_w_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3), workload['W']) + 1):
                                for sp_h_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3 / sp_w_d3), workload['H']) + 1):
                                    # for sp_b_d3 in range(1, min(floor(hw_conf['D3'] / sp_n_d3 / sp_m_d3 / sp_w_d3 / sp_h_d3), workload['B']) + 1):
                                    sp_comb.append((sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3))


        # with open('objs.pkl', 'rb') as dump_file:
        #     sp_comb, hw_conf, workload = pickle.load(dump_file)
        # dump_file.close()


        cnt = 0
        global_sol = []
        for sp_opt in sp_comb:
            (sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3) = sp_opt
            tp_sol = []
            # generate all possible `temporal partition` combinations
            # tw starts from 2 due to the weight sharing
            for tw in range(2, min(ceil(workload['W']/sp_w_d3), hw_conf['N_ACT'])+1):
                for th in range(1, min(ceil(workload['H']/sp_h_d3), floor(hw_conf['N_ACT']/tw)+1)):
                    for tm in range(1, min(ceil(workload['M']/sp_m_d2/sp_m_d3), floor(hw_conf['N_PSUM']/tw/th))+1):
                        ti = ceil(workload['I']/sp_i_d1)
                        tj = ceil(workload['J'] / sp_j_d1)
                        for tn in range(1, min(ceil(workload['N']/sp_n_d1/sp_n_d3), floor(hw_conf['N_ACT']/tw/th)+1)):
                            # NOTE: ln can be 1 to workload boundary, the larger ln, the less psum I/O
                            for ln in range(1, ceil(workload['N']/sp_n_d1/sp_n_d3/tn)+1):
                                # FIXME: more fine-grained instructions, remove `ceil`!
                                xm = ceil(workload['M'] / sp_m_d2 / sp_m_d3 / tm)
                                xn = ceil(workload['N'] / sp_n_d1 / sp_n_d3 / tn / ln)
                                xw = ceil(workload['W'] / sp_w_d3 / tw)
                                xh = ceil(workload['H'] / sp_h_d3 / th)
                                # FIXME: verify the hw constraints, maybe more than listed
                                ##CONST1: accumulation latency: D1(N_TILE/SBLK) + 4
                                if ((tw*th*tm) < (hw_conf['D1'] + 4)):
                                    continue
                                ## CONST2: the weight buffer consumption should be less than N_W
                                if (ti*tj*tm*tn*ln*xn*xm>hw_conf['N_W']):
                                    continue
                                ##CONST3:
                                ## ACT BUF REQUIREMENT
                                tmp1 = int((abs(ti - workload['STRIDE']) + ti - workload['STRIDE'])/2)
                                tmp2 = int((abs(tj - workload['STRIDE']) + tj - workload['STRIDE']) / 2)
                                act_buf = (ti * tw - tmp1 * (tw-1)) * (tj * th - tmp2 * (th-1)) * tn  # miss `tn` before
                                if (act_buf>hw_conf['N_ACT']):
                                    continue
                                ##CONST4:
                                if (tw*th*tm>hw_conf['N_PSUM']):
                                    continue
                                # pass all requirement verification
                                # append the temporal solution for the current spatial-partition solution
                                tp_sol.append((tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh, act_buf))
            if args.print:
                if (cnt%10==0):
                    print("Gen for SP_COMB", cnt)
                cnt = cnt + 1
            global_sol.append(tp_sol)

        if args.print:
            print("All partition combinations have been generated!")

        # generate the performance with different partition parameters
        perf = []
        sol = []
        for ii in range(len(global_sol)-1, -1, -1):
            (sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3) = sp_comb[ii]
            sp_opt_sol = global_sol[ii]
            for tp_sol in sp_opt_sol:
                (tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh, act_buf) = tp_sol
                # TIME1: computation time
                ##FIXME: whether add the latency or not?
                time_comp = (ti*tj*tm*tw*th*tn*ln+hw_conf['D1']+4)*xm*xn*xw*xh
                # weight ram consumption for each TILE
                # FIXME: although xn, xm should be integer, the weight can be stored without overhead: more fine-grained instruction!
                # w_ram_consump = ti*tj*ceil(tm*xm)*tn*ceil(ln*xn)
                w_ram_consump = ti * tj * tm * xm * tn * xn * ln
                # partial sum buffer consumption for each SBLK
                psum_ram_consump = tw * th * tm
                # act read amount
                act_rd = act_buf * ln * xn * xw * xh * xm * sp_n_d3 * sp_w_d3 * sp_h_d3 * sp_n_d1 * sp_i_d1 * sp_j_d1
                # psum write amount
                psum_wr = psum_ram_consump * xm * xn * xw * xh * sp_m_d2 * sp_m_d3 * sp_w_d3 * sp_h_d3
                # psum rd amount (for accumulation)
                psum_rd = psum_ram_consump * xm * (xn - 1) * xw * xh * sp_m_d2 * sp_m_d3 * sp_w_d3 * sp_h_d3
                # record data
                perf.append((time_comp, w_ram_consump, psum_ram_consump, act_rd, psum_wr, psum_rd))
                sol.append((sp_n_d1, sp_i_d1, sp_j_d1, sp_m_d2, sp_n_d3, sp_m_d3, sp_w_d3, sp_h_d3, tw, th, tm, ti, tj, tn, ln, xm, xn, xw, xh))
            # pop the item in global_sol to save memory
            global_sol.pop(ii)
        if args.print:
            print("Performance for all partition solution has been generated!")


        # evaluate the solution
        [opt_sol, opt_perf, opt_score] = res_score_conv(sol, perf, hw_conf, workload)

        # tmp: doump the result
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

    else:
        print("[File exist: ]"+dump_name)




