from pyscipopt import Model
import numpy as np
import pandas
import time
import pickle

def conv_model(conf):
	model = Model("Example")  
	model.hideOutput()
	dram_rd_bw = 20 
	dram_wr_bw = 20
	adj = np.array([[0,1,0,0,1,1],
				[1,0,0,0,0,0],
			    [1,1,1,1,0,0],
			    [1,1,1,1,0,0],
			    [0,1,0,0,0,0],
			    [1,1,1,1,1,1]])

	x = {}
	for i in range(1, 7):
		for j in range(1, 7):
			x[i, j] = model.addVar(vtype="INTEGER", name="x(%s,%s)"%(i,j))

	C_comp = model.addVar("C_comp", vtype="INTEGER")
	C_psum = model.addVar("C_psum", vtype="INTEGER")
	C_act = model.addVar("C_act", vtype="INTEGER")
	C_rd = model.addVar("C_rd", vtype="INTEGER")
	C_rw = model.addVar("C_rw", vtype="INTEGER")
	C_exe = model.addVar("C_exe", vtype="INTEGER")
	X = model.addVar("X", vtype="INTEGER")
	L = model.addVar("L", vtype="INTEGER")
	T = model.addVar("T", vtype="INTEGER")



	for i in range(1, 7):
		for j in range(1, 7):
			model.addCons(x[i, j] >= 1) 

	for i in range(1, 7):
		for j in range(1, 7):
			if adj[j - 1, i - 1] == 0:
				model.addCons(x[i, j] == 1) 

	model.addCons(x[1, 1] * x[2, 1] * x[3, 1] * x[4, 1] * x[5, 1] * x[6, 1] <= conf['D1']) 
	model.addCons(x[1, 2] * x[2, 2] * x[3, 2] * x[4, 2] * x[5, 2] * x[6, 2] <= conf['D2']) 
	model.addCons(x[1, 3] * x[2, 3] * x[3, 3] * x[4, 3] * x[5, 3] * x[6, 3] <= conf['D3']) 

	model.addCons(x[1, 1] * x[1, 2] * x[1, 3] * x[1, 4] * x[1, 5] * x[1, 6] >= conf['M']) 
	model.addCons(x[2, 1] * x[2, 2] * x[2, 3] * x[2, 4] * x[2, 5] * x[2, 6] >= conf['N'])
	model.addCons(x[3, 1] * x[3, 2] * x[3, 3] * x[3, 4] * x[3, 5] * x[3, 6] >= conf['W'])
	model.addCons(x[4, 1] * x[4, 2] * x[4, 3] * x[4, 4] * x[4, 5] * x[4, 6] >= conf['H'])
	model.addCons(x[5, 1] * x[5, 2] * x[5, 3] * x[5, 4] * x[5, 5] * x[5, 6] >= conf['I'])
	model.addCons(x[6, 1] * x[6, 2] * x[6, 3] * x[6, 4] * x[6, 5] * x[6, 6] >= conf['J'])

	model.addCons(x[1, 4] * x[2, 4] * x[3, 4] * x[4, 4] * x[5, 4] * x[6, 4] <= X)
	model.addCons(x[1, 5] * x[2, 5] * x[3, 5] * x[4, 5] * x[5, 5] * x[6, 5] <= L)
	model.addCons(x[1, 6] * x[2, 6] * x[3, 6] * x[4, 6] * x[5, 6] * x[6, 6] <= T)
	model.addCons( X * (L * T + conf['D1'] + 6) <= C_comp)


	model.addCons(conf['N_ACT'] * X * L <= C_act)

	model.addCons(conf['N_PSUM']  * conf['D3'] *  X <= C_psum)

	model.addCons((C_psum + C_act) / dram_rd_bw <= C_rd)

	#model.addCons(C_psum / dram_wr_bw <= C_rw)

	model.addCons(C_comp <= C_exe)
	model.addCons(C_act <= C_exe)
	model.addCons(C_psum <= C_exe)
	model.addCons(C_rd <= C_exe)
	#model.addCons(C_rw <= C_exe)

	model.setObjective(C_exe)
	model.optimize()
	sol = model.getBestSol()

	out = np.zeros([6, 6], dtype=int)
	for i in range(1, 7):
		for j in range(1, 7):
			out[i-1, j-1] = sol[x[i, j]]
	
	return out


if __name__ == "__main__":

	hw = pandas.read_csv('hw_config.csv')
	sw = pandas.read_csv('GoogLeNet.csv')

	HW_KEY = ['D1', 'D2', 'D3', 'N_ACT', 'N_W', 'N_PSUM']
	SW_KEY = ['M', 'N', 'W', 'H', 'I', 'J']

	total_time = 0
	output_list = []
	for i in range(hw.shape[0]):
		for j in range(sw.shape[0]):
			conf = {}
			out_dict = {}
			for hw_key in HW_KEY:
				conf[hw_key] = hw[hw_key][i]
			for sw_key in SW_KEY:
				conf[sw_key] = sw[sw_key][j]
			
			begin = time.time()
			out = conv_model(conf)
			end = time.time()
			time_elapsed = end - begin
			total_time += time_elapsed

			out_dict['conf'] = conf
			out_dict['sol'] = out
			out_dict['time'] = time_elapsed

			output_list.append(out_dict)
			print(out_dict)
		break #run one hw config

	print('total_time: ', total_time)




















