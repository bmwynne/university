import socket
import sys
from PacketLib import *
import time
from struct import *

def make_IP_pkt2(pkt_len = 60, message = '', **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/message
    return pkt

MAC = ['00:ca:fe:00:00:01', '00:ca:fe:00:00:02',
       '00:ca:fe:00:00:03', '00:ca:fe:00:00:04']

IP = ['192.168.1.1', '192.168.2.1', '192.168.3.1', '192.168.4.1']

TTL = 30

length = 64
DA = MAC[1]
SA = MAC[2]
dst_ip = IP[1]
src_ip = IP[2]
proto = 155

server_address = ''
root = 0
leaf = 0

#pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
#                  src_IP=src_ip, proto=proto, pkt_len=length)/pack('2sHBB','\0A',123,1,1)

#def make_IP_pkt2(pkt_len = 60, message = '', **kwargs):
#    if pkt_len < 60:
#        pkt_len = 60
#    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/message
#    return pkt

def barrier():
    # Create a UDS socket
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    # Connect the socket to the port where the server is listening
    
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

#        pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
#                          src_IP=src_ip, proto=proto, message = data)
        if root == 1:
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/pack('2sHBB','\0A',123,2,4)
        elif leaf == 1:
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/pack('2sHBB','\0A',123,2,3)
        else :
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/pack('2sHBB','\0A',123,2,2)
        
        print pkt
        print dir(pkt)
        pkt.show2()
        scapy.hexdump(pkt)
        sock.sendall(str(pkt))
        
        data = sock.recv(16)
        print data
        while data != 'released':
            data = sock.recv(16)

        print >>sys.stderr, 'received released signal : "%s"' % data

#        sock.close()
        while 1:
            time.sleep(10)
    finally:
        print >>sys.stderr, 'closing socket'
        while 1:
            time.sleep(10)
#        sock.close()

if __name__=='__main__':
    #print dir(pkt)
    #pkt.show()
    #scapy.hexdump(pkt)
    #print pkt.__len__()
    server_address = sys.argv[1]
    if len(sys.argv) > 2 : 
        if sys.argv[2]=='root':
            root = 1
        if sys.argv[2]=='leaf':
            leaf = 1
        
        
    barrier()
