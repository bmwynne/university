import os
import sys
from myhdl import *
import pcap

packet=''
pid = -1

def get_packet(pktlen, data, timestamp):
    global packet
    if not data:
        return
    packet=data

def chain(out_data, out_ctrl, out_wr, out_rdy, 
           in_data, in_ctrl, in_wr, in_rdy,
           reg_req_in, reg_ack_in, reg_rd_wr_L_in, reg_addr_in, reg_data_in, reg_src_in,
           reg_req_out, reg_ack_out, reg_rd_wr_L_out, reg_addr_out, reg_data_out, reg_src_out,
           clk, reset):
    cmd = "iverilog -o chain -c chain.txt" 
    os.system(cmd)
    return Cosimulation("vvp -m ./myhdl.vpi chain", 
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

#    datain_list = [Signal(intbv(0)[8:]) for i in range(8)]                              
#    datain = ConcatSignal(*reversed(datain_list))
#    dataout = Signal(intbv(0)[64:])
#    ctrlin = Signal(intbv(0)[8:])
#    ctrlout = Signal(intbv(0)[8:])
    
    clk = Signal(bool(0))
    reset = Signal(bool(1))

    @always(Half_Period) 
    def clockGen():
        clk.next = not clk
#        reset.next = not reset
        
    @instance
    def stimulus():
        initial = 0
        p = pcap.pcapObject()
        p.open_offline("omer.dump")
        while 1:
            p.dispatch(1, get_packet)
            sys.stdout.write("Please hit a key to process captured packet (hit CTRL-D to halt the simulation): ")
            next = sys.stdin.read(1)
            reset.next=1
            yield clk.negedge
            if not next:
                raise StopSimulation
            for i in range(len(packet)) :
                if reset:
                    reset.next = not reset

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
                    for j in range(8) :
                        if len(packet)>(i+j) :
                            in_data_list[j].next=ord(packet[i+j])
                        else :
                            in_data_list[j].next=0
                            in_ctrl.next = 0x10
                    yield clk.negedge

    @instance
    def monitor():
        while 1:
            yield clk.posedge
            yield delay (1) 
            for i in range(0,8):
                sys.stdout.write(chr(out_data[8+i:i]))
                
            sys.stdout.write("\n")

    up = chain(out_data, out_ctrl, out_wr, out_rdy,
                in_data, in_ctrl, in_wr, in_rdy,
                reg_req_in, reg_ack_in, reg_rd_wr_L_in, reg_addr_in, reg_data_in, reg_src_in,
                reg_req_out, reg_ack_out, reg_rd_wr_L_out, reg_addr_out, reg_data_out, reg_src_out,
                clk, reset)

    return clockGen , stimulus , up , monitor

if __name__=='__main__':
#    pid = os.fork() 
#    if(pid == 0):
#        print "Child Process"
#    else:
#        print "Parent Process"

#    print os.getpid(), pid

    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()
