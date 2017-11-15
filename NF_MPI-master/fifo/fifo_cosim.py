import os
import sys
from myhdl import *
import pcap

packet=''

def get_packet(pktlen, data, timestamp):
    global packet
    if not data:
        return
    packet=data

def fallthrough_small_fifo(din, wr_en, rd_en, dout, full, nearly_full, empty, clk, reset):
    cmd = "iverilog -o fallthrough_small_fifo -Dwidth=72 -Ddept=2 fallthrough_small_fifo.v tb_fallthrough_small_fifo.v"
    os.system(cmd)
    return Cosimulation("vvp -m ./myhdl.vpi fallthrough_small_fifo", 
                        din=din, wr_en=wr_en, rd_en=rd_en, dout=dout, full=full, 
                        nearly_full=nearly_full, empty=empty, clk=clk, reset=reset)

def testbench():
    global packet
    Half_Period = delay (10)

    dout = Signal(intbv(0)[72:]) 
    wr_en = Signal(bool(1))
    rd_en = Signal(bool(0))

    in_data_list = [Signal(intbv(0)[8:]) for i in range(9)]            
    din = ConcatSignal(*reversed(in_data_list))
    full = Signal(bool(0))
    nearly_full = Signal(bool(0))
    empty = Signal(bool(0))
    
    clk = Signal(bool(0))
    reset = Signal(bool(1))

    @always(Half_Period) 
    def clockGen():
        clk.next = not clk
#        delay(1)
#        if reset:
#            reset.next = not reset
        

        
    @instance
    def stimulus():
        initial = 0
        p = pcap.pcapObject()
#        p.open_live('en2', 1600, 0, 100)
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
                    rd_en.next=not rd_en
                    wr_en.next=not wr_en
                    
                    for j in range(8) :
                        if len(packet)>(i+j) :
                            in_data_list[j].next=ord(packet[i+j])
                        else :
                            in_data_list[j].next=0
                        if j == 7:
                            in_data_list[8].next=0x0;

                    yield clk.negedge

    @instance
    def monitor():
        while 1:
            yield clk.posedge
            yield delay (1) 
            if empty:
                print "empty"
            else:
                print "not empty"
            
#            sys.stdout.write(chr(dataout[8:0]))

    up = fallthrough_small_fifo(din, wr_en, rd_en, dout, full, nearly_full, empty, clk, reset)
    return clockGen , stimulus , up , monitor

if __name__=='__main__':
    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()
