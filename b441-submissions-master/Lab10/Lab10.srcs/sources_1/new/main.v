`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indiana University Bloomington
// Engineer: Brandon Wynne
// 
// Create Date: 11/03/2015 05:27:22 PM
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

//  Pin Name     |   STM Pin  |  Basys Pin
//  ---------------------------------------------------
//  SCK          |   D13/PA5  |  JA1
//  MISO         |   D12/PA6  |  JA2
//  MOSI         |   D11/PA7  |  JA3
//  CS           |   D10/PB6  |  JA4
//  GND          |   GND (any)|  GND (on JA Pin header)




module SPI_Slave(CLOCK, sck, mosi, miso, ss, an, seg);
 input mosi, sck, ss, CLOCK;
    output miso;

    output reg [3:0]an;    
    output [6:0] seg;
    wire [0:0] slct; 
    reg [15:0]buff;
    integer i;
    integer k;
    integer j;
    wire lights;
    reg [26:0] clkreg;
    wire ck = clkreg[20];
    reg m;
    reg [7:0]shifter;
    reg [7:0]sh_out;
    reg [7:0]dump;
    reg [7:0]payload;
    reg [3:0]choice;
    
    not select(slct, ss);
  
    
    bin2seg fun(choice, seg);
    assign miso = shifter[7];
    
    always @(posedge CLOCK)
    begin
        clkreg = clkreg + 1;
        if(ck)begin
                an = 4'b1101;
                choice = shifter[7:4];
            end
        else 
            begin
                an = 4'b1110;
                choice = shifter[3:0];
            end
    end

    always @(posedge sck) 
      begin
        if(slct) 
        begin
            shifter = shifter << 1;
            shifter[0] = mosi;
            i = i+1;  
         end   
       end
       
        
 endmodule
        

          
module bin2seg(B, S, AN);
      input [3:0] B;
      output [6:0] S;
      output [3:0] AN;
      wire m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m11, m12, m13, m14, m15;
     
      assign m0 = ~B[3] & ~B[2] & ~B[1] & ~B[0];
      assign m1 = ~B[3] & ~B[2] & ~B[1] & B[0];
      assign m2 = ~B[3] & ~B[2] & B[1] & ~B[0];
      assign m3 = ~B[3] & ~B[2] & B[1] & B[0];
      assign m4 = ~B[3] & B[2] & ~B[1] & ~B[0];
      assign m5 = ~B[3] & B[2] & ~B[1] & B[0];
      assign m6 = ~B[3] & B[2] & B[1] & ~B[0];
      assign m7 = ~B[3] & B[2] & B[1] & B[0];
      assign m8 = B[3] & ~B[2] & ~B[1] & ~B[0];
      assign m9 = B[3] & ~B[2] & ~B[1] & B[0];
      assign m10 = B[3] & ~B[2] & B[1] & ~B[0];
      assign m11 = B[3] & ~B[2] & B[1] & B[0];
      assign m12 = B[3] & B[2] & ~B[1] & ~B[0];
      assign m13 = B[3] & B[2] & ~B[1] & B[0];
      assign m14 = B[3] & B[2] & B[1] & ~B[0];
      assign m15 = B[3] & B[2] & B[1] & B[0];
     
      assign S[0] = ~(m0 | m2 | m3 | m5 | m6 | m7 | m8 | m9 | m10 | m12 | m14 | m15);// A
      assign S[1] = ~(m0 | m1 | m2 | m3 | m4 | m7 | m8 | m9 | m10 | m13); // B
      assign S[2] = ~(m0 | m1 | m3 | m4 | m5 | m6 | m7 | m8 | m9 | m10 | m11 | m13);// C
      assign S[3] = ~(m0 | m2 | m3 | m5 | m6 | m8 | m11| m12| m13 | m14); // D
      assign S[4] = ~(m0 | m2 | m6 | m8 | m10 | m11 | m12| m13| m14 | m15); // E
      assign S[5] = ~(m0 | m4 | m5 | m6 | m8 | m9 | m10| m11| m12 | m14 | m15); // F
      assign S[6] = ~(m2 | m3 | m4 | m5 | m6 | m8 | m9 | m10| m11 | m13 | m14 | m15);// G
      assign AN = 4'b1110;
     
 endmodule