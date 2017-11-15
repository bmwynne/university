import os
import sys
import time
from myhdl import *
import pcap
import socket

packet=''
server_address = '../uds_socket'
connection=''
client_address=''

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
        while 1:
            byte = connection.recv(1)
            if ord(byte) > 0:
                reset.next = 1
            else:
                reset.next = 0
            
            byte = connection.recv(1)
            in_ctrl.next = ord(byte)
            byte = ord(byte)
            sys.stdout.write("%s " % byte)

            for i in range(8):
                byte = connection.recv(1)
                in_data_list[i].next = ord(byte)
                byte = ord(byte)
                sys.stdout.write("%s " % byte)

            sys.stdout.write('\n')

            in_wr.next=1
            out_rdy.next=1
            reg_req_in.next=0
            reg_ack_in.next=0
            reg_rd_wr_L_in.next=0
            reg_addr_in.next=0
            reg_data_in.next=0
            reg_src_in.next=0
            yield clk.negedge

    @instance
    def monitor():
        while 1:
            yield clk.posedge
            yield delay (1) 

#            for i in range(0,8):
#                j = ord(chr(out_data[8*(1+i):8*i]))
#                sys.stdout.write("%s " % j)
#            sys.stdout.write("\n")


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

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    print >>sys.stderr, 'starting up on %s' % server_address
    sock.bind(server_address)

    sock.listen(1)

    # Wait for a connection                                                                                                          
    print >>sys.stderr, 'waiting for a connection'
    connection, client_address = sock.accept()

    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()

