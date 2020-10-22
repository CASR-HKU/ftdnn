from pyscipopt import Model
import numpy as np
import pandas
import time

import gurobipy as gp
from gurobipy import GRB

def vargen_prodchain(auxvar, model, varlist):

	assert len(varlist) > 2, "Input varlist should be larger than two."
	auxvar.append(model.addVar(vtype=GRB.INTEGER))
	for ii in range(len(varlist)):
		auxvar.append(model.addVar(vtype=GRB.INTEGER))
		model.addConstr(auxvar[-2] * varlist[ii] == auxvar[-1])
	return auxvar[-1]


def conv_model(conf_hw, conf_workload):
	m = gp.Model("MIP")
	
	# word per cycle
	dram_rd_bw = 8 
	dram_wr_bw = 8

	loop_depth = 6

	adj = np.array([[0,1,0,0,1,1],
				[1,0,0,0,0,0],
			    [1,1,1,1,0,0],
			    [1,1,1,1,0,0],
			    [0,1,0,0,0,0],
			    [1,1,1,1,1,1]])

	# auxiliary variables for the gurobi quard constraint
	auxvar = []

	x = {}
	for i in range(loop_depth):
		for j in range(6): # 6 - D1,2,3,X,L,T
			x[i, j] = m.addVar(vtype=GRB.INTEGER, name="x(%s,%s)"%(i,j))

	# keep tile param of infeasible partition dim to 1
	m.addConstrs((x[i, j] == 1 for i in range(loop_depth) for j in range(6) if adj[j, i] == 0))

	# mapping matrix space constraint
	m.addConstrs((x[i, j] >= 1 for i in range(loop_depth) for j in range(6)))

	# spartial partition - D1,2,3
	for j in range(3):
		m.addConstr(vargen_prodchain(auxvar, m, [x[i, j] for i in range(5)]) <= conf_hw[list(conf_hw.keys())[j]])

	# worload amount
	for i in range(loop_depth):
		m.addConstr(vargen_prodchain(auxvar, m, [x[i, j] for j in range(5)]) >= conf_workload[list(conf_workload.keys())[i]])

	# constraint1: accumulation latency - tm * tw * th > D1 + lat (4)
	m.addConstr(vargen_prodchain(auxvar, m, [x[0, 5], x[2, 5], x[3, 5]]) >= (conf_hw['D1'] + 4))

	# constraint2: WBUF consumption <= N_W (tlx - m, n, i, j)
	n_w = m.addVar(vtype=GRB.INTEGER, name="n_w")
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, j] for i in [0, 1, 4, 5] for j in [5, 4, 3]]) == n_w)
	m.addConstr(n_w <= conf_hw['N_W'])

	# constraint3: ActBUF consumption <= N_ACT (t - n, w, h)
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, 5] for i in [1, 2, 3]]) <= conf_hw['N_ACT'])

	# constraint4: PSum consumption <= N_PSUM (tl - m, w, h)
	n_psum = m.addVar(vtype=GRB.INTEGER, name="n_psum")
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, j] for i in [0, 2, 3] for j in [5, 4]]) == n_psum)
	m.addConstr(n_psum <= conf_hw['N_PSUM'])

	# performance evaluation

	c_comp = m.addVar(vtype=GRB.INTEGER, name="c_comp")
	n_actrd = m.addVar(vtype=GRB.INTEGER, name="n_actrd")
	n_psumwr = m.addVar(vtype=GRB.INTEGER, name="n_psumwr")
	n_psumrd = m.addVar(vtype=GRB.INTEGER, name="n_psumrd")

	# final execution time
	c_exe = m.addVar(vtype=GRB.INTEGER, name="c_exe")

	# estimate the computation time
	c_comp = m.addVar(vtype=GRB.INTEGER, name="c_comp")
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, j] for i in range(5) for j in [5, 4, 3]]) == c_comp)
	c_x = m.addVar(vtype=GRB.INTEGER, name="c_x")
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, 3] for i in range(5)]) == c_x)
	c_l = m.addVar(vtype=GRB.INTEGER, name="c_l")
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, 4] for i in range(5)]) == c_l)

	# estimate actrd
	m.addConstr(vargen_prodchain(auxvar, m, [x[i, 5] for i in range(1, 4)] + [c_l, c_x])== n_actrd)
	
	# estimate psumwr
	m.addConstr(n_psum * c_x == n_psumwr)

	# estimate psumrd
	m.addConstr(n_psumwr == n_psumrd)

	# bandwidth constraints
	# m.addConstr((n_actrd / c_exe) + (n_psumrd / c_exe) <= dram_rd_bw)
	m.addConstr((n_actrd + n_psumrd) <= dram_rd_bw * c_exe)
	m.addConstr( n_psumwr <= dram_wr_bw * c_exe)
		
	m.addConstr(c_comp <= c_exe)
	m.addConstr((n_actrd + n_psumrd) <= c_exe * dram_rd_bw)
	m.addConstr(n_psumwr <= c_exe * dram_wr_bw)

	m.setObjective(c_exe, GRB.MINIMIZE)
	m.optimize()
	sol = m.getVars()

	return sol


if __name__ == "__main__":

	hw = pandas.read_csv('hw_config.csv')
	sw = pandas.read_csv('GoogLeNet.csv')

	HW_KEY = ['D1', 'D2', 'D3', 'N_ACT', 'N_W', 'N_PSUM']
	SW_KEY = ['M', 'N', 'W', 'H', 'I', 'J']

	total_time = 0
	output_list = []
	# for i in range(hw.shape[0]):
	# 	for j in range(sw.shape[0]):
	for i in range(1):
		for j in range(1):
			conf_hw = {}
			conf_workload = {}
			out_dict = {}
			for hw_key in HW_KEY:
				conf_hw[hw_key] = hw[hw_key][i]
			for sw_key in SW_KEY:
				conf_workload[sw_key] = sw[sw_key][j]
			
			begin = time.time()
			sol = conv_model(conf_hw, conf_workload)
			end = time.time()
			time_elapsed = end - begin
			total_time += time_elapsed

			out_dict['conf_hw'] = conf_hw
			out_dict['conf_workload'] = conf_workload
			out_dict['sol'] = sol
			out_dict['time'] = time_elapsed

			output_list.append(out_dict)
			print(out_dict)
		break #run one hw config

	print('total_time: ', total_time)




















