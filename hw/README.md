# FTDNN hardware automatic workflow

## Creat Vivado projet

```bash
  cd ./tcl
  vivado -source ftdnn.tcl
```

## Modify RTL code

1. Modify `ftdnn_conf.vh`

    - Hardware spatial define

    - Hardware temporal define

      - number of variable

      - bit width of variable

1. Modify `sblk_ctrl.sv`

    - Temporal loop read

      - number of variable

      - BUF capacity calculation

    - Temporal loop control

      - number of variable

    - Calculation control

      - address calculation

1. Modify `tb_sblk_row.sv`

    - Temoral loop param

    - Finish condition

## Generate data file

1. ACTBUF file

    - `actbuf_x_x_x_x.dat` for ACTBUF write in simulation.

1. WBUF file

    - `wbuf_x_x_x.mem` for WBUF initialization.

    - WBUF file need to be add to Vivado project manually.

## Simulation

Run Vivado simulation and compare results with results from Python simulation.
