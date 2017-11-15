#Kevin Lu and Brandon Wynne
#controller for creating the nodes using os.system
#ring works partially so far

import os
import sys
import time
import socket
import select
import Queue
import string
import subprocess

topoType = sys.argv[1]
numNodes = sys.argv[2]
counter = 1
numNodes = int(numNodes)
rank = 0
nodes = 1
size = numNodes


################################################# RING #################################################
# ring is run this way:
# python controller.py <topology type> <number of nodes>  which calls:
# python node.py <./server> <./client> <rank> <size>

if topoType == "ring": # test case for controller , supplying Ring topology type
    while counter < numNodes:
        subprocess.Popen("python node.py ./" + str(nodes) +" ./" + str(nodes + 1) + " " + str(rank) + " " + str(size), shell=True)
        rank = rank + 1 # head is 0, else increment the other ranks
        nodes = nodes + 1
        counter = counter + 1

        if counter == numNodes:
            headNode = 1
            os.system("python node.py ./" + str(nodes) + " ./"+ str(headNode) + " " + str(rank)  + " " + str(size))
            # last node connects back to head (headRank = 0)

#    Example:
# python root/opl_cosim.py root ../1
# python middle1/opl_cosim.py ../2 ../1
# python middle2/opl_cosim.py ../3 ../1
# python leaf1/opl_cosim.py leaf ../4 ../2
# python leaf2/opl_cosim.py leaf ../5 ../2
# python leaf3/opl_cosim.py leaf ../6 ../3
# python leaf4/opl_cosim.py leaf ../7 ../3



# tree topology type Complete Full-tree: so each node has 2 children and the level or height for them are all the same. 
#full trees: each node has 2 children or is a leaf
#http://courses.cs.vt.edu/~cs3114/Fall09/wmcquain/Notes/T03a.BinaryTreeTheorems.pdf


# so tree will always have an odd number of nodes, 3, 7, 11, 19 etc...
# Always a triangle

#     1
#   2   3
# 4  5 6  7

#=============================================================

root = "root"
counter = 0 #reset counter for this tree topo
nodeValue = 1 #start off tree as 1 - N
treeArray = [0 for i in range(numNodes)]
if topoType == 'tree':        
    
    while counter< numNodes: 
    #fill array with [1,2,3,4,5..] 
    #up to number of nodes requested by parameter in controller (argv[2])
        treeArray[counter] = nodeValue
        nodeValue = nodeValue + 1
        counter = counter + 1
        #array filled
    print treeArray
    # while counter < numNodes:
    #     subprocess.Popen("python tree.py " + root + " ./" + str(nodes), shell=True)




