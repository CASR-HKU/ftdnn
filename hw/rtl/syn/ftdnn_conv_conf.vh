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

// Hardware spatial define
`define        HW_D1                           9
`define        HW_D1_LEN                       $clog2(`HW_D1)
`define        HW_D2                           8
`define        HW_D3                           16

// Hardware temporal define
`define        HW_TEMP_PARAM0_LEN              4
`define        HW_TEMP_PARAM1_LEN              4
`define        HW_TEMP_PARAM2_LEN              4
`define        HW_TEMP_PARAM3_LEN              4
`define        HW_TEMP_PARAM4_LEN              4
`define        HW_TEMP_PARAM5_LEN              4
`define        HW_TEMP_PARAM6_LEN              4
`define        HW_TEMP_PARAM7_LEN              4

`define        HW_TEMP_PARAM_LEN               32
`define        HW_TEMP_PARAM0_POS              0
`define        HW_TEMP_PARAM1_POS              (`HW_TEMP_PARAM0_POS+`HW_TEMP_PARAM0_LEN)
`define        HW_TEMP_PARAM2_POS              (`HW_TEMP_PARAM1_POS+`HW_TEMP_PARAM1_LEN)
`define        HW_TEMP_PARAM3_POS              (`HW_TEMP_PARAM2_POS+`HW_TEMP_PARAM2_LEN)
`define        HW_TEMP_PARAM4_POS              (`HW_TEMP_PARAM3_POS+`HW_TEMP_PARAM3_LEN)
`define        HW_TEMP_PARAM5_POS              (`HW_TEMP_PARAM4_POS+`HW_TEMP_PARAM4_LEN)
`define        HW_TEMP_PARAM6_POS              (`HW_TEMP_PARAM5_POS+`HW_TEMP_PARAM5_LEN)
`define        HW_TEMP_PARAM7_POS              (`HW_TEMP_PARAM6_POS+`HW_TEMP_PARAM6_LEN)
