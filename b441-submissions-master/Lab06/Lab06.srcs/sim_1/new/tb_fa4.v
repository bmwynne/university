`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2015 05:53:38 PM
// Design Name: 
// Module Name: tb_fa4
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


module tb_fa4();
    
    wire [3:0] carry_bit, S;
    wire [3:0] bhvm_c_bit;
    reg [3:0] A, B;
    reg C_IN;
    integer i, j;
  
    paradd4    tb_1(A, B, C_IN, S, carry_bit); 
    bm_paradd4 tb_2(A, B, bhvm_c_bit);
    initial
    begin
        A = 0; B = 0; C_IN = 0;
            for (i = 0; i < 16; i = i + 1) // 16 x 16 = 256 or 2 ^ 8
            begin
            #5 A = i;
            #5 B = 0;
                for (j = 0; j < 16; j = j + 1) // 16
                begin
                #5 B = j;
                #5;             
                if(S != (A + B))
                begin
                $display("ERROR:");
                $display("The value of A is: %b, B is: %b, and S is %b.", A, B, S);
                $display("the correct output of S is : %b", bhvm_c_bit);
                $finish;
                end
                end   
           end
    #5 $finish;
    end  
    
endmodule

