`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2015 06:12:29 PM
// Design Name: 
// Module Name: tb_Mux_4_1
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


module tb_Mux_4_1;

    wire Y;
    reg  S0, S1, D0, D1, D2, D3;
    Mux_4_1 MUX(S0, S1, D0, D1, D2, D3, Y);
    
    initial
    begin
        S0 = 0; S1 = 0; D0 = 0; D1 = 0; D2 = 0; D3 = 0; 
        
       #10 D0 = 1;
       #10 D0 = 0;
       #10 S0 = 1; D1 = 1;
       #10 D1 = 0; S0 = 0; S1 = 1; D2 = 1;
       #10 D2 = 0; S0 = 1; D3 = 1;
       #10;
        $finish;
                   
end
endmodule
