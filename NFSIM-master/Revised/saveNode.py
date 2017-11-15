# using Omer's opl_cosim.py as base for the program
# Kevin Lu
# 3.12.2014

import os
import sys
import time
#from myhdl import *
#import pcap
import socket
import select
import Queue
import string

timeout = 1

#Omer's code
if __name__=='__main__':
    server_address = sys.argv[1] #current node's socket ../i
    next_address = sys.argv[2] #next node's socket ../i + 1
    rank = sys.argv[3]
    rank = int(sys.argv[3]) # rank 1 means head, 2 means regular node (convert string arg to int)

    try:
        os.unlink(server_address)
    except OSError:
        if os.path.exists(server_address):
            raise

    print "Server address " + server_address
    print "Next address " + next_address
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #socket created
    
    #case 1 where rank=1 indicating a head node
    if rank == 1 : #node created is head
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #create a client socket

        while 1 :
            ret = client.connect_ex(next_address) #so client head will connect to next node (server)
            if ret == 0 :
                break

    print >>sys.stderr, 'starting up on %s' % server_address
    server.bind(server_address) # head connects to next node and now head turns into a server to listen (current head)
    server.listen(5)

    inputs = [ server ]
    outputs = [ ]
    message_queues = {}
    connection, client_address = server.accept()
    server.setblocking(0)
    inputs.append(connection)
    message_queues[connection] = Queue.Queue()

    #case 2 where rank != 1 indicating a non-head node (regular)
    if rank != 1: #so anything other than 1 (head) would be a regular node
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #socket created

        while 1 :
            ret= client.connect_ex(next_address) #current socket connect to next node
            if ret == 0 :
                break
    
    print 'Starting simulation on netfpga : ',server_address
    while 1:
        readable, writable, exceptional = select.select(inputs, outputs, inputs, timeout)
        if not (readable):
            print >>sys.stderr, ' empty cycle ------------------------------------------------'            
        else:
            for s in readable:
                if s is server:
                    connection, client_address = s.accept()
        

# for the ring send a message to the next nodes and increment the hello + (number), hello1 -> hello2 -> hello3 then go back to head and reset to resend.

# [head] -> [ 1] -> [ 2] -> [ 3] -> [ 4] -> [head still hello4] so when it sends it again, hello will be reset
#new loop to let the other nodes that the barrier is reached (release)














































###############################################################
########### psudo code for how node.py would work##############
###############################################################

# next_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
# prev_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# if node_type == head:
# ret = next_sock.connect_ex(next_address)

# prev_sock.bind(own_address)
# prev_sock.listen(5)
# prev_connection, prev_address = prev_sock.accept()
# prev_sock.setblocking(0)

# if node_type!=head:
# ret = next_sock.connect_ex(next_address)
# inputs=[prev_sock,prev_connection,next_sock]


#code begins here

# next_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #next
# prev_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #previous
# #previous will be last node if current node is the head node

# if sys.argv[1] == 'head': #
#     client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #

# if sys.arg[1] != 'head': #must be a regular node which will not wait to be connected to

