// FTDNN CONV configuration define

// Data length define
`define        PSUM_DATA_LEN                   32
`define        PBUF_DATA_LEN                   (2*`PSUM_DATA_LEN)
`define        WBUF_DATA_LEN                   16
`define        ACTBUF_DATA_LEN                 16

// Addr length define
`define        PBUF_ADDR_LEN                   9        // RAMB36E2, 15 - $clog2(`PBUF_DATA_LEN) = 9
`define        WBUF_ADDR_LEN                   10       // RAMB18E2, 14 - $clog2(`WBUF_DATA_LEN) = 10
`define        ACTBUF_ADDR_LEN                 7        // RAM128X1D
`define        ACTBUF_ADDRH_LEN                (`ACTBUF_ADDR_LEN-1)
`define        ACTBUF_ADDRM_LEN                (`ACTBUF_ADDR_LEN-2)

// For loop define
`define        FOR_LOOP_LEVEL                  3
`define        FOR_LOOP_K1                     200      // N
`define        FOR_LOOP_K2                     100      // M
`define        FOR_LOOP_K3                     150      // P

// Hardware spatial define
`define        HW_D1_K1                        4
`define        HW_D1_K2                        1
`define        HW_D1_K3                        1
`define        HW_D1                           4
`define        HW_D1_LEN                       $clog2(`HW_D1)

`define        HW_D2_K1                        1
`define        HW_D2_K2                        5
`define        HW_D2_K3                        1
`define        HW_D2                           5

`define        HW_D3_K1                        1
`define        HW_D3_K2                        2
`define        HW_D3_K3                        5
`define        HW_D3                           10

// Hardware temporal define
`define        HW_X_K1                         5
`define        HW_X_K1_LEN                     $clog2(`HW_X_K1)
// `define        HW_X_K2                         1
// `define        HW_X_K2_LEN                     $clog2(`HW_X_K2)
// `define        HW_X_K3                         1
// `define        HW_X_K3_LEN                     $clog2(`HW_X_K3)
`define        HW_X                            5

// `define        HW_L_K1                         1
// `define        HW_L_K1_LEN                     $clog2(`HW_L_K1)
// `define        HW_L_K2                         1
// `define        HW_L_K2_LEN                     $clog2(`HW_L_K2)
`define        HW_L_K3                         5
`define        HW_L_K3_LEN                     $clog2(`HW_L_K3)
`define        HW_L                            5

`define        HW_T_K1                         10
`define        HW_T_K1_LEN                     $clog2(`HW_T_K1)
`define        HW_T_K2                         10
`define        HW_T_K2_LEN                     $clog2(`HW_T_K2)
`define        HW_T_K3                         6
`define        HW_T_K3_LEN                     $clog2(`HW_T_K3)
`define        HW_T                            600

`define        HW_XLT_LEN                      (`HW_X_K1_LEN+`HW_L_K3_LEN+`HW_T_K1_LEN+`HW_T_K2_LEN+`HW_T_K3_LEN+`ACTBUF_ADDRM_LEN)
`define        HW_X_K1_POS                     (`HW_XLT_LEN-`HW_X_K1_LEN)
`define        HW_L_K3_POS                     (`HW_X_K1_POS-`HW_L_K3_LEN)
`define        HW_T_K1_POS                     (`HW_L_K3_POS-`HW_T_K1_LEN)
`define        HW_T_K2_POS                     (`HW_T_K1_POS-`HW_T_K2_LEN)
`define        HW_T_K3_POS                     (`HW_T_K2_POS-`HW_T_K3_LEN)
`define        ACTBUF_ADDRM_POS                (`HW_T_K3_POS-`ACTBUF_ADDRM_LEN)

// BUF addr define
`define        ACTBUF_ADDRM_MAX                ((`HW_T_K1*`HW_T_K3)>>1)
