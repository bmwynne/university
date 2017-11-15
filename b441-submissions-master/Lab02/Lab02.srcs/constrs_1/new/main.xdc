## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

 ## USE THIS
 set_property PACKAGE_PIN V17 [get_ports {a}]					
     set_property IOSTANDARD LVCMOS33 [get_ports {a}]
 set_property PACKAGE_PIN V16 [get_ports {b}]                    
     set_property IOSTANDARD LVCMOS33 [get_ports {b}]
     
set_property PACKAGE_PIN U16 [get_ports {myAND}]					
     set_property IOSTANDARD LVCMOS33 [get_ports {myAND}]
set_property PACKAGE_PIN E19 [get_ports {myOR}]                    
     set_property IOSTANDARD LVCMOS33 [get_ports {myOR}]
set_property PACKAGE_PIN U19 [get_ports {myNOT}]                    
     set_property IOSTANDARD LVCMOS33 [get_ports {myNOT}]
 
 
 
 
 
 
 
 
 
