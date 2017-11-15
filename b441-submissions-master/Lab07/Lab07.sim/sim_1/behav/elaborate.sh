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
ExecStep $xv_path/bin/xelab -wto 0568863938b04e18aa84d6b0853439cd -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot tb_AU_behav xil_defaultlib.tb_AU xil_defaultlib.glbl -log elaborate.log
