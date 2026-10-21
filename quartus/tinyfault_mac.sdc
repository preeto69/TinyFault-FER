create_clock -name clk -period 10.000 [get_ports {clk}]
set_false_path -from [get_ports {rst_n}]
derive_clock_uncertainty
