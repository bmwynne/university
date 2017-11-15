import socket
import sys
from PacketLib import *
import time

MAC = ['00:ca:fe:00:00:01', '00:ca:fe:00:00:02',
       '00:ca:fe:00:00:03', '00:ca:fe:00:00:04']

IP = ['192.168.1.1', '192.168.2.1', '192.168.3.1', '192.168.4.1']

TTL = 30

length = 64
DA = MAC[1]
SA = MAC[2]
dst_ip = IP[1]
src_ip = IP[2]
pkt = make_IP_pkt(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                  src_IP=src_ip, pkt_len=length)

def make_IP_pkt2(pkt_len = 60, message = '', **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/message
    return pkt

def barrier():
    # Create a UDS socket
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    # Connect the socket to the port where the server is listening
    server_address = '../netfpga1'
    print >>sys.stderr, 'connecting to %s' % server_address
    try:
        sock.connect(server_address)
    except socket.error, msg:
        print >>sys.stderr, msg
        sys.exit(1)

    try:    
        # Send data
        message = 'host'
        sock.sendall(message)

        data = sock.recv(8)
        print data

        pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                          src_IP=src_ip, message = data)

        print pkt
        print dir(pkt)
        pkt.show()
        sock.sendall(str(pkt))
        
        data = sock.recv(16)
        print data
        while data != 'released':
            data = sock.recv(16)

        print >>sys.stderr, 'received released signal : "%s"' % data

        while 1:
            time.sleep(10)
    finally:
        print >>sys.stderr, 'closing socket'
        while 1:
            time.sleep(10)
#        sock.close()

if __name__=='__main__':
    barrier()
