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
server_address = '../netfpga1'
next_address = '../netfpga2'
connection=''
client_address=''
inputs = ''
outputs = ''
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
    Half_Period = delay (10)

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
                
            readable, writable, exceptional = select.select(inputs, outputs, inputs, timeout)
            if not (readable):
                print >>sys.stderr, '  timed out, do some other work here'
                yield clk.negedge
            else:
                for s in readable:
                    if s is server:
                        # A "readable" server socket is ready to accept a connection                                             
                        connection, client_address = s.accept()
                        print >>sys.stderr, 'new connection from host 0', client_address
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
                            portmap[key]=connection
                        else:
                            key = 'dummy'+str(dq)
                            dq=dq+1
                            portmap[key]=connection
                        print 'key : ', key
                        connection.sendall(key)
                        connection.setblocking(0)
                        inputs.append(connection)
                        # Give the connection a queue for data we want to send 
                        message_queues[connection] = Queue.Queue()
                        yield clk.negedge
                    else:
                        data = s.recv(1024)
                        if data:
                            print '******* ',len(data), ' ',data
                            host_loc=data.find('host')
                            net_loc=data.find('net')

                            if host_loc > -1 :
                                print 'packet is from host'
                                if reset:
                                    reset.next = not reset

                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                reg_req_in.next=0
                                reg_ack_in.next=0
                                reg_rd_wr_L_in.next=0
                                reg_addr_in.next=0
                                reg_data_in.next=0
                                reg_src_in.next=0
                                
                                in_data_list[0].next=len(data)                                                       
                                in_data_list[1].next=0
                                in_data_list[2].next=int(data[host_loc+4])*2+1
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
                                        reg_req_in.next=0
                                        reg_ack_in.next=0
                                        reg_rd_wr_L_in.next=0
                                        reg_addr_in.next=0
                                        reg_data_in.next=0
                                        reg_src_in.next=0
                                        #sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                #byte = ord(data[i+j])
                                                #sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[j].next=0
                                                in_ctrl.next = 0x10
                                        #sys.stdout.write('\n')
                                        yield clk.negedge
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                reg_req_in.next=0
                                reg_ack_in.next=0
                                reg_rd_wr_L_in.next=0
                                reg_addr_in.next=0
                                reg_data_in.next=0
                                reg_src_in.next=0

                                in_data_list[0].next=0
                                in_data_list[1].next=0
                                in_data_list[2].next=0
                                in_data_list[3].next=0
                                in_data_list[4].next=0
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
                                yield clk.negedge
                            elif net_loc > -1 :
                                print 'packet is from net'
                                if reset:
                                    reset.next = not reset
                                in_wr.next=1
                                out_rdy.next=1
                                in_ctrl.next=0xff
                                reg_req_in.next=0
                                reg_ack_in.next=0
                                reg_rd_wr_L_in.next=0
                                reg_addr_in.next=0
                                reg_data_in.next=0
                                reg_src_in.next=0
        
                                in_data_list[0].next=len(data)
                                in_data_list[1].next=0
                                in_data_list[2].next=int(data[net_loc+3])*2
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
                                        reg_req_in.next=0
                                        reg_ack_in.next=0
                                        reg_rd_wr_L_in.next=0
                                        reg_addr_in.next=0
                                        reg_data_in.next=0
                                        reg_src_in.next=0
                                        sys.stdout.write('Sent : ')
                                        for j in range(8) :
                                            if len(data)>(i+j) :
                                                in_data_list[j].next=ord(data[i+j])
                                                if i+j+1 == len(data):
                                                    in_ctrl.next = 0x10
                                                byte = ord(data[i+j])
                                                sys.stdout.write("%s " % byte)
                                            else :
                                                in_data_list[j].next=0
                                                in_ctrl.next = 0x10
                                        sys.stdout.write('\n')
                                        yield clk.negedge
                                
                                in_wr.next=0
                                out_rdy.next=1
                                in_ctrl.next=0
                                reg_req_in.next=0
                                reg_ack_in.next=0
                                reg_rd_wr_L_in.next=0
                                reg_addr_in.next=0
                                reg_data_in.next=0
                                reg_src_in.next=0

                                in_data_list[0].next=0
                                in_data_list[1].next=0
                                in_data_list[2].next=0
                                in_data_list[3].next=0
                                in_data_list[4].next=0
                                in_data_list[5].next=0
                                in_data_list[6].next=0
                                in_data_list[7].next=0
                                yield clk.negedge
                        else:
                            if s in outputs:
                                outputs.remove(s)
                            inputs.remove(s)
                            s.close()
                            del message_queues[s]
                            raise StopSimulation                            

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
            yield delay (1)            
        
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
                if out_encoded != 0:
                    if out_encoded & 1 != 0 : 
                        port = portmap['client']
                        if pkt.find('host0') > -1:
                            pkt2 = string.replace(pkt,'host0','net0')
                            print 'Sending : ',pkt2
                            port.sendall(pkt2)
                        else:
                            print 'Sending : ',pkt
                            port.sendall(pkt)
                            
                    if out_encoded & 2 != 0 :
                        port = portmap['host0']
                        #if pkt.find('host0') > -1:
                        port.sendall('released')

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
    try:
        os.unlink(server_address)
    except OSError:
        if os.path.exists(server_address):
            raise

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    if len(sys.argv) > 1:
        if sys.argv[1] == 'head' :
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

            while 1 :
                ret = client.connect_ex(next_address)
                if ret == 0 :
                    break
            
            message = 'net'
            client.sendall(message)
            key = client.recv(16)
            portmap['client']=client

    print >>sys.stderr, 'starting up on %s' % server_address
    server.bind(server_address)
    
    server.listen(5)
    
    inputs = [ server ]
    outputs = [ ] 
    message_queues = {}
    
    connection, client_address = server.accept()
    server.setblocking(0)

    print >>sys.stderr, 'new connection from ', client_address
    type = connection.recv(8)
    key=''
    if type == 'host':
        key = 'host'+str(hq)
        hq=hq+1
        portmap[key]=connection
    elif type == 'net':
        key = 'net'+str(nq)
        nq=nq+1
        portmap[key]=connection
    else:
        key = 'dummy'+str(dq)
        dq=dq+1
        portmap[key]=connection
    connection.sendall(key)
    connection.setblocking(0)
    inputs.append(connection)
    message_queues[connection] = Queue.Queue()

    if len(sys.argv) == 1 :
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        while 1 :
            ret= client.connect_ex(next_address)
            if ret == 0 :
                break

        message = 'net'
        client.sendall(message)
        key = client.recv(16)
        portmap['client']=client

    print 'Starting simulation on netfpga : ',server_address

    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()

    
        
