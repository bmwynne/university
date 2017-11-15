#controller for creating the nodes using os.system

import os
import sys
import time
#from myhdl import *
#import pcap
import socket
import select
import Queue
import string
import subprocess

topoType = sys.argv[1] #don't read from sys.argv, use cmd line options
numNodes = sys.argv[2]
counter = 1
numNodes = int(numNodes)
rank = 0
nodes = 1
size = numNodes

#use python command line options instead of if statements if showing to people 

#print sys.argv
if topoType == "ring": # test case for controller , supplying Ring topology type
    while counter < numNodes:        
        # os.system("python node.py ./" + str(nodes) +" ./" + str(nodes + 1) + " " + str(head))       
        # head = 0
        # nodes = nodes + 1
        # counter = counter + 1
        # if counter == numNodes:
        #     headNode = 1        
        #     os.system("python node.py ./" + str(nodes) + " ./"+ str(headNode) + " " + str(head))
           
        subprocess.Popen("python node.py ./" + str(nodes) +" ./" + str(nodes + 1) + " " + str(rank) + " "  + str(size), shell=True)        
        rank = rank + 1
        nodes = nodes + 1
        counter = counter + 1
        if counter == numNodes:
            headNode = 1        
            os.system("python node.py ./" + str(nodes) + " ./"+ str(headNode) + " " + str(rank) + " " + str(size))
        
    # counter = 1
    # head = 1
    # nodes = 1
    






#tree topo - simult or individually
