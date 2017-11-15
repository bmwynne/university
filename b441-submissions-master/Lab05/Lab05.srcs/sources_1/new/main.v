`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2015 04:21:31 PM
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

// MAIN
module main(
    input S0, S1, D0, D1, D2, D3, S2, S3, IN1, IN2, IN3, IN4,
    output Q
    );
    //Mux_4_1 Mux_1(S0, S1, D0, D1, D2, D3, Y);
    LightSW_4 LSW(IN1, IN2, IN3, IN4, Q);
    
endmodule

// 4 To 1 Multiplex
module Mux_4_1(s0, s1, d0, d1, d2, d3, y);
    input s0, s1, d0, d1, d2, d3;
    output y;
    
    wire w1, w2, w3, w4, w5, w6;
    
    not Inv_0(w1, s0);
    not Inv_1(w2, s1);
    
    and And_0(w3, w1,  w2,  d0);
    and And_1(w4, w2,  s0,  d1);
    and And_2(w5, w1,  s1,  d2);
    and And_3(w6, s0,  s1,  d3);
    or  OR_1(y, w3, w4, w5, w6);
     
endmodule

// 4 Input Light Switch
module LightSW_4(in1, in2, in3, in4, q);
    input in1, in2, in3, in4;
    output q;
    xor XOR_1(q, in1, in2, in3, in4);
endmodule
