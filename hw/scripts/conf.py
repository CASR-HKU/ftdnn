# Data structure define
WID_W = 16
WID_WADDR = 10
WID_ACT = 16
WID_ACTADDR = 6

# For loop define
LOOP_LEVEL = 3
LOOP_K1 = 200      # N
LOOP_K2 = 100      # M
LOOP_K3 = 150      # P

# TPE architecture define
WID_WBUF_ADDR = 10       # RAMB18E2, 14-bit bit addressable
WID_ACTBUF_ADDR = 7        # RAM128X1D, 7-bit bit addressable

# Hardware spatial define
# Kx: [K1, K2, ... ]
HW_D1_Kx = [4, 1, 1]
HW_D1 = 4

HW_D2_Kx = [1, 5, 1]
HW_D2 = 5

HW_D3_Kx = [1, 2, 5]
HW_D3 = 10

# Hardware temporal define
HW_X_Kx = [5, 1, 1]
HW_X = 5

HW_L_Kx = [1, 1, 5]
HW_L = 5

HW_T_Kx = [10, 10, 6]
HW_T = 600