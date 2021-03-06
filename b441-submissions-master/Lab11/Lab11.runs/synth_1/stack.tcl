# 
# Synthesis run script generated by Vivado
# 

debug::add_scope template.lib 1
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7a35ticpg236-1L

set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/brandonwynne/Documents/IU/b441-submissions/Lab11/Lab11.cache/wt [current_project]
set_property parent.project_path C:/Users/brandonwynne/Documents/IU/b441-submissions/Lab11/Lab11.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
read_verilog -library xil_defaultlib C:/Users/brandonwynne/Documents/IU/b441-submissions/Lab11/Lab11.srcs/sources_1/new/main.v
read_xdc C:/Users/brandonwynne/Documents/IU/b441-submissions/Lab11/Lab11.srcs/constrs_1/new/main.xdc
set_property used_in_implementation false [get_files C:/Users/brandonwynne/Documents/IU/b441-submissions/Lab11/Lab11.srcs/constrs_1/new/main.xdc]

synth_design -top stack -part xc7a35ticpg236-1L
write_checkpoint -noxdef stack.dcp
catch { report_utilization -file stack_utilization_synth.rpt -pb stack_utilization_synth.pb }
