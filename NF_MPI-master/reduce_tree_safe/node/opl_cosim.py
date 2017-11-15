import os
import sys
import time
from myhdl import *
import pcap
import socket
import select
import Queue
import string

packet=''
connection=''
client_address=''
inputs = []
outputs = []
timeout = 1
message_queues = {}
hq=0
nq=0
dq=0
portmap = {}

def get_packet(pktlen, data, timestamp):
    global packet
    #    if not data:
    #        return
    packet=data

def output_port_lookup(out_data, out_ctrl, out_wr, out_rdy, 
           in_data, in_ctrl, in_wr, in_rdy,
           reg_req_in, reg_ack_in, reg_rd_wr_L_in, reg_addr_in, reg_data_in, reg_src_in,
           reg_req_out, reg_ack_out, reg_rd_wr_L_out, reg_addr_out, reg_data_out, reg_src_out,
           clk, reset):

    cmd = "iverilog -o opl -c opl.txt"
    os.system(cmd)
    return Cosimulation("vvp  -m ./myhdl.vpi opl", 
                        out_data=out_data, out_ctrl=out_ctrl, out_wr=out_wr, out_rdy=out_rdy,
                        in_data=in_data, in_ctrl=in_ctrl, in_wr=in_wr, in_rdy=in_rdy,
                        reg_req_in=reg_req_in, reg_ack_in=reg_ack_in, reg_rd_wr_L_in=reg_rd_wr_L_in, 
                        reg_addr_in=reg_addr_in,reg_data_in=reg_data_in, reg_src_in=reg_src_in,
                        reg_req_out=reg_req_out, reg_ack_out=reg_ack_out, reg_rd_wr_L_out=reg_rd_wr_L_out, 
                        reg_addr_out=reg_addr_out, reg_data_out=reg_data_out, reg_src_out=reg_src_out,
                        clk=clk, reset=reset)
    
def testbench():
    global packet
    Half_Period = delay (1)

    out_data = Signal(intbv(0)[64:]) 
    out_ctrl = Signal(intbv(0)[8:]) 
    out_wr = Signal(bool(0))
    out_rdy = Signal(bool(0))

    in_data_list = [Signal(intbv(0)[8:]) for i in range(8)]            
    in_data = ConcatSignal(*reversed(in_data_list))
    in_ctrl = Signal(intbv(0)[8:]) 
    in_wr = Signal(bool(0))
    in_rdy = Signal(bool(0))

    reg_req_in = Signal(bool(0))
    reg_ack_in = Signal(bool(0))
    reg_rd_wr_L_in = Signal(bool(0))
    reg_addr_in = Signal(intbv(0)[23:])
    reg_data_in = Signal(intbv(0)[32:])
    reg_src_in = Signal(intbv(0)[2:])

    reg_req_out = Signal(bool(0))
    reg_ack_out = Signal(bool(0))
    reg_rd_wr_L_out = Signal(bool(0))
    reg_addr_out = Signal(intbv(0)[23:])
    reg_data_out = Signal(intbv(0)[32:])
    reg_src_out = Signal(intbv(0)[2:])

    clk = Signal(bool(0))
    reset = Signal(bool(1))

    def assign_reg_input():
        reg_req_in.next=0                        
        reg_ack_in.next=0
        reg_rd_wr_L_in.next=0
        reg_addr_in.next=0
        reg_data_in.next=0
        reg_src_in.next=0
        
    @always(Half_Period) 
    def clockGen():
        clk.next = not clk
