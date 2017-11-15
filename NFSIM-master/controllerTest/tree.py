# Kevin Lu and Brandon Wynne
# Converting Omer's opl_cosim.py to work with our tree.py
# Created: 4/20/2014
# Last updated: 4/27/2014
# Comments: Currently only works backwards?

import os
import sys
import time
# from myhdl import *
# import pcap
import socket
import select
import Queue
import string


if __name__=='__main__':
    server_addr = '' # start on server
    left_addr = '' # left side of tree
    right_addr = '' # right side of tree
    parent_addr = '' # previous node
    portmap = {}
    hq = 0 #host queue
    nq = 0 #net queue
    dq = 0 #dummy queue

    
    #first case where the argument is root -> root node
    if sys.argv[1] == 'root':
        if len(sys.argv) == 3 :
            print "This is the root node."
            server_addr = sys.argv[2]
            rank = int(sys.argv[3]) # index the node ( rank = 0 for root)
            size = int(sys.argv[4]) # size of root
            #left_addr = sys.argv[3]
            #right_addr = sys.argv[4]
        else :
            print 'Not correct input for root node \"python tree.py root <server_addr> \"'
            sys.exit()
    elif sys.argv[1] == 'leaf':
        if len(sys.argv) == 4 :
            print "This is a leaf node."
            server_addr = sys.argv[2]
            parent_addr = sys.argv[3]
            rank = int(sys.argv[4]) # index the node ( everything after 0 for leaf)
            size = int(sys.argv[5]) # size of leaf
        else:
            print 'Not correct input for leaf node \"python tree.py leaf <server_addr> <parent_addr> \"'
            sys.exit()
    else:
        if len(sys.argv) == 3:
            print "This is a middle node."
            server_addr = sys.argv[1]
            parent_addr = sys.argv[2]
            rank = int(sys.argv[3]) # index the middle ( everything after 0 for middle)
            size = int(sys.argv[4]) # size of middle
            #left_addr = sys.argv[3]
            #right_addr = sys.argv[4]
        else:
            print 'Not correct input for middle node \"python tree.py <server_addr> <parent_addr>\"'
            sys.exit()
            
    try:
        os.unlink(server_addr)
    except OSError:
        if os.path.exists(server_addr):
            raise
    #root node will now listen on its socket 
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(server_addr)
    server.listen(5) #3 incoming connections?
    inputs = [ server ]
    outputs = [ ] 
   
    message_queues = {}
    
    parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    if sys.argv[1] == 'leaf':
     #   parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        while 1: 
            ret = parent.connect_ex(parent_addr)
            if rank == size - 1 and ret == 0: 
                print >>sys.stderr, " The last node is reached and connected"
                parent.sendall("Tree established")
                break
            if ret == 0 :
                break
        message = 'net'
        parent.sendall(message) # sends 'net' up  from previously created 'leaf' socket
        key = parent.recv(16) # recieves and stores 'net' into variable key
        print key # prints net
        portmap['parent'] = parent # stores 'parent' value in portmap list
        parent.setblocking(0) 
        server.setblocking(0)
        inputs.append(parent) # adds parent to inputs list: inputs = [server, parent]
        print 'Starting simulation on netfpga : ',server_addr
        
    else:        
        connection, client_address = server.accept() # connection is socket created from server.accept()
                                                     # server.accept() returns socket and client_address
        server.setblocking(0)

        print >>sys.stderr, 'new connection from child 1', client_address
       
        type = connection.recv(8) 
            
        key=''# resets key
        if type == 'host':
            key = 'host'+str(hq)
            hq=hq+1
            portmap[key]=connection 
        elif type == 'net':
            key = 'net'+str(nq)
            nq=nq+1
            portmap['left']=connection
        else:
            key = 'dummy'+str(dq)
            dq=dq+1
            portmap[key]=connection
        connection.sendall(key)
        connection.setblocking(0)
        inputs.append(connection)
        message_queues[connection] = Queue.Queue()

        readable, writable, exceptional = select.select(inputs, outputs, inputs)
        for s in readable:
            if s is server:
                connection, client_address = s.accept()
                print >>sys.stderr, 'new connection from child 2', client_address
                type = connection.recv(8)
                print 'type : ',type
                key=''
                if type == 'host':
                    key = 'host'+str(hq)
                    hq=hq+1
                    portmap[key]=connection
                elif type == 'net':
                    key = 'net'+str(nq)
                    nq=nq+1
                    portmap['right']=connection
                else:
                    key = 'dummy'+str(dq)
                    dq=dq+1
                    portmap[key]=connection
                print 'key : ', key
                connection.sendall(key)
                connection.setblocking(0)
                inputs.append(connection)
                message_queues[connection] = Queue.Queue()


        if sys.argv[1] == 'root' :
            print 'Starting simulation on netfpga : ',server_addr
        else:
            parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            while 1 :
                ret= parent.connect_ex(parent_addr)
                if ret == 0 :
                    break

            message = 'net'
            parent.sendall(message)
            key = parent.recv(16)
            portmap['parent']=parent
            parent.setblocking(0)
            inputs.append(parent)
            print 'Starting simulation on netfpga : ', server_addr
    

   
############################################################################################



# if __name__=='__main__':
#     server_addr = ''
#     left_addr = ''
#     right_addr = ''
#     parent_addr = ''


#     if sys.argv[1] == 'root':  # Root is 'head' node connecting to either middle nodes or leaf nodes
#         if len(sys.argv) == 3: 
#             server_addr = sys.argv[2]
#             # left_addr = sys.argv[3]
#             # right_addr = sys.argv[4]
#         else:
#             print 'Not correct input for root node \ "python tree.py root <server_address> \"'
#             sys.exit()
   
