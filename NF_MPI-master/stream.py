from myhdl import *
import sys

def stream(clk, datain, dataout, ctrlin, ctrlout):

    @always(clk.posedge)
    def upcase():
        dataout.next = datain
        counter = 0
    
        if (datain[8:0] > 96) and (datain[8:0] < 123) :
            dataout.next[8:0] = datain[8:0] - 32
            counter=counter+1

        if (datain[16:8] > 96) and (datain[16:8] < 123) :
            dataout.next[16:8] = datain[16:8] - 32
            counter=counter+1
        
        if (datain[24:16] > 96) and (datain[24:16] < 123) :
            dataout.next[24:16] = datain[24:16] - 32
            counter=counter+1
        
        if (datain[32:24] > 96) and (datain[32:24] < 123) :
            dataout.next[32:24] = datain[32:24] - 32
            counter=counter+1

        if (datain[40:32] > 96) and (datain[40:32] < 123) :
            dataout.next[40:32] = datain[40:32] - 32
            counter=counter+1

        if (datain[48:40] > 96) and (datain[48:40] < 123) :
            dataout.next[48:40] = datain[48:40] - 32
            counter=counter+1

        if (datain[56:48] > 96) and (datain[56:48] < 123) :
            dataout.next[56:48] = datain[56:48] - 32
            counter=counter+1

        if (datain[64:56] > 96) and (datain[64:56] < 123) :
            dataout.next[64:56] = datain[64:56] - 32
            counter=counter+1
            
        if counter == 0:
            ctrlout.next[8:0] = 254
        elif ctrlin == counter :
            ctrlout.next[8:0] = 8 - counter
        else :
            ctrlout.next[8:0] = 255

    return upcase

if __name__ == "__main__" :
    datain = Signal(intbv(0)[64:]) 
    dataout = Signal(intbv(0)[64:])
    ctrlin = Signal(intbv(0)[8:])
    ctrlout = Signal(intbv(0)[8:])
    clk = Signal(bool(0))    
    tmp = toVerilog(stream, clk, datain, dataout, ctrlin, ctrlout)
