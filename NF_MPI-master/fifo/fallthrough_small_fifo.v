///////////////////////////////////////////////////////////////////////////////
// $Id: fallthrough_small_fifo.v 5205 2009-03-08 18:54:46Z grg $
//
// Module: fallthrough_small_fifo.v
// Project: NF_2.1_reference
// Description: small fifo with first word fallthrough i.e. data valid as soon as
//  it is available
//
// Change history:
//   8/2/07 -- Set nearly full to 2^MAX_DEPTH_BITS - 1 by default so that it
//             goes high a clock cycle early.
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module fallthrough_small_fifo
    (  
     input [WIDTH-1:0] din,     // Data in
     input          wr_en,   // Write enable

     input          rd_en,   // Read the next word

     output [WIDTH-1:0] dout,    // Data out
     output         full,
     output         nearly_full,
     output         empty,

     input          reset,
     input          clk
     );

   parameter WIDTH = 72;
   parameter MAX_DEPTH_BITS = 3;
   parameter NEARLY_FULL = 2**MAX_DEPTH_BITS - 1;


   parameter MAX_DEPTH = 2 ** MAX_DEPTH_BITS;
   parameter SEL_DIN   = 0;
   parameter SEL_QUEUE = 1;
   parameter SEL_KEEP  = 2;


   reg [WIDTH-1:0]                queue [MAX_DEPTH - 1 : 0];
   reg [MAX_DEPTH_BITS - 1 : 0]   rd_ptr ;
   wire [MAX_DEPTH_BITS - 1 : 0]  rd_ptr_plus1 = rd_ptr+1;
//   assign rd_ptr_plus1 = rd_ptr+1;
   reg [MAX_DEPTH_BITS - 1 : 0]   wr_ptr ;
   reg [MAX_DEPTH_BITS : 0]       depth  ;

   reg [WIDTH-1:0]                queue_rd;
   reg [WIDTH-1:0]                din_d1;
   reg [WIDTH-1:0]                dout_d1;
   reg [1:0]                      dout_sel;
   reg [WIDTH-1:0]                deneme;

   // Sample the data
   always @(posedge clk)
     begin
        if (wr_en)
          queue[wr_ptr] <= din;

        queue_rd <= queue[rd_ptr_plus1];
        din_d1 <= din;
	dout_d1 <= dout;

        if (rd_en && wr_en && (rd_ptr_plus1==wr_ptr)) begin
           dout_sel <= SEL_DIN;
        end
        else if(rd_en) begin
           dout_sel <= SEL_QUEUE;
        end
        else if(wr_en && (rd_ptr==wr_ptr)) begin
           dout_sel <= SEL_DIN;
        end
	else begin
	   dout_sel <= SEL_KEEP;
	   end
     end

   always @(posedge clk)
     begin
        if (reset) begin
           rd_ptr <= 'h0;
           wr_ptr <= 'h0;
           depth  <= 'h0;
        end
        else begin
           if (wr_en) wr_ptr <= wr_ptr + 'h1;
           if (rd_en) rd_ptr <= rd_ptr_plus1;
           if (wr_en & ~rd_en) depth <= depth+1;
                                        //depth + 'h1;
           if (~wr_en & rd_en) depth <=
                                        depth - 'h1;
        end
     end

   assign dout = (dout_sel==SEL_QUEUE) ? queue_rd : ((dout_sel==SEL_DIN) ? din_d1 : dout_d1);
   assign full = depth == MAX_DEPTH;
   //assign full = wr_en;
   assign nearly_full = depth >= NEARLY_FULL;
   assign empty = depth == 'h0;

endmodule // small_fifo


/* vim:set shiftwidth=3 softtabstop=3 expandtab: */
