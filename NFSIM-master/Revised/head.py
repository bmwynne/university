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

   
