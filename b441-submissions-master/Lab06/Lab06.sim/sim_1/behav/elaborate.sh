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
ExecStep $xv_path/bin/xelab -wto 6e15ac10514b453e827f011c217ee26c -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot tb_fa4_behav xil_defaultlib.tb_fa4 xil_defaultlib.glbl -log elaborate.log
