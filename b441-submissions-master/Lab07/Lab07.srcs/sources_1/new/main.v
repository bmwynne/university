`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Indiana University B441
// Engineer: Brandon Wynne 
// 
// Create Date: 10/06/2015 07:02:23 PM
// Design Name: ALU
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
module main();
endmodule

module Mux_2_1(y, s, f0, f1);
    input f0, f1, s;
    output y;
    wire not_s;
    wire [1:0] w;
    
    not INV_1(not_s, s);
    and AND_1(w[0], f0, not_s);
    and AND_2(w[1], f1, s);
    or or_1(y, w[0] , w[1]);
    
    endmodule
    
module Mux_4_1(op1, op2, op3, op4, f0, f1, s);
    input op1, op2, op3, op4, f0, f1;
    output s;
    wire [5:0] w;
    not INV_1(w[0], f0);
    not INV_2(w[1], f1);
    and AND_1(w[2], w[0], w[1], op1);
    and AND_2(w[3], w[1], f0, op2);
    and AND_3(w[4], w[0], f1, op3);
    and AND_4(w[5], f0, f1, op4);
    or OR_1(s, w[2], w[3], w[4], w[5]);
    
    endmodule
    
module FullAdd(a, b, c_in, c_out, s); 
    input  a, b, c_in;
    output c_out, s;  
    wire w1, w2, w3;
    xor XOR_1(w1,   b, c_in);
    xor XOR_2(c_out, w1,   a);
    and AND_1(w3,   b, c_in);  
    and AND_2(w2,   a, b);
    or  OR_1(s, w2,   w3);
    
    endmodule

module FullSub(a, b, c_in, c_out, d);
    input a, b, c_in;
    output c_out, d; 
    wire not_a, not_xor, w1, w2, w3;
    not INV_1(not_a, a);
    xor XOR_1(w1, a, b);
    xor XOR_2(d, c_in, w1);
    not INV_2(not_xor, w1);
    and AND_1(w2, not_a, b);
    and AND_2(w3, not_xor, c_in);
    or OR_1(c_out, w2, w3);
    
    endmodule
    
module Decrement_a(a, c_in, c_out, dec);
    input a, c_in;
    output c_out, dec;
    wire w1;
    xor XOR_1(dec, a, c_in);
    xor XOR_2(w1, a, dec);
    and AND_1(c_out, w1, c_in);
    
    endmodule

module Transfer_a(a, f0, f1, tx_a);
    input a, f0, f1;
    output tx_a;
    and AND_1(tx_a, a, f0, f1);
    
    endmodule
       
module AU_4Bit(a, b, c_in, f0, f1, c_out, y);
    input [3:0] a;
    input [1:0] b;
    input c_in, f0, f1;
    wire [4:0] w;
    output c_out, y;
    
    FullAdd     add(a[0], b[0], c_in, c_out, w[0]);
    FullSub     sub(a[1], b[1], c_in, c_out, w[1]);
    Decrement_a dec(a[2], c_in, c_out, w[2]);
    Transfer_a tx_a(a[3], f0, f1, w[3]);
    Mux_4_1     mux(w[0], w[1], w[2], w[3], f0, f1, y);
    
    endmodule
    
module LU_4Bit(a, b, f0, f1, y);
    input [3:0] a;
    input [2:0] b;
    input f0, f1;
    output y;
    wire   [3:0] w;
    
    and AND_1(w[0], a[0], b[0]);
    or   OR_1(w[1], a[1], b[1]);
    xor XOR_1(w[2], a[2], b[2]);
    not NOT_1(w[3], a[3]);
    Mux_4_1 mux(w[0], w[1], w[2], w[3], f0, f1, y);
    
    endmodule
    
module ALU_4Bit(a, b, c_in, f0, f1, f2, c_out, y);
    
    input [1:0] a, b;
    input c_in, f0, f1, f2;
    output c_out, y;
    wire [2:0] w;
    
    AU_4Bit a_unit(a[0], b[0], c_in, f0, f1, c_out, w[1]);
    LU_4Bit l_unit(a[1], b[1], f0, f1, w[2]);
    Mux_2_1 mux(y, f2, w[1], w[2]);

    endmodule


// THE FOLLOWING COMMENTED CODE IS NOT WORKING

//module AU_4bit(a, b, c_in, f0, f1, c_out, y);
//   input [3:0] a;
//   input [1:0] b;
//   input c_in, f0, f1;
//   output c_out, y;
//   wire [3:0] w;
//   wire not_f0, not_f1, w1, w2, w3, w4;
//   fulladd add(a[0:0], b[0:0], c_in, c_out, w[0:0]);
//   fullsub sub(a[1:0], b[1:0], c_in, c_out, w[1:0]);
//   decrement_a dec(a[2:0], c_in, c_out, w[2:0]);
//   transfer_a tx(a[3:0], f0, f1, w[3:0]);  
//    not INV_1(not_f0, f0);
//    not INV_2(not_f1, f1);
//    and AND_1(w1, w[0:0], not_f0, not_f1);
//    and AND_2(w2, w[1:0], not_f0, f1);
//    and AND_3(w3, w[2:0]. f0, not_f1);
//    and AND_4(w4, w[3:0], f0, f1);
//    or OR_1(y, w1, w2, w3, w4);  
//    endmodule

//module LU_4bit(a, b, f0, f1, y);
//   input [3:0] a;
//   input [2:0] b;
//   input f0, f1;
//   output y;
//   wire [3:0] w;
//   wire not_f0, not_f1, w1, w2, w3, w4, w5, w6, w7, w8;  
//   not INV_1(not_f0, f0);
//   not INV_2(not_f1, f1);
//   and AND_1(w1, a[0:0], b[0:0]);
//   or  OR_1(w2, a[1:0], b[1:0]);
//   xor XOR_1(w3, a[2:0], b[2:0]);
//   not NOT_1(w4, a[3:0]);
//   and AND_2(w5, w1, not_f0, not_f1);
//   and AND_3(w6, w2, f0, not_f1);
//   and AND_4(w7, w3, not_f0, f1);
//   and AND_5(w8, w4, f0, f1);
//   or OR_2(y, w5, w6, w7, w8);  
//   endmodule

//module ALU_4bit(a, b, c_in, f0, f1, f2, c_out, y);
//   // 4 a 3b - LU
//   // 4 a 2b - AU
//   // == 8 a, 5b
//   input [7:0] a;
//   input [4:0] b;
//   input       c_in, f2;
//   input [1:0] f0, f1;
//   output      c_out;
//   wire [2:0]  y;
//   AU_4bit arith_unit(a, b, c_in, f0, f1, c_out, y[0:0]);
//   LU_4bit logic_unit(a, b, f0, f1, y[1:0]);
//   or OR_1(y[2:0], y[0:0], y[1:0]);
//   endmodule