#        reset.next = not reset
        
    @instance
    def stimulus():
        global hq
        global dq
        global dq
        global timeout
        reset.next = 1
        while 1:
            #reset.next = 1                
            readable, writable, exceptional = select.select(inputs, outputs, inputs,timeout)
            if not (readable):
                print >>sys.stderr, ' empty cycle ------------------------------------------------'
                yield clk.negedge
            else:
                for s in readable:
                    if s is server:
                        # A "readable" server socket is ready to accept a connection                                             
                        connection, client_address = s.accept()
                        type = connection.recv(8)
                        print 'new collection from : ',type
                        key=''
                        if type == 'host0':
                            portmap['host0']=connection
                        elif type == 'port0':
                            portmap['port0']=connection
                        elif type == 'port1':
                            portmap['port1']=connection
                        else:
                            sys.exit(0)
                        connection.setblocking(0)
                        inputs.append(connection)
                        # Give the connection a queue for data we want to send 
                        message_queues[connection] = Queue.Queue()
                        yield clk.negedge
                    else:
                        data = s.recv(1024)
                        port = ''
                        for port in portmap:
                            print portmap[port], s
                            if portmap[port]==s:
                                break
                        print port
                            
                        if data:
                            print '******* ',len(data), ' ',data
                            host_loc=data.find('\0A')
                            net_loc=data.find('B\0')
                            rls_loc=data.find('C\0')
                            #print host_loc,' ',net_loc,' ',rls_loc
                            print '--------------------------',port
                            if port == 'host0' :
                                print 'packet is from host'
                                if reset:
                                    reset.next = not reset

                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                assign_reg_input()
                                
                                in_data_list[0].next=len(data)                                                       
                                in_data_list[1].next=0
                                in_data_list[2].next=1 #int(data[host_loc+4])*2+1
                                in_data_list[3].next=0
                                in_data_list[4].next=len(data)/8
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
                                
                                yield clk.negedge
                                                                
                                for i in range(len(data)) :
                                    if i%8 == 0 :
                                        in_wr.next=1
                                        out_rdy.next=1
                                        in_ctrl.next=0
                                        assign_reg_input()
                                        #sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[7-j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                #byte = ord(data[i+j])
                                                #sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[7-j].next=0
                                                in_ctrl.next = 0x10
                                        #sys.stdout.write('\n')
                                        yield clk.negedge
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                assign_reg_input()

                                for i in range(8):
                                    in_data_list[i].next=0
                                yield clk.negedge
                            elif port == 'port0':
                                #print 'packet is from net'
                                if reset:
                                    reset.next = not reset
                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                assign_reg_input()
        
                                in_data_list[0].next=len(data)
                                in_data_list[1].next=0
                                in_data_list[2].next=0 #int(data[net_loc+3])*2
                                in_data_list[3].next=0
                                in_data_list[4].next=len(data)/8
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
        
                                yield clk.negedge
                                
                                for i in range(len(data)) :
                                    if i%8 == 0 :
                                        in_wr.next=1
                                        out_rdy.next=1
                                        in_ctrl.next=0
                                        assign_reg_input()
                                        #sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                byte = ord(data[i+j])
                                                #sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[j].next=0
                                                in_ctrl.next = 0x10
                                        #sys.stdout.write('\n')
                                        yield clk.negedge
                                
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                assign_reg_input()

                                for i in range(8):
                                    in_data_list[i].next=0
                                yield clk.negedge
                            elif port == 'port1':
                                #print 'packet is from net'
                                if reset:
                                    reset.next = not reset
                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                assign_reg_input()
        
                                in_data_list[0].next=len(data)
                                in_data_list[1].next=0
                                in_data_list[2].next=2 #int(data[net_loc+3])*2
                                in_data_list[3].next=0
                                in_data_list[4].next=len(data)/8
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
        
                                yield clk.negedge
                                
                                for i in range(len(data)) :
                                    if i%8 == 0 :
                                        in_wr.next=1
                                        out_rdy.next=1
                                        in_ctrl.next=0
                                        assign_reg_input()
                                        #sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                byte = ord(data[i+j])
                                                #sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[j].next=0
                                                in_ctrl.next = 0x10
                                        #sys.stdout.write('\n')
                                        yield clk.negedge
                                        
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                assign_reg_input()

                                for i in range(8):
                                    in_data_list[i].next=0
                                yield clk.negedge
                                
                            elif port == 'port2':
                                #print 'packet is from net'
                                if reset:
                                    reset.next = not reset
                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                assign_reg_input()
        
                                in_data_list[0].next=len(data)
                                in_data_list[1].next=0
                                in_data_list[2].next=4 #int(data[net_loc+3])*2
                                in_data_list[3].next=0
                                in_data_list[4].next=len(data)/8
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
        
                                yield clk.negedge
                                
                                for i in range(len(data)) :
                                    if i%8 == 0 :
                                        in_wr.next=1
                                        out_rdy.next=1
                                        in_ctrl.next=0
                                        assign_reg_input()
                                        #sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                byte = ord(data[i+j])
                                                #sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[j].next=0
                                                in_ctrl.next = 0x10
                                        #sys.stdout.write('\n')
                                        yield clk.negedge
                                
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                assign_reg_input()

                                for i in range(8):
                                    in_data_list[i].next=0
                                yield clk.negedge
                        else: #if data
                            if s in outputs:
                                outputs.remove(s)
                            inputs.remove(s)
                            s.close()
                            del message_queues[s]
                            #raise StopSimulation                            

    @instance
    def monitor():
        pkt=''
        out_encoded = 0
        key=''
        pkt=''
        port=''
        new_packet = 0
        while 1:
            yield clk.posedge
            #yield delay (1)            
        
            if ord(chr(out_ctrl)) == 0xff :
                out_encoded = ord(chr(out_data[56:48]))
                new_packet = 1

            elif ord(chr(out_ctrl)) == 0x0 and new_packet == 1:
                for i in range(8) :
                    pkt+=chr(out_data[8*(i+1):8*i]) 
            elif ord(chr(out_ctrl)) == 0x10 and new_packet == 1:
                for i in range(8) :
                    pkt+=chr(out_data[8*(i+1):8*i])        

                print 'out_encoded : ',out_encoded,'  pkt : ',pkt
                00010101
                if out_encoded != 0:
                    if out_encoded & 1 != 0 : 
                        port = portmap['port0']
                        if pkt.find('host0') > -1:
                            pkt2 = string.replace(pkt,'host0','net0')
                            print 'Sending : ',pkt2
                            port.sendall(pkt2)
                        else:
                            #print 'Sending : ',pkt
                            port.sendall(pkt)
                            
                    if out_encoded & 2 != 0 :
                        port = portmap['host0']
                        #if pkt.find('host0') > -1:
                        port.sendall(pkt)
                        
                    if out_encoded & 4 != 0 :
                        port = portmap['port1']
                        #if pkt.find('host0') > -1:
                        port.sendall(pkt)
                        print "net0"
                        
                    if out_encoded & 16 != 0 :
                        port = portmap['port2']
                        #if pkt.find('host0') > -1:
                        port.sendall(pkt)
                        print "net0"

                out_encoded = 0
                key=''
                pkt=''
                port=''
                new_packet = 0
            #else:
            #    print "error"


    up = output_port_lookup(out_data, out_ctrl, out_wr, out_rdy,
                            in_data, in_ctrl, in_wr, in_rdy,
                            reg_req_in, reg_ack_in, reg_rd_wr_L_in, reg_addr_in, reg_data_in, reg_src_in,
                            reg_req_out, reg_ack_out, reg_rd_wr_L_out, reg_addr_out, reg_data_out, reg_src_out,
                            clk, reset)

    return clockGen , stimulus , up , monitor

