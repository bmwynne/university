import socket
import sys
from PacketLib import *
import time
from struct import *

def str2hex(string):
    return ' '.join('%02x' % ord(b) for b in string)

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
SA = MAC[1]
dst_ip = IP[0]
src_ip = IP[1]
proto = 155

server_address = ''
rank = 0
root = 0
size = 0
sock=''
pkt =''

def barrier():
    try:  
        print root, rank, size  
        if root == rank and rank == 0:
            print '1'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,4)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        elif root == rank and rank == (size-1):
            print '2'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,5)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        elif root == rank :                  
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,0)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))      
        elif rank == 0 :
            print '3'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,1)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        elif rank == (size-1):
            print 'omer'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,1)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        elif rank < root:
            print '4'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,3)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        elif rank > root:
            print '5'
            pkt = make_IP_pkt2(dst_MAC=DA, src_MAC=SA, TTL=TTL, dst_IP=dst_ip,
                               src_IP=src_ip, proto=proto, pkt_len=length)/scapy.UDP(sport=45329)/pack('2sHBB','\0A',123,1,2)/pack('HHHHHHHH',rank_n,root_n,size_n,0,768,0,0,0)/pack('3Q',socket.htonl(1),socket.htonl(2),socket.htonl(3))
        
        
        start = time.time()
        sock.sendall(str(pkt))      
        if rank == root: 
            data = sock.recv(64)
        elapsed = (time.time() - start)
        print >>sys.stderr, 'received released signal : ', data, ' time : ',elapsed
    
    except socket.error, msg:
        print >>sys.stderr, msg
        sys.exit(1)

if __name__=='__main__':
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server_address = sys.argv[1]
    try:
        sock.connect(server_address)
    except socket.error, msg:
        print >>sys.stderr, msg
        sys.exit(1)
    
    rank = int(sys.argv[2])
    root = int(sys.argv[3])
    size = int(sys.argv[4])
    rank_n = socket.htons(int(sys.argv[2]))
    root_n = socket.htons(int(sys.argv[3]))
    size_n = socket.htons(int(sys.argv[4]))
        
    message = 'host0'
    sock.sendall(message)
    
    barrier()
    sock.close()
