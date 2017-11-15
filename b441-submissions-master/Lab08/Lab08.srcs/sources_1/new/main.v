`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2015 03:06:15 PM
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

    );
endmodule

module MS_D_FF(d, clk, rst, q, not_q);
input d, clk, rst;
output q, not_q;

wire not_d, not_clk;
wire [7:0] w;
not INV_0(not_d, d);
not INV_1(not_clk, clk);
and AND_0(w[0], d, clk);
and AND_1(w[1], not_d, clk);
and AND_2(w[2], w[0], w[3]);
and AND_3(w[3], w[1], w[2]);
and AND_4(w[4], w[2], not_clk);
and AND_5(w[5], w[3], not_clk);
nand NAND_0(w[6], w[4], w[7]);
nand NAND_1(w[7], w[5], w[6], rst);

endmodule

module Four_Bit_Reg(d, clk, rst, q, not_q);

input [3:0] d, rst;
input clk;
wire [3:0] not_clk;
not INV_0(not_clk, clk);
output [3:0] q, not_q;

MS_D_FF d_ff0(d[0], not_clk, rst[0], q[0], not_q[0]);
MS_D_FF d_ff1(q[0], not_clk, rst[1], q[1], not_q[1]);
MS_D_FF d_ff2(q[1], not_clk, rst[2], q[2], not_q[2]);
MS_D FF d_ff3(q[

endmodule