if __name__=='__main__':
    server_address = sys.argv[1]
    parent_address = sys.argv[2]
    leaf_left = 0
    leaf_right = 0
    left = 0
    right = 0
    root = 0
    
    if sys.argv[1] == 'root':
        root = 1
        server_address = sys.argv[2]
        rank = int(sys.argv[3])
        root = int(sys.argv[4])
        size = int(sys.argv[5])
    else:
        server_address = sys.argv[2]
        parent_address = sys.argv[3]
        rank = int(sys.argv[4])
        root = int(sys.argv[5])
        size = int(sys.argv[6])
    
    if sys.argv[1] == 'leaf_left':
        leaf_left = 1
    elif sys.argv[1] == 'leaf_right':
        leaf_right = 1
    elif sys.argv[1] == 'right':
        right = 1
    elif sys.argv[1] == 'left':
        left = 1
        
    try:
        os.unlink(server_address)
    except OSError:
        if os.path.exists(server_address):
            raise
    
    #print server_address
    #print next_address
    #print len(sys.argv)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    
    print rank,root,size
    
    if leaf_left == 1 :
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        while 1:
            ret = client.connect_ex(parent_address)
            if ret == 0:
                break
            
        message = 'port0'
        client.sendall(message)
        portmap['port2']=client
        inputs.append(client)
            
    if leaf_right == 1 :
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        while 1:
            ret = client.connect_ex(parent_address)
            if ret == 0:
                break
            
        message = 'port1'
        client.sendall(message)
        portmap['port2']=client
        inputs.append(client)
        
    print >>sys.stderr, 'starting up on %s' % server_address
    server.bind(server_address)
    
    server.listen(5)
    
    inputs.append(server)
    outputs = [ ] 
    message_queues = {}
    
#    connection, client_address = server.accept()
#    server.setblocking(0)
#
#    print >>sys.stderr, 'new connection from ', client_address
#    type = connection.recv(8)
#        
#    if type == 'host0':
#        portmap['host0']=connection
#    elif type == 'port0':
#        portmap['port0']=connection
#    elif type == 'port1':
#        portmap['port1']=connection
#    else:
#        sys.exit(0)
#        
#    connection.setblocking(0)
#    inputs.append(connection)
#    message_queues[connection] = Queue.Queue()
#    print 'buraya'
#    
#    connection2, client_address2 = server.accept()
#
#    print >>sys.stderr, 'new connection from ', client_address2
#    type = connection2.recv(8)
#        
#    if type == 'host0':
#        portmap['host0']=connection2
#    elif type == 'port0':
#        portmap['port0']=connection2
#    elif type == 'port1':
#        portmap['port1']=connection2
#    else:
#        sys.exit(0)
        
#    connection2.setblocking(0)
#    inputs.append(connection2)
#    message_queues[connection2] = Queue.Queue()
#    print 'buraya2'
    

    if right==1:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        while 1 :
            ret= client.connect_ex(parent_address)
            if ret == 0 :
                break

        message = 'port1'
        client.sendall(message)
        portmap['port2']=client
        inputs.append(client)
    
    if left==1:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        while 1 :
            ret= client.connect_ex(parent_address)
            if ret == 0 :
                break

        message = 'port0'
        client.sendall(message)
        portmap['port2']=client
        inputs.append(client)
        
        

    print 'Starting simulation on netfpga : ',server_address
    print portmap

    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()

    
        
