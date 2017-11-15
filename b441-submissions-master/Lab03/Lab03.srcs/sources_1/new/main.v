`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2015 04:42:37 PM
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


module main(
    input a, b, c, s1, s0, d,
    output d0, d1, d2, d3, d4, d5, d6, d7, y0, y1, y2, y3
    ); 
    assign d0 = ~a & ~b & ~c;
    assign d1 = ~a & ~b &  c;
    assign d2 = ~a &  b & ~c;
    assign d3 = ~a &  b &  c;
    assign d4 =  a & ~b & ~c;
    assign d5 =  a & ~b &  c;
    assign d6 =  a &  b & ~c;
    assign d7 =  a &  b &  c;
    
    assign y0 = ~s1 & ~s0 &  d;
    assign y1 = ~s1 &  s0 &  d;
    assign y2 =  s1 & ~s0 &  d;
    assign y3 =  s1 &  s0 &  d;
    
endmodule
