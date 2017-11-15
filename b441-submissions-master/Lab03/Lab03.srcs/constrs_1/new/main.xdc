# 3-to-8 Decoder
set_property PACKAGE_PIN V17 [get_ports {c}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {c}]
set_property PACKAGE_PIN V16 [get_ports {b}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b}]
set_property PACKAGE_PIN W16 [get_ports {a}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a}]
	
# 1-to-4 Demultiplexer
set_property PACKAGE_PIN T1 [get_ports {s0}]					
    set_property IOSTANDARD LVCMOS33 [get_ports {s0}]
set_property PACKAGE_PIN R2 [get_ports {s1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {s1}]


# Button L mapped to D input
set_property PACKAGE_PIN W19 [get_ports d]						
	set_property IOSTANDARD LVCMOS33 [get_ports d]



# LEDS for DEcoder
set_property PACKAGE_PIN U16 [get_ports {d0}]					
    set_property IOSTANDARD LVCMOS33 [get_ports {d0}]
set_property PACKAGE_PIN E19 [get_ports {d1}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d1}]
set_property PACKAGE_PIN U19 [get_ports {d2}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d2}]
set_property PACKAGE_PIN V19 [get_ports {d3}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d3}]
set_property PACKAGE_PIN W18 [get_ports {d4}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d4}]
set_property PACKAGE_PIN U15 [get_ports {d5}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d5}]
set_property PACKAGE_PIN U14 [get_ports {d6}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {d6}]
set_property PACKAGE_PIN V14 [get_ports {d7}]					
    set_property IOSTANDARD LVCMOS33 [get_ports {d7}]                  

# Other LED for DMult
set_property PACKAGE_PIN P3 [get_ports {y0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {y0}]
set_property PACKAGE_PIN N3 [get_ports {y1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {y1}]
set_property PACKAGE_PIN P1 [get_ports {y2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {y2}]
set_property PACKAGE_PIN L1 [get_ports {y3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {y3}]