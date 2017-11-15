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

def stream(clk, datain, dataout, ctrlin, ctrlout):
    os.system("python stream.py")
    cmd = "iverilog -o stream stream.v tb_stream.v" 
    os.system(cmd)
    return Cosimulation("vvp -m ./myhdl.vpi stream", clk=clk,
                        datain=datain , dataout=dataout, ctrlin=ctrlin, ctrlout=ctrlout) 

def testbench():
    global packet
    Half_Period = delay (10)
    datain_list = [Signal(intbv(0)[8:]) for i in range(8)]                              
    datain = ConcatSignal(*reversed(datain_list))
    dataout = Signal(intbv(0)[64:])
    ctrlin = Signal(intbv(0)[8:])
    ctrlout = Signal(intbv(0)[8:])
    
    clk = Signal(bool(0))
    
    @always(Half_Period) 
    def clockGen():
        clk.next = not clk
        
    @instance
    def stimulus():
        initial = 0
        p = pcap.pcapObject()
        p.open_live('en2', 1600, 0, 100)
        while 1:
            p.dispatch(1, get_packet)
            sys.stdout.write("Please hit a key to process captured packet (hit CTRL-D to halt the simulation): ")
            next = sys.stdin.read(1)
            if not next:
                raise StopSimulation
            for i in range(len(packet)) :
                if i%8 == 0 :
                    ctrlin.next=0
                    for j in range(8) :
                        if len(packet)>(i+j) :
                            datain_list[j].next=ord(packet[i+j])
                            if (datain_list[j].next > 96) and (datain_list[j].next < 123) :
                                ctrlin.next = ctrlin.next+1
                        else :
                            datain_list[j].next=0xff
                            ctrlin.next = 0xff
                    yield clk.negedge

    @instance
    def monitor():
        while 1:
            yield clk.posedge
            yield delay (1) 
#            sys.stdout.write(chr(dataout[8:0]))

    up = stream(clk, datain, dataout, ctrlin, ctrlout) 
    return clockGen , stimulus , up , monitor

if __name__=='__main__':
    tb = traceSignals(testbench) 
    sim = Simulation(tb) 
    sim.run()
