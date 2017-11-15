`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indiana University, B441
// Engineer: Brandon Wynne
// 
// Create Date: 09/01/2015 05:19:24 PM
// Design Name: Lab 02
// Module Name: main
// Project Name: Lab 02
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
    input a,b,
    output myAND, myOR, myNOT
    );
    assign myAND = a & b;
    assign myOR  = a | b;
    assign myNOT =    ~a;
endmodule