#     if  sys.argv[1] == 'middle': # Middle is a node that either connects to another middle or leaf nodes
#         if len(sys.argv) == 3:
#             server_addr = sys.argv[1]
#             parent_addr = sys.argv[2]
#             # left_addr = sys.argv[3]
#             # right_addr = sys.argv[4]
#         else:
#             print 'Not correct input for middle node \ "python tree.py middle <server_address> <parent_address> \"'
#             sys.exit()
    
#     if sys.argv[1] == 'leaf': # Leaf is a node that has no children and can only connect to a middle or root
#         if len(sys.argv) == 4:
#             server_addr = sys.argv[2]
#             server_addr = sys.argv[3]
#         else:
#             print 'Not correct input for leaf node \ "python tree.py leaf <server_address> <parent_address> \"'
#             sys.exit()

#     try:
#         os.unlink(server_addr)
#     except OSError:
#         if os.path.exists(server_addr):
#             raise


#     # Creating server
#     server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
#     # Binding socket to port
#     server.bind(server_addr) 
#     # Listen for connection
#     server.listen(5)
        
#     inputs = [ server ]
#     outputs = [ ]
#     message_queues = { }

#     if sys.argv[1] == 'leaf':
#         parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
#         while 1:
#             ret = parent.connect_ex(parent_addr)
#             if ret == 0:
#                 break
            
#         key = parent.recv(16)
#         print key
#         portmap['parent'] = parent
#         parent.setblocking(0)
#         server.setblocking(0)
#         inputs.append(parent)
#         print 'Starting simulation on netfpga : ', server_addr
            
#     else:
#         connection, client_address = server.accept()
#         server.setblocking(0)
        
#         print >>sys.stderr, 'new connection from child 1', client_address
#         type = connection.recv(8)
   
#         key = ''
#         if type == 'host':
#             key = 'host' + str(hq)
#             hq = hq + 1
#             portmap[key] = connection
#         elif type == 'net':
#             key = 'net' + str(nq)
#             nq = nq + 1
#             portmap['left'] = connection
#         else:
#             key = 'dummy' + str(dq)
#             nq = nq + 1
#             portmap[key] = connection
            
#         connection.setblocking(0)
#         inputs.append(connection)
#         message_queues[connection] = Queue.Queue()
             
#         readable, writable, exceptional = select.select(inputs, outputs, inputs)
#         for s in readable:
#             if s is server:
#                 connection, client_address = s.accept() # accept server connection
#                 print >>sys.stderr, 'new connection from child 2', client_address
#                 type = connection.recv(8)
#                 print 'type: ', type
#                 key=''
#                 if type == 'host':
#                     key = 'host' + str(hq)
#                     nq = nq + 1
#                     portmap['right'] = connection
#                 elif type == 'net':
#                     key = 'net' + str(nq)
#                     nq = nq + 1
#                     portmap['right'] = connection
#                 else:
#                     key = 'dummy' + str(dq)
#                     dq = dq + 1
#                     portmap[key] = connection
#                     print 'key: ', key
#                     connection.setblocking(0)
#                     inputs.append(connection)
#                     message_queues[connection] = Queue.Queue()
                
#         # Wait for Children to connect to middle then connect to parents
#         # Middle listens
#     if sys.argv[1] == 'middle':
#         parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
#         while 1:
#             ret = parent.connect_ex(parent_addr)
#             if ret == 0:
#                 break
         
#         portmap['parent'] = parent
#         parent.setblocking(0)
#         server.setblocking(0)
#     else:
#         connection, client_address = server.accept()
#         server.setblocking(0)
#         print >>sys.stderr, ' new connection from middle 1', client_address
#         type = connection.recv(8)
#         key = ''
#         if type == 'host':
#             key = 'host' + str(hq)
#             hq = hq + 1
#             portmap[key] = connection
#         elif type == 'net':
#             key = 'net' + str(nq)
#             nq = nq + 1
#             portmap['left'] = connection
#         else:
#             key = 'dummy' + str(dq)
#             dq = dq + 1
#             portmap[key] = connection
          
#         connection.setblocking(0)
#         inputs.append(connection)
#         message_queues[connection] = Queue.Queue()
       
#         readable, writable, exceptional = select.select(inputs, outputs, inputs)
#         for s in readable:
#             if s is server:
#                 connection, client_address = s.accept() # accept server connection
#                 print >>sys.stderr, 'new connection from middle 2', client_address
#                 type = connection.recv(8)
#                 print 'type: ', type
#                 key=''
#                 if type == 'host':
#                     key = 'host' + str(hq)
#                     nq = nq + 1
#                     portmap['right'] = connection
#                 elif type == 'net':
#                     key = 'net' + str(nq)
#                     nq = nq + 1
#                     portmap['right'] = connection
#                 else:
#                     key = 'dummy' + str(dq)
#                     dq = dq + 1
#                     portmap[key] = connection
#                     print 'key: ', key
#                     connection.setblocking(0)
#                     inputs.append(connection)
#                     message_queues[connection] = Queue.Queue()


        
#     if sys.argv[1] == 'root':
#         print 'Starting simulation on netfpgs: ', server_addr
#     else:
#         parent = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
#         while 1:
#             ret = parent.connect_ex(parent_addr)
#             if ret == 0:
#                 break
#         message = 'net'
#         key = parent.recv(16)
#         portmap['parent'] = parent
#         parent.setblocking(0)
#         intputs.append(parent)
#         print 'Starting simulation on netfgpa: ', server_addr
                

                

        



        
