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
ExecStep $xv_path/bin/xsim tb_fa4_behav -key {Behavioral:sim_1:Functional:tb_fa4} -tclbatch tb_fa4.tcl -log simulate.log
