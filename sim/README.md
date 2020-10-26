# FTDNN software automatic workflow

1. Modify `conf.py`

    - MAP_PARAM

    - data size calculation in `wl2act_1d()`, `wl2w_1d()`, `wl2pusm_1d()`

1. Modify `data_gen.py`

    - calculation of `data_actout`

    - run `data_gen.py`

1. Check `data_partition.py`

    - should be OK for any workload

1. Check `idx_transform.py`

    - should be OK for any workload

1. Check `mem_gen_actbuf.py`

    - should be OK for any workload

1. Check `mem_gen_wbuf.py`

    - should be OK for any workload

1. Modify `ftdnn_sim.py`

    - Almost everything need to rewrite for new workload

## Data generator

- `data_gen.py` : Generate data and save in `./data/*.npy`.

- `data_partition.py` : Partition data based on index.

- `mem_gen_actbuf.py` : Generate `.dat` file for simulation.

- `mem_gen_wbuf.py` : Generate `.mem` file for BRAM init.

## Simulation

- `sim_sblk.py` : Simulate calculation in each SBLK.

- `workload_mapping.py` : Mapping workload index.

## Configuration

- `conf.py` : Global configuration.
