#Pmod Header JA
#Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports {sck}]        
    set_property IOSTANDARD LVCMOS33 [get_ports {sck}]
#Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports {miso}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {miso}]
#Sch name = JA3
set_property PACKAGE_PIN J2 [get_ports {mosi}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {mosi}]
#Sch name = JA4
set_property PACKAGE_PIN G2 [get_ports {cs}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {cs}]

##7 segment display
set_property PACKAGE_PIN W7 [get_ports {SEG[0]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]
set_property PACKAGE_PIN W6 [get_ports {SEG[1]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]
set_property PACKAGE_PIN U8 [get_ports {SEG[2]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]
set_property PACKAGE_PIN V8 [get_ports {SEG[3]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]
set_property PACKAGE_PIN U5 [get_ports {SEG[4]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]
set_property PACKAGE_PIN V5 [get_ports {SEG[5]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]
set_property PACKAGE_PIN U7 [get_ports {SEG[6]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]

set_property PACKAGE_PIN U2 [get_ports {AN[0]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]
set_property PACKAGE_PIN U4 [get_ports {AN[1]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property PACKAGE_PIN V4 [get_ports {AN[2]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property PACKAGE_PIN W4 [get_ports {AN[3]}]                                        
        set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]

set_property PACKAGE_PIN W5 [get_ports clk]
    set_property IOSTANDARD LVCMOS33 [get_ports clk]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
    
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sck_IBUF] 
