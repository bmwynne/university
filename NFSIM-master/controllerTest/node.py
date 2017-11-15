# using Omer's opl_cosim.py as base for the program
# Kevin Lu
# 3.12.2014

import os
import sys
import time
import socket
import select
import Queue
import string

timeout = 1
counter = 1

#Omer's code
if __name__=='__main__':
    server_address = sys.argv[1] #current node's socket ../i
    next_address = sys.argv[2] #next node's socket ../i + 1
    rank = int(sys.argv[3]) # rank 1 means head, 2 means regular node (convert string arg to int)
    size = int(sys.argv[4]) #size parameter
    check = size -1    
    HELLO = "hello"        
    
    try: #see if sockets already exists
        os.unlink(server_address)
    except OSError:
        if os.path.exists(server_address):
            raise

    print "Server address " + server_address
    print "Next address " + next_address
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #server for each node.py is called 
    #case 1 where rank = 0 indicating a head node
    client1 = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #head client socket created
    if rank == 0 :        
        while 1 :
            #so client head will connect to next server continuously
            ret = client1.connect_ex(next_address)        
            if ret == 0:
                break
    
    print >>sys.stderr, 'starting up on %s' % server_address
    server.bind(server_address) #binds the current head server (./1)
    #head connects to next node, now head turns into a server to listen
    server.listen(5)
    
    inputs = [ server ] # list of servers (first one is head server)?
    outputs = [ ]
    message_queues = {}
    connection, client_address = server.accept()#server accpeting connection from other client nodes
    #connection and client is different for each node.py that is run
    
#============================================================================

    server.setblocking(0)
    inputs.append(connection)
    #message_queues[connection] = Queue.Queue() #queue not doing anything

#==============================================================================
    
    #case 2 where rank != 0 indicating a non-head node
    client2 = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) #socket created
    if rank != 0:        
        while 1: 
            #connect to the next node ./2 -> ./3 
            ret = client2.connect_ex(next_address)                                                
            if rank == check and ret == 0: #check is size - 1
                print >>sys.stderr, "last node reached and connected" # last node reached
                client2.sendall("Ring established") #tell head last node is connected
                break                
            if ret == 0:
                break
            
    #head node receives the ring established data from last node
    if rank == 0:
        dataSent = connection.recv(1024) #head recv'ed
        print >>sys.stderr, 'confirm receipt of data "%s"' % dataSent #head says its reached
        #once head receives the confirmation, head sends data to its connected node
        if dataSent == "Ring established":            
            client1.sendall(HELLO)
            print >>sys.stderr, 'Head sending data to next node: "%s"' % HELLO #display what will be sent

    #head node receives the final incremenrted hello, not ring established  
    if rank == 0:
        dataSent = connection.recv(1024)
        if dataSent != "Ring established":
            print "Final Hello has arrived at head, do stuff"
            
    #non-head nodes sending each other the hello + increment
    if rank != 0:                        
        dataSent = connection.recv(1024)
        print >>sys.stderr, 'confirm receipt of data "%s"' % dataSent #head says its reached       
        HELLO = "hello" + str(rank)        
        #print "After increment of increase, is now " + str(increase)
        client2.sendall(HELLO)
        print >>sys.stderr, 'Node sending data to next node: "%s"' % HELLO #display what will be sent
    
        
    
    line = 1
    print 'Starting simulation on netfpga : ',server_address
    while 1:
        readable, writable, exceptional = select.select(inputs, outputs, inputs, timeout)
        if not (readable): # need help here, readable socket list?
            print >>sys.stderr, ' empty cycle ------------------------------------------------' + str(line)
        else: #otherwise the readable has good sockets
            for s in readable:
                if s is server: # s == server socket
                    connection, client_address = s.accept() #accept connections                    
                        
        line = line +1






























#==================================NOTES=======================================================

# know the size of the ring, head - last node,
# if last node, connected by previous and connect to head
# python node.py server client rnak size


#start accepting data after some time
#first establish ring, then send data on head
#so after you see the empty cycles, accept user input
#after head and regular node have been executed, the empty cycle will run
#   --------------- etc --------------
#   <user input on head node cycle>


#reverse traffic of data - send hello from last to head, so everyone knows everyone connected 
#or send an ack to head and then the head can start to send to rest of ring to increment data
