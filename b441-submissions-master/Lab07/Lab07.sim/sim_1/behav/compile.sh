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
echo "xvlog -m64 --relax -prj tb_AU_vlog.prj"
ExecStep $xv_path/bin/xvlog -m64 --relax -prj tb_AU_vlog.prj 2>&1 | tee compile.log
