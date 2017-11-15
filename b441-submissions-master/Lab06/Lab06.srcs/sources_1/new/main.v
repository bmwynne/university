`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2015 05:01:43 PM
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

// full adder
module fulladd(a, b, cin, cout, s); 
    input  a, b, cin;
    output cout, s;
    
    wire w1, w2, w3;
    xor XOR_1(w1,   b, cin);
    xor XOR_2(cout, w1,   a);
    and AND_1(w3,   b, cin);  
    and AND_2(w2,   a, b);
    or   OR_1(s, w2,   w3);

endmodule


// faulty 4-bit parallel adder 
module paradd4(a, b, c_in, s, c_out);
    input [3:0] a,b;
    input c_in;
    output [3:0] s;
    output c_out;
    
    wire w1, w2, w3;
    fulladd fadd1(a[0], b[0], c_in, s[0], w1);
    fulladd fadd2(a[1], b[1], w1, s[1], w2);
    fulladd fadd3(a[2], b[2], w2, s[2], w3);
    fulladd fadd4(a[2], b[2], w3, s[3], c_out);
      
endmodule
     
     


