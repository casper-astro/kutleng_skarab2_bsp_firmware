# Base Reference Clock

set_property PACKAGE_PIN AW20 [get_ports sysclk1_300_p]
set_property PACKAGE_PIN AW19 [get_ports sysclk1_300_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sysclk1_300_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sysclk1_300_n]





set_property LOC CMACE4_X0Y7 [get_cells -hierarchical -filter {NAME =~ *inst/i_EthMACPHY100GQSFP14x_top/* && REF_NAME==CMACE4}]



set_property LOC CMACE4_X0Y6 [get_cells -hierarchical -filter {NAME =~ *inst/i_EthMACPHY100GQSFP24x_top/* && REF_NAME==CMACE4}]

# Debug LEDs
set_property PACKAGE_PIN BA20 [get_ports {blink_led[0]}]
set_property PACKAGE_PIN BB21 [get_ports {blink_led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {blink_led[*]}]

#This is the partial loaded pins
set_property PACKAGE_PIN BC21 [get_ports partial_bit_led]
set_property IOSTANDARD LVCMOS18 [get_ports partial_bit_led]

# QSFP0 Clock
set_property PACKAGE_PIN T10 [get_ports mgt_qsfp2_clock_n]
set_property PACKAGE_PIN T11 [get_ports mgt_qsfp2_clock_p]



#QSFP0 MGT Signals
#RX0
#TX0
set_property PACKAGE_PIN U4 [get_ports qsfp2_mgt_rx0_p]
set_property PACKAGE_PIN U3 [get_ports qsfp2_mgt_rx0_n]
set_property PACKAGE_PIN U9 [get_ports qsfp2_mgt_tx0_p]
set_property PACKAGE_PIN U8 [get_ports qsfp2_mgt_tx0_n]

#RX1
#TX1
set_property PACKAGE_PIN T2 [get_ports qsfp2_mgt_rx1_p]
set_property PACKAGE_PIN T1 [get_ports qsfp2_mgt_rx1_n]
set_property PACKAGE_PIN T7 [get_ports qsfp2_mgt_tx1_p]
set_property PACKAGE_PIN T6 [get_ports qsfp2_mgt_tx1_n]

#RX2
#TX2
set_property PACKAGE_PIN R4 [get_ports qsfp2_mgt_rx2_p]
set_property PACKAGE_PIN R3 [get_ports qsfp2_mgt_rx2_n]
set_property PACKAGE_PIN R9 [get_ports qsfp2_mgt_tx2_p]
set_property PACKAGE_PIN R8 [get_ports qsfp2_mgt_tx2_n]

#RX3
#TX3
set_property PACKAGE_PIN P2 [get_ports qsfp2_mgt_rx3_p]
set_property PACKAGE_PIN P1 [get_ports qsfp2_mgt_rx3_n]
set_property PACKAGE_PIN P7 [get_ports qsfp2_mgt_tx3_p]
set_property PACKAGE_PIN P6 [get_ports qsfp2_mgt_tx3_n]

# QSFP0 Settings
set_property PACKAGE_PIN BE21 [get_ports qsfp2_intl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp2_intl_ls]
set_property PACKAGE_PIN BD18 [get_ports qsfp2_lpmode_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp2_lpmode_ls]
set_property PACKAGE_PIN BE20 [get_ports qsfp2_modprsl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp2_modprsl_ls]
set_property PACKAGE_PIN BE16 [get_ports qsfp2_modsell_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp2_modsell_ls]
set_property PACKAGE_PIN BE17 [get_ports qsfp2_resetl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp2_resetl_ls]




# QSFP1 Clocks
set_property PACKAGE_PIN M10 [get_ports mgt_qsfp1_clock_n]
set_property PACKAGE_PIN M11 [get_ports mgt_qsfp1_clock_p]



#QSFP1 MGT Signals

#RX0
#TX0
set_property PACKAGE_PIN N4 [get_ports qsfp1_mgt_rx0_p]
set_property PACKAGE_PIN N3 [get_ports qsfp1_mgt_rx0_n]
set_property PACKAGE_PIN N9 [get_ports qsfp1_mgt_tx0_p]
set_property PACKAGE_PIN N8 [get_ports qsfp1_mgt_tx0_n]

#RX1
#TX1
set_property PACKAGE_PIN M2 [get_ports qsfp1_mgt_rx1_p]
set_property PACKAGE_PIN M1 [get_ports qsfp1_mgt_rx1_n]
set_property PACKAGE_PIN M7 [get_ports qsfp1_mgt_tx1_p]
set_property PACKAGE_PIN M6 [get_ports qsfp1_mgt_tx1_n]

#RX2
#TX2
set_property PACKAGE_PIN L4 [get_ports qsfp1_mgt_rx2_p]
set_property PACKAGE_PIN L3 [get_ports qsfp1_mgt_rx2_n]
set_property PACKAGE_PIN L9 [get_ports qsfp1_mgt_tx2_p]
set_property PACKAGE_PIN L8 [get_ports qsfp1_mgt_tx2_n]

#RX3
#TX3
set_property PACKAGE_PIN K2 [get_ports qsfp1_mgt_rx3_p]
set_property PACKAGE_PIN K1 [get_ports qsfp1_mgt_rx3_n]
set_property PACKAGE_PIN K7 [get_ports qsfp1_mgt_tx3_p]
set_property PACKAGE_PIN K6 [get_ports qsfp1_mgt_tx3_n]

# QSFP1 Settings

set_property PACKAGE_PIN AV21 [get_ports qsfp1_intl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp1_intl_ls]
set_property PACKAGE_PIN AV22 [get_ports qsfp1_lpmode_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp1_lpmode_ls]
set_property PACKAGE_PIN BC19 [get_ports qsfp1_modprsl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp1_modprsl_ls]
set_property PACKAGE_PIN AY20 [get_ports qsfp1_modsell_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp1_modsell_ls]
set_property PACKAGE_PIN BC18 [get_ports qsfp1_resetl_ls]
set_property IOSTANDARD LVCMOS18 [get_ports qsfp1_resetl_ls]

#USB UART for Microblaze
set_property PACKAGE_PIN BB20 [get_ports rs232_uart_rxd];
set_property IOSTANDARD LVCMOS18 [get_ports rs232_uart_rxd];
set_property PACKAGE_PIN BF18 [get_ports rs232_uart_txd];
set_property IOSTANDARD LVCMOS18 [get_ports rs232_uart_txd];



# Exceptions
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets GMAC1_i/MACPHY_QSFP1_i/inst/gt_ref_clk]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets GMAC2_i/MACPHY_QSFP2_i/inst/gt_ref_clk]

# Timing exceptions




set_property BITSTREAM.GENERAL.PERFRAMECRC yes [current_design]

set_property ASYNC_REG true [get_cells {RXAXIS_i/U0/PROBE_PIPE.shift_probes_reg[0][1158]}]
set_property ASYNC_REG true [get_cells {RXAXIS_i/U0/PROBE_PIPE.shift_probes_reg[1][1158]}]
set_property ASYNC_REG true [get_cells {RXAXIS_i/U0/PROBE_PIPE.shift_probes_reg[0][1162]}]
set_property ASYNC_REG true [get_cells {RXAXIS_i/U0/PROBE_PIPE.shift_probes_reg[1][1162]}]
create_clock -period 3.333 [get_ports sysclk1_300_p]
set_input_jitter [get_clocks -of_objects [get_ports sysclk1_300_p]] 0.010
create_clock -period 6.400 [get_ports mgt_qsfp2_clock_p]
create_clock -period 6.400 [get_ports mgt_qsfp1_clock_p]
set_false_path -from [get_cells *ClockGen100MHz_i/inst/seq_reg* -filter is_sequential]
set_clock_groups -asynchronous -group [get_clocks {txoutclk_out[0]}] -group [get_clocks clk_out2_clockgen100mhz]
set_clock_groups -asynchronous -group [get_clocks clk_out2_clockgen100mhz] -group [get_clocks {txoutclk_out[0]}]
set_clock_groups -asynchronous -group [get_clocks {txoutclk_out[0]}] -group [get_clocks {txoutclk_out[0]_1}]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets ClkQSFP1]
