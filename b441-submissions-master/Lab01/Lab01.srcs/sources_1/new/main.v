`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indiana University, B441
// Engineer: Brandon Wynne
// 
// Create Date: 08/26/2015 05:58:22 PM
// Design Name: 
// Module Name: main
// Project Name: Lab01
// Target Devices: xc7a35ticpg236-1L, Basys3
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
    output led,
    input sw
    );
    assign led = sw;   
endmodule
