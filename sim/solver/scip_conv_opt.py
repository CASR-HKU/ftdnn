from pyscipopt import Model
import numpy as np
import pandas
import time
import pickle
from functools import reduce


def list_prod(vars):
	return reduce(lambda x, y : x * y, vars)

def conv_model(conf_hw, conf_workload):
	model = Model("Example")
	model.hideOutput()
	
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

	x = {}
	for i in range(loop_depth):
		for j in range(6): # 6 - D1,2,3,X,L,T
			x[i, j] = model.addVar(vtype="INTEGER", name="x(%s,%s)"%(i,j))

	# keep tile param of infeasible partition dim to 1
	for i in range(loop_depth):
		for j in range(6):
			if adj[j, i] == 0:
				model.addCons(x[i, j] == 1)

	# mapping matrix space constraint
	for i in range(loop_depth):
		for j in range(6):
			model.addCons(x[i, j] >= 1)


	# spartial partition - D1,2,3
	for j in range(3):
		model.addCons(list_prod([x[i, j] for i in range(5)]) <= conf_hw[list(conf_hw.keys())[j]])

	# worload amount
	for i in range(loop_depth):
		model.addCons(list_prod([x[i, j] for j in range(5)])  >= conf_workload[list(conf_workload.keys())[i]])

	# constraint1: accumulation latency - tm * tw * th > D1 + lat (4)
	model.addCons(list_prod([x[i, 5] for i in [0, 2, 3]]) >= (conf_hw['D1'] + 4))

	# constraint2: WBUF consumption <= N_W (tlx - m, n, i, j)
	n_w = model.addVar("n_w", vtype="INTEGER")
	model.addCons(list_prod([x[i, j] for i in [0, 1, 4, 5] for j in [5, 4, 3]]) == n_w)
	model.addCons(n_w <= conf_hw['N_W'])

	# constraint3: ActBUF consumption <= N_ACT (t - n, w, h)
	model.addCons(list_prod([x[i, 5] for i in [1, 2, 3]]) <= conf_hw['N_ACT'])

	# constraint4: PSum consumption <= N_PSUM (tl - m, w, h)
	n_psum = model.addVar("n_psum", vtype="INTEGER")
	model.addCons(list_prod([x[i, j] for i in [0, 2, 3] for j in [5, 4]]) == n_psum)
	model.addCons(n_psum <= conf_hw['N_PSUM'])

	# performance evaluation

	c_comp = model.addVar("c_comp", vtype="INTEGER")
	n_actrd = model.addVar("n_actrd", vtype="INTEGER")
	n_psumwr = model.addVar("n_psumwr", vtype="INTEGER")
	n_psumrd = model.addVar("n_psumrd", vtype="INTEGER")

	# final execution time
	c_exe = model.addVar("c_exe", vtype="INTEGER")

	# estimate the computation time
	c_comp = model.addVar("c_comp", vtype="INTEGER")
	model.addCons(list_prod([x[i, j] for i in range(5) for j in [5, 4, 3]]) == c_comp)

	c_x = model.addVar("c_x", vtype="INTEGER")
	model.addCons(list_prod([x[i, 3] for i in range(5)]) == c_x)
	c_l = model.addVar("c_l", vtype="INTEGER")
	model.addCons(list_prod([x[i, 4] for i in range(5)]) == c_l)

	# estimate actrd
	model.addCons(list_prod([x[i, 5] for i in range(1, 4)] + [c_l, c_x]) == n_actrd)
	
	# estimate psumwr
	model.addCons(n_psum * c_x == n_psumwr)

	# estimate psumrd
	model.addCons(n_psumwr == n_psumrd)

	# bandwidth constraints
	model.addCons((n_actrd / c_exe) + (n_psumrd / c_exe) <= dram_rd_bw)
	model.addCons((n_psumwr / c_exe) <= dram_wr_bw)
		
	model.addCons(c_comp <= c_exe)
	model.addCons((n_actrd + n_psumrd) / dram_rd_bw <= c_exe)
	model.addCons(n_psumwr / dram_wr_bw <= c_exe)



	model.setObjective(c_exe)
	model.optimize()
	sol = model.getBestSol()

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



















