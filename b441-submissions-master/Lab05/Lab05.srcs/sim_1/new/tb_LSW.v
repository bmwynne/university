`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2015 08:05:29 PM
// Design Name: 
// Module Name: tb_LSW
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


module tb_LSW;

    wire Light;
    reg SW0, SW1, SW2, SW3;
    LightSW_4 LSW_BENCH(SW0, SW1, SW2, SW3, Light);
    initial
    begin
        SW0 = 0; SW1 = 0; SW2 = 0; SW3 = 0;
     #10 SW3 = 1;
     #10 SW3 = 0; SW2 = 1;
     #10 SW3 = 1;
     #10 SW1 = 1; SW2 = 0; SW3 = 0;
     #10 SW3 = 1; 
     #10 SW3 = 0; SW2 = 1;
     #10 SW3 = 0;
     #10 S0 = 1; SW1 = 0; SW2 = 0; SW3 = 0;
     #10 SW2 = 1;
     #10 SW3 = 1;
     #10 SW2 = 0; SW3 = 0; SW1 = 1;
     #10 SW3 = 1;
     #10 SW2 = 1; SW3 = 0;
     #10 SW3 = 1;
     #10;
        $finish
     end
     endmodule
     
endmodule
