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
counter = 1

#start accepting data after some time 
#first establish ring, then send data on head
#so after you see the empty cycles , accept user input
#after head and regular node have been executed, the empty cycle will run 
#   --------------- etc -------------- 
#   <user input on head node cycle>


#Omer's code
if __name__=='__main__':
    server_address = sys.argv[1] #current node's socket ../i
    next_address = sys.argv[2] #next node's socket ../i + 1
    rank = int(sys.argv[3]) # rank 1 means head, 2 means regular node (convert string arg to int)
    size = int(sys.argv[4]) #size param 

    try:
        os.unlink(server_address)
    except OSError:
        if os.path.exists(server_address):
            raise

    print "Server address " + server_address
    print "Next address " + next_address
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #socket created
    
    #case 1 where rank=0 indicating a head node 
    if rank == 0 : #node created is head
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #create a client socket
        while 1 :
            ret = client.connect_ex(next_address) 
            #so client head will connect to next server continuously
            # client.sendall("hello world")
            # data = client.recv(1024)
            if ret == 0 :
                break
                  
    print >>sys.stderr, 'starting up on %s' % server_address
    server.bind(server_address)     
    # head connects to next node and now head turns into a server to listen (current head)
    server.listen(5)     
    inputs = [ server ] # list of servers (first one is head server)?
    outputs = [ ]
    message_queues = {}
    (connection, client_address) = server.accept() # (conn, address) pair
    
#================================================================================        
    
    print >>sys.stderr, "waiting for connection" # accepting clients and waiting
    #while True:
    data = connection.recv(1024)
    print >>sys.stderr, 'received "%s"' % data 
    if data:
        print >>sys.stderr, 'sending data back to the client'            
        connection.sendall(data)
        # else:
        #     print >>sys.stderr, 'no more data from', client_address
        #     break
    
#=============================================================================
    server.setblocking(0)
    inputs.append(connection)
    message_queues[connection] = Queue.Queue() #creating FIFO queue 
    #queue not doing anything
#==============================================================================

    #case 2 where rank != 0 indicating a non-head node (regular)
    if rank != 0: #so anything other than 0 (head) would be a regular node 
        
        #each rank is an identifier for the node, 0 , 1, 2, 3 etc.... 
        # then when rank == (size -1)  then we know the last node is connected
        
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #socket created        
        while 1 :            
            ret = client.connect_ex(next_address) #client socket connect to next node            
            #counter = counter + 1
            data = "hello world" + str(counter)           
            client.sendall(data)
            counter = counter + 1
            #print >>sys.stderr, 'received "%s"' % data            
            data = client.recv(1024)            
            if ret == 0:
                break
        if rank == size - 1: # here is when the last node 
            client.sendall("Reached last node")
            
#check if you are last node here.
#reverse traffic of data - send hello from last to head, so everyone knows everyone connected    # client.sendall("hello")     

#or send an ack to head and then the head can start to send to rest of ring to increment data

    print 'Starting simulation on netfpga : ',server_address
    while 1:
        readable, writable, exceptional = select.select(inputs, outputs, inputs, timeout)
        if not (readable): # need help here, readable socket list?
            print >>sys.stderr, ' empty cycle ------------------------------------------------' 
        else: #otherwise the readable has good sockets
            for s in readable: #for each s 
               
                if s is server: # s == server socket
                    connection, client_address = s.accept() #accept connections
#============================close if rank != 1============================================

#now need to pass the hello to the server and pass to next server, incrementing the hello




# know the size of the ring, head - last node, 
# if last node, connected by previous and connect to head 
# python node.py server client rnak size
















# for the ring send a message to the next nodes and increment the hello + (number), hello1 -> hello2 -> hello3 then go back to head and reset to resend.

# [head] -> [ 1] -> [ 2] -> [ 3] -> [ 4] -> [head still hello4] so when it sends it again, hello will be reset
#new loop to let the other nodes that the barrier is reached (release)
















 # while True:
    #     print >>sys.stderr, "waiting for connection to server"
    #     connection, client_addr = server.accept();
    #     while 1:
    #         data = connection.recv(16)
    #         connection.sendall(data)





























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

