`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2015 08:57:40 PM
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

`define TRUE 1'b1
`define FALSE 1'b0
`define DELAY 3

module elevator_controller ();
    
    // floor states
    parameter f1    = 3'b001;
    parameter f2    = 3'b010;
    parameter f3    = 3'b011;
    parameter f4    = 3'b100;
    
    // movement states
    parameter NOT   = 3'b000;
    parameter UP2   = 3'b001;
    parameter UP3   = 3'b010;
    parameter UP4   = 3'b011;
    parameter DOWN1 = 3'b100;
    parameter DOWN2 = 3'b101;
    parameter DOWN3 = 3'b110;
    
    reg state;
    reg next_state;
    reg [20:0] count;
   
    wire w;
    assign w = count[25];
    
    
    input clk, reset, push_button;
    reg [3:0] car_status; // is there a car on this floor? T/ F'
    reg [3:0] door_open;
    reg [3:0] push_button;
    
    // timing
    always @ (posedge clk)
    begin
        count <= count + 1;
    end
    
    // change at pos edge or reset
    always @ (posedge w) begin
        if (reset)
            state <= f1;
        else
            state <= next_state;         
        end
    
    // compute values of signals
    always @ (state)
    begin
        
        case (state)
            f1: begin
                car_status[0]  = TRUE;
                door_open[0]   = FALSE;
                push_button[0] = FALSE;
                end
    
            
            f2: begin
                car_status[1]  = TRUE;
                door_open[1]   = FALSE;
                push_button[1] = FALSE;
                end
            
            f3: begin
                car_status[2]  = TRUE;
                door_open[2]   = FALSE;
                push_button[2] = FALSE;
                end
                
            f4: begin
                car_status[3]  = TRUE;
                door_open[3]   = FALSE;
                push_button[3] = FALSE;
                end
         endcase
    end
    
    always @ (state)
    begin
       
       case (state)
           f1: begin
               if (push_button[1] = TRUE) 
               next_state = f2;
               if (push_button[2] = TRUE)
               next_state = f3;
               if (push_button[3] = TRUE)
               next_state = f4;
               else
               next_state = f1;
               end
           
           f2: begin
               if (push_button[2] = TRUE)
               next_state = f3;
               if (push_button[0] = TRUE)
               next_state = f1;
               if (push_button[3] = TRUE)
               next_state = f4;
               else
               next_state = f2;
               end
               
           f3: begin
               if (push_button[3] = TRUE)
               next_state = f4;
               if (push_button[0] = TRUE)
               next_state = f1;
               if (push_button[1] = TRUE)
               next_state = f2;
               else
               next_state = f3;
               end
           
           f4: begin
               if (push_button[0] = TRUE)
               next_state = f1;
               if (push_button[1] = TRUE)
               next_state = f2;
               if (push_button[2] = TRUE)
               next_state = f3;
               else
               next_state = f4;
               end
               
           default:
               next_state = f1;
         endcase
         end
                               
endmodule
