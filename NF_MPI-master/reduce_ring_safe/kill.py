import os
import sys
p = os.popen('ps | grep opl_cosim',"r")
i=0;
while 1:
    line = p.readline()    
    if not line: break
    
    if i <  int(sys.argv[1]):
        command = 'kill -9 '+ line.split()[0]
        os.system(command)
    i = i+1    
