import socket
import sys
import os 
from struct import *

messages = [ 'This is the message. ',
             'It will be sent ',
             'in parts.',
             ]
server_address = '../uds_socket'

# Create a TCP/IP socket
socks = [ socket.socket(socket.AF_UNIX, socket.SOCK_STREAM),
          socket.socket(socket.AF_UNIX, socket.SOCK_STREAM),
          socket.socket(socket.AF_UNIX, socket.SOCK_STREAM),
          socket.socket(socket.AF_UNIX, socket.SOCK_STREAM),
          ]

# Connect the socket to the port where the server is listening
print >>sys.stderr, 'connecting to %s' % server_address
for s in socks:
    s.connect(server_address)

i=0;
#for s in socks:
#    client_id = pack('i',i)
#    s.send(client_id)
#    i=i+1

for message in messages:

    # Send messages on both sockets
    for s in socks:
        print >>sys.stderr, '%s: sending "%s"' % (s.getsockname(), message)
        leng=len(message)
        print leng
        key = 'i'+leng.__str__()+'s'
        mes = pack(key,i,message)
        s.send(mes)
        i=i+1;

    # Read responses on both sockets
    for s in socks:
        data = s.recv(1024)
        print >>sys.stderr, '%s: received "%s"' % (s.getsockname(), data)
        if not data:
            print >>sys.stderr, 'closing socket', s.getsockname()
            s.close()
