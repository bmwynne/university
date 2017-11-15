`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Brandon Wynne
// 
// Create Date: 11/11/2015 03:46:34 PM
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stack(clk, sck, mosi, miso, cs, SEG, AN);

// params
parameter READY = 8'b00000100,
          EMPTY = 8'b00001000,
          FULL  = 8'b00001001,
          PUSH  = 8'b00001010,
          POP   = 8'b00001011;
          
parameter TRUE = 8'b00000001,
          FALSE = 8'b00000010;


// inputs
input mosi, sck, cs, clk;
// outputs
output miso;
output [6:0] SEG;
output reg [3:0] AN;
// registers
reg [3:0] B;
reg [7:0] memory [0:63];
reg [15:0] buff_in, buff_out, display;
reg [25:0] seg_clk;
// wires
wire clk_wire1, clk_wire2;
// integers
integer SP = 63;
integer i;
// assignments
assign miso = buff_out[15];    
assign clk_wire1 = seg_clk[15];
assign clk_wire2 = seg_clk[14];

// initializations
seg7dec display_seg(B, SEG);

// start
always @(posedge clk)
begin
    seg_clk <= seg_clk + 1;
    if (clk_wire1 & clk_wire2)
        begin
            AN = 4'b1110;
            B = display[11:8];
        end
    else if (clk_wire1 & ~clk_wire2)
        begin
            AN = 4'b1101;
            B = display[15:12];
        end
    else if (~clk_wire1 & clk_wire2)
        begin
            AN = 4'b1011;
            B = display[3:0];
        end
    else
        begin
            AN = 4'b0111;
            B = display[7:4];
        end    
end 

always @(posedge sck)
begin
    if (~cs)
    begin
        buff_in = buff_in << 1;
        buff_in[0] = mosi;
        buff_out = buff_out << 1;
        i = i + 1;
        if (i == 24)
            i = 0;
        if (i == 16)
        begin
            buff_out[15:8] = buff_in[7:0];
            buff_out[7:0] =  buff_in[15:8];
            display[15:8] =  buff_in[15:8];
        case(buff_out[7:0])
            READY: begin
                        buff_out[15:8] = TRUE;
                        display[7:0] = TRUE;
                   end
            EMPTY: begin
                    if (SP == 63)
                    begin
                        buff_out[15:8] = TRUE;
                        display[7:0] = TRUE;                              
                    end
                    else
                    begin
                        buff_out[15:8] = FALSE;
                        display[7:0] = FALSE;
                    end
                   end
            FULL: begin
                    if (SP == 0)
                    begin
                        buff_out[15:8] = TRUE;
                        display[7:0] = TRUE;
                    end
                    else
                    begin
                        buff_out[15:8] = FALSE;
                        display[7:0] = FALSE;       
                    end
                  end
            PUSH: begin
                    memory[SP] = buff_out[15:8];    //WRITE                     
                    if (SP != 0)                     //decrement
                        SP = SP - 1;
                    buff_out[15:8] = TRUE;
                    display[7:0] = TRUE;
                  end
            POP: begin
                    if (SP != 63)
                    begin
                        SP = SP + 1;                //increment
                        buff_out[15:8] = memory[SP]; // read
                        display[7:0] = TRUE;
                    end
                    else
                    begin
                        buff_out[15:8] = FALSE;
                        display[7:0] = FALSE;
                    end                                        
                 end  
        endcase    
        end
    end
end

endmodule

module seg7dec(B, S);
input [3:0] B;
output [6:0] S;
wire m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m11, m12, m13, m14, m15;
assign m0  = ~B[3] & ~B[2] & ~B[1] & ~B[0]; 
assign m1  = ~B[3] & ~B[2] & ~B[1] &  B[0]; 
assign m2  = ~B[3] & ~B[2] &  B[1] & ~B[0]; 
assign m3  = ~B[3] & ~B[2] &  B[1] &  B[0]; 
assign m4  = ~B[3] &  B[2] & ~B[1] & ~B[0]; 
assign m5  = ~B[3] &  B[2] & ~B[1] &  B[0]; 
assign m6  = ~B[3] &  B[2] &  B[1] & ~B[0]; 
assign m7  = ~B[3] &  B[2] &  B[1] &  B[0]; 
assign m8  =  B[3] & ~B[2] & ~B[1] & ~B[0]; 
assign m9  =  B[3] & ~B[2] & ~B[1] &  B[0]; 
assign m10 =  B[3] & ~B[2] &  B[1] & ~B[0]; 
assign m11 =  B[3] & ~B[2] &  B[1] &  B[0]; 
assign m12 =  B[3] &  B[2] & ~B[1] & ~B[0]; 
assign m13 =  B[3] &  B[2] & ~B[1] &  B[0]; 
assign m14 =  B[3] &  B[2] &  B[1] & ~B[0]; 
assign m15 =  B[3] &  B[2] &  B[1] &  B[0]; 
assign S[0] = ~(m0 | m2 | m3 | m5 | m6  | m7  | m8  | m9  | m10 | m12 | m14 | m15); 
assign S[1] = ~(m0 | m1 | m2 | m3 | m4  | m7  | m8  | m9  | m10 | m13);             
assign S[2] = ~(m0 | m1 | m3 | m4 | m5  | m6  | m7  | m8  | m9  | m10 | m11 | m13);
assign S[3] = ~(m0 | m2 | m3 | m5 | m6  | m8  | m11 | m12 | m13 | m14);             
assign S[4] = ~(m0 | m2 | m6 | m8 | m10 | m11 | m12 | m13 | m14 | m15);             
assign S[5] = ~(m0 | m4 | m5 | m6 | m8  | m9  | m10 | m11 | m12 | m14 | m15);       
assign S[6] = ~(m2 | m3 | m4 | m5 | m6  | m8  | m9  | m10 | m11 | m13 | m14 | m15); 
endmodule
