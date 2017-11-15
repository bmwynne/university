`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2015 04:08:42 PM
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

module PF_Processor(clk, sck, mosi, miso, cs, seg, an);

// Inputs
input clk, sck, mosi, cs;
// Outputs
output miso;
output [6:0] seg;
output reg [3:0] an;
// Registers
reg [3:0] b;
reg [7:0] stack_mem [0:64];
reg [15:0] buff_in, buff_out, display;
reg [25:0] seg_clk;
// Wires
wire clk_wire1, clk_wire2;
// Integers
integer SP = 63;
integer i;
// Assignments
assign miso      = buff_out[15];
assign clk_wire1 = seg_clk[15];
assign clk_wure2 = seg_clk[14];
// Parameters
parameter READY = 8'b00000100,
          EMPTY = 8'b00001000,
          FULL  = 8'b00001001,
          PUSH  = 8'b00001010,
          POP   = 8'b00001011,
          PEEK  = 8'b00001100,
          AND   = 8'b00010000,
          OR    = 8'b00010001,
          NOT   = 8'b00010010,
          XOR   = 8'b00010011,
          ADD   = 8'b00100000,
          SUB   = 8'b00100001,
          INC   = 8'b00100010,
          MULT  = 8'b00100011,
          MOD   = 8'b00100100;
          
parameter TRUE  = 8'b00000001,
          FALSE = 8'b00000010;

seg7dec display_seg(b, seg);

// Segment Display
always @ (posedge clk)
    begin
        seg_clk <= seg_clk + 1;
        if (clk_wire1 & clk_wire2)
            begin
                an = 4'b1101;
                b  = display[11:8];
            end
        else if (clk_wire1 & ~clk_wire2)
            begin
                an = 4'b1101;
                b  = display[15:12];
            end
        else if (~clk_wire1 & clk_wire2)
            begin
                an = 4'b1011;
                b = display[3:0];
            end
        else
            begin
                an = 4'b0111;
                b  = display[7:4];
            end
end

// STM Commands
always @ (posedge sck)
    begin
        if (~cs)
            begin
                buff_in    = buff_in << 1;
                buff_in[0] = mosi;
                buff_out   = buff_out << 1;
                i = i + 1;
                if (i == 24)
                    i = 0;
                if (i == 16)
                begin
                    buff_out[15:8] = buff_in[7:0];
                    buff_out[7:0]  = buff_in[15:8];
                    display[15:8]  = buff_in[15:8];
                    
                    case (buff_out[7:0])
                        READY: begin
                                    buff_out[15:8] = TRUE;
                                    display[7:0]   = TRUE;
                               end
                        EMPTY: begin
                                    if (SP == 63)
                                    begin
                                        buff_out[15:8] = TRUE;
                                        display[7:0]   = TRUE;
                                    end
                                    else
                                        begin
                                            buff_out[15:8] = FALSE;
                                            display[7:0]   = FALSE;
                                        end
                                end
                         FULL: begin
                                    if (SP == -1)
                                    begin
                                        buff_out[15:8] = TRUE;
                                        display[7:0]   = TRUE;
                                    end
                                    else
                                        begin
                                        buff_out[15:8] = FALSE;
                                        display[7:0]   = FALSE;
                                        end
                                end
                          PUSH: begin
                                    if (SP != -1)
                                    begin
                                        stack_mem[SP] = buff_out[15:8];
                                        buff_out[15:8]= TRUE;
                                        display[7:0]  = TRUE;
                                        SP = SP - 1;
                                        end
                                     else
                                        begin
                                            stack_mem[0]   = buff_out[15:8];
                                            buff_out[15:8] = FALSE;
                                            display[7:0]   = FALSE;
                                         end
                                 end
                           POP: begin
                                    if (SP != 63)
                                    begin
                                        buff_out[15:8] = stack_mem[SP + 1];
                                        display[7:0]   = stack_mem[SP + 1];
                                    end
                                    else
                                    begin
                                        buff_out[15:8] = stack_mem[SP];
                                        display[7:0]   = stack_mem[SP];
                                    end
                                end
                           AND: begin
                                    if (SP < 62)
                                    begin
                                        stack_mem[SP + 2] = stack_mem[SP + 1] & stack_mem[SP + 2];
                                        buff_out[15:8]    = stack_mem[SP + 2];
                                        display[7:0]      = stack_mem[SP + 2];
                                        SP = SP + 1;
                                    end
                                    else if (SP == -1)
                                    begin
                                        stack_mem[1]  = stack_mem[0] & stack_mem[1];
                                        buff_out[15:8]= stack_mem[1];
                                        display[7:0]  = stack_mem[1];
                                        SP = 0;
                                    end
                                    else
                                    begin
                                        stack_mem[63] = stack_mem[63] & stack_mem[63];
                                        buff_out[15:8]= stack_mem[63];
                                        display[7:0]  = stack_mem[63];
                                        SP = 62;
                                    end
                                 end
                             OR: begin
                                    if (SP < 62)
                                    begin
                                        stack_mem[SP + 2] = stack_mem[SP + 1] | stack_mem[SP + 2];
                                        buff_out[15:8]    = stack_mem[SP + 2];
                                        display[7:0]      = stack_mem[SP + 2];
                                        SP = SP + 1;
                                    end
                                    else if (SP == -1)
                                    begin
                                        stack_mem[1]   = stack_mem[0] | stack_mem[1];
                                        buff_out[15:8] = stack_mem[1];
                                        display[7:0]   = stack_mem[1];
                                        SP = 0;
                                    end
                                    else
                                    begin
                                        stack_mem[63] = stack_mem[63] | stack_mem[63];
                                        buff_out[15:8]= stack_mem[63];
                                        display[7:0]  = stack_mem[63];
                                        SP = 62;
                                    end
                                    end    
                                                   
                                NOT: begin
                                     if (SP != 63)
                                     begin
                                       stack_mem[SP + 1] = ~stack_mem[SP + 1];
                                       buff_out[15:8]    = stack_mem[SP + 1];
                                       display[7:0]      = stack_mem[SP + 1];
                                     end
                                     else if (SP == -1)
                                     begin
                                        stack_mem[0]   = ~stack_mem[0];
                                        buff_out[15:8] = stack_mem[0];
                                        display[7:0]   = stack_mem[0];
                                     end
                                     else
                                     begin
                                        stack_mem[63] = ~stack_mem[63];
                                        buff_out[15:8]= stack_mem[63];
                                        display[7:0]  = stack_mem[63];
                                        SP = 62;
                                     end
                                     end
                                XOR: begin
                                     if (SP < 62)
                                     begin
                                        stack_mem[SP + 2] = stack_mem[SP + 1] ^ stack_mem[SP + 2];
                                        buff_out[15:8] = stack_mem[SP + 2];
                                        display[7:0] = stack_mem[SP + 2];
                                        SP = SP + 1;
                                     end
                                     else if (SP == -1)
                                     begin
                                        stack_mem[1] = stack_mem[0] ^ stack_mem[1];
                                        buff_out[15:8] = stack_mem[1];
                                        display[7:0] = stack_mem[1];
                                        SP = 0;
                                     end
                                     else
                                     begin
                                        stack_mem[63] = stack_mem[63] ^ stack_mem[63];
                                        buff_out[15:8] = stack_mem[63];
                                        display[7:0] = stack_mem[63];
                                        SP = 62;
                                     end
                                     end
                                ADD: begin
                                      if (SP < 62)
                                      begin
                                      stack_mem[SP + 2] = stack_mem[SP + 1] + stack_mem[SP + 2];
                                      buff_out[15:8] = stack_mem[SP + 2];
                                      display[7:0] = stack_mem[SP + 2];
                                      SP = SP + 1;
                                      end
                                      else if (SP == -1)
                                      begin
                                        stack_mem[1] = stack_mem[0] + stack_mem[1];
                                        buff_out[15:8] = stack_mem[1];
                                        display[7:0] = stack_mem[1];
                                        SP = 0;
                                      end
                                      else
                                      begin
                                        stack_mem[63] = stack_mem[63] + stack_mem[63];
                                        buff_out[15:8] = stack_mem[63];
                                        display[7:0] = stack_mem[63];
                                        SP = 62;
                                      end
                                   end
                                SUB: begin
                                     if (SP < 62)
                                        begin
                                        stack_mem[SP + 2] = stack_mem[SP + 1] - stack_mem[SP + 2];
                                        buff_out[15:8] = stack_mem[SP + 2];
                                        display[7:0] = stack_mem[SP + 2];
                                        SP = SP + 1;
                                   
                                     end
                                     else if (SP == -1)
                                     begin
                                     stack_mem[1] = stack_mem[0] - stack_mem[1];
                                     buff_out[15:8] = stack_mem[1];
                                     display[7:0] = stack_mem[1];
                                     end
                                     else
                                     begin
                                     stack_mem[63] = stack_mem[63] - stack_mem[63];
                                     buff_out[15:8] = stack_mem[63];
                                     display[7:0] = stack_mem[63];
                                     SP = SP + 1;
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
 assign S[0] = ~(m0 | m2 | m3 | m5 | m6  | m7  | m8  | m9  | m10 | m12 | m14 | m15); //A
 assign S[1] = ~(m0 | m1 | m2 | m3 | m4  | m7  | m8  | m9  | m10 | m13);             //B
 assign S[2] = ~(m0 | m1 | m3 | m4 | m5  | m6  | m7  | m8  | m9  | m10 | m11 | m13); //C
 assign S[3] = ~(m0 | m2 | m3 | m5 | m6  | m8  | m11 | m12 | m13 | m14);             //D
 assign S[4] = ~(m0 | m2 | m6 | m8 | m10 | m11 | m12 | m13 | m14 | m15);             //E
 assign S[5] = ~(m0 | m4 | m5 | m6 | m8  | m9  | m10 | m11 | m12 | m14 | m15);       //F
 assign S[6] = ~(m2 | m3 | m4 | m5 | m6  | m8  | m9  | m10 | m11 | m13 | m14 | m15); //G
 endmodule
                                 
                                        
                                        
                     
        
