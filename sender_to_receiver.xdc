#create_clock -period 10.000 -name clk_100 -waveform {0.000 5.000} [get_ports clk_100000]
#set_property PACKAGE_PIN C20 [get_ports clk_100000]
#set_property IOSTANDARD LVCMOS33 [get_ports clk_100000]

set_property CFGBVS VCCO [current_design]
set_property config_voltage 3.3 [current_design]

#1ere rangée
set_property PACKAGE_PIN P19 [get_ports lvds_clk_word_out_n]
set_property PACKAGE_PIN N18 [get_ports lvds_clk_word_out_p]

set_property PACKAGE_PIN V18 [get_ports {lvds_data_out_n[0]}]
set_property PACKAGE_PIN V17 [get_ports {lvds_data_out_p[0]}]

set_property PACKAGE_PIN R17 [get_ports {lvds_data_out_n[1]}]
set_property PACKAGE_PIN R16 [get_ports {lvds_data_out_p[1]}]

set_property PACKAGE_PIN U20 [get_ports {lvds_data_out_n[2]}]
set_property PACKAGE_PIN T20 [get_ports {lvds_data_out_p[2]}]

set_property PACKAGE_PIN Y17 [get_ports {lvds_data_out_n[3]}]
set_property PACKAGE_PIN Y16 [get_ports {lvds_data_out_p[3]}]


#3eme rangée
#set_property PACKAGE_PIN Y19 [get_ports lvds_clk_word_out_n]
#set_property PACKAGE_PIN Y18 [get_ports lvds_clk_word_out_p]

#set_property PACKAGE_PIN P16 [get_ports {lvds_data_out_n[0]}]
#set_property PACKAGE_PIN P15 [get_ports {lvds_data_out_p[0]}]

#set_property PACKAGE_PIN W19 [get_ports {lvds_data_out_n[1]}]
#set_property PACKAGE_PIN W18 [get_ports {lvds_data_out_p[1]}]

#set_property PACKAGE_PIN W20 [get_ports {lvds_data_out_n[2]}]
#set_property PACKAGE_PIN V20 [get_ports {lvds_data_out_p[2]}]

#set_property PACKAGE_PIN U15 [get_ports {lvds_data_out_n[3]}]
#set_property PACKAGE_PIN U14 [get_ports {lvds_data_out_p[3]}]


#2eme rangée
create_clock -period 40.000 -name clk_word_in -waveform {0.000 20.000} [get_ports lvds_clk_word_in_p]
set_property PACKAGE_PIN U19 [get_ports lvds_clk_word_in_n]
set_property PACKAGE_PIN U18 [get_ports lvds_clk_word_in_p]

set_property PACKAGE_PIN R18 [get_ports {lvds_data_in_n[0]}]
set_property PACKAGE_PIN T17 [get_ports {lvds_data_in_p[0]}]

set_property PACKAGE_PIN W16 [get_ports {lvds_data_in_n[1]}]
set_property PACKAGE_PIN V16 [get_ports {lvds_data_in_p[1]}]

set_property PACKAGE_PIN P20 [get_ports {lvds_data_in_n[2]}]
set_property PACKAGE_PIN N20 [get_ports {lvds_data_in_p[2]}]

set_property PACKAGE_PIN R14 [get_ports {lvds_data_in_n[3]}]
set_property PACKAGE_PIN P14 [get_ports {lvds_data_in_p[3]}]

set_property IOSTANDARD LVDS_25 [get_ports lvds_*]
