`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indiana University, B441
// Engineer: Brandon Wynne
// 
// Create Date: 09/15/2015 7:55:57 PM
// Design Name: 
// Module Name: main
// Project Name: Lab04
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
    input a, b, c, e, A0, A1, A2, A3, B0, B1, B2, B3, C_IN,
    output d0, d1, d2, d3, d4, d5, d6, d7, S3, S2, S1, S0, C_OUT
);   
    //dec_2_4 Two_To_Four(b, c, e, d0, d1, d2, d3);
    //dec_3_8 Three_To_Eight(a, b, c, d0, d1, d2, d3, d4, d5, d6, d7);
    adder_4b ADD4(A0, A1, A2, A3, B0, B1, B2, B3, C_IN, S0, S1, S2, S3, C_OUT);
 
    endmodule

module dec_2_4(in1, in2, enabler, out0, out1, out2, out3);
    input in1, in2, enabler;
    output out0, out1, out2, out3;
    
    wire w1, w2;
    
    not Inv_1(w1, in1);
    not Inv_2(w2, in2);
    and And_1(out0, w1, w2,    enabler);
    and And_2(out1, w1, in2,   enabler);
    and And_3(out2, w2, in1,   enabler);
    and And_4(out3, in1,  in2, enabler);
    
    endmodule
 
 
module dec_3_8(input1, input2, input3, output0, output1, output2, output3, output4, output5, output6, output7);
    input input1, input2, input3;
    output output0, output1, output2, output3, output4, output5, output6, output7;
     
    wire w1;
    not inv_1(w1, input1);
    dec_2_4 Dec_2_4_1(input2, input3, w1, output0, output1, output2, output3);
    dec_2_4 Dec_2_4_2(input2, input3, input1, output4, output5, output6, output7);
     
    endmodule
    
    
module adder_1b(input1, input2, input3, output1, output2);
    input input1, input2, input3;
    output output1, output2; 
    
    wire w1, w2, w3;
    xor XOR_1(w1, input2, input3);
    xor XOR_2(output1, w1, input1);
    and And_1(w3, input2, input3);
    and And_2(w2, input1, input2);
    or  OR_1(output2, w2, w3);
    
    endmodule   
    
module adder_4b(in1, in2, in3, in4, in5, in6, in7, in8, cin, out1, out2, out3, out4, cout);
    input in1, in2, in3, in4, in5, in6, in7, in8, cin;
    output out1, out2, out3, out4, cout;
    
    wire w1, w2, w3;
    adder_1b add1(in1, in2, cin, out1, w1);
    adder_1b add2(in3, in4, w1, out2, w2);
    adder_1b add3(in5, in6, w2, out3, w3);
    adder_1b add4(in7, in8, w3, out4, cout); 
    
    endmodule
    

    
    
