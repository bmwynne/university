`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2015 09:23:07 PM
// Design Name: 
// Module Name: tb_AU
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


module tb_AU();
    reg [3:0] a, b;
    reg f0, f1;
    reg c_in;
    wire c_out, y;
   
    AU_4Bit arith_unit(a, b, c_in, f0, f1, c_out, y);
    initial
    begin
        a = 0000; b = 0000; c_in = 0; f0 = 0; f1 = 0;  
     #5 a = 0001; b = 0001;
     #5 a = 0010; b = 0000;
        a = 0000; b = 0000; c_in = 1; f0 = 1; f1 = 0;
     #5 a = 0010; b = 1000;
        a = 0000; b = 0000; c_in = 1; f0 = 1; f1 = 1;
        a = 1111;
    
//        begin
//            #5 $display("Test1 = %d, Test2 = %d, Test3 = %d", test1, test2, test3);
           
//        end
        $finish;
    end
    
    
     
     
endmodule
