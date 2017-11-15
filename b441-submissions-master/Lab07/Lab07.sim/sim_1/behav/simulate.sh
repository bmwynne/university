#!/bin/sh -f
xv_path="/l/Xilinx_Vivado-2015.2_0626_1/Vivado/2015.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xsim tb_AU_behav -key {Behavioral:sim_1:Functional:tb_AU} -tclbatch tb_AU.tcl -log simulate.log
