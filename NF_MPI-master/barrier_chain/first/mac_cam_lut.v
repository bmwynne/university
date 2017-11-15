///////////////////////////////////////////////////////////////////////////////
// $Id: mac_cam_lut.v 1887 2007-06-19 21:33:32Z grg $
//
// Module: mac_lut.v
// Project: NF2.1
// Description: Looks up the mac<->output port mapping for a given MAC address
//              and can learn new mappings
//
//              Does not assume that the inputs are held, so it latches them
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
  module mac_cam_lut
    #(parameter NUM_OUTPUT_QUEUES = 8,
      parameter LUT_DEPTH_BITS = 4,
      parameter LUT_DEPTH = 2**LUT_DEPTH_BITS,
      parameter NUM_IQ_BITS = 3,
      parameter DEFAULT_MISS_OUTPUT_PORTS = 8'h55) // only send to the txfifos not the cpu

   ( // --- lookup and learn port
     input [15:0]                       comm_id,
     input                              lookup_req,
     input [2:0]			barrier_state_in,
     output [2:0] 			barrier_state_out,
     output reg                         lookup_ack,

     // --- Register signals
     output reg                         lut_hit,          // pulses high on a hit
     output reg                         lut_miss,         // pulses high on a miss

     // --- Misc
     input                              clk,
     input                              reset

     );

   //--------------------- Internal Parameter-------------------------
   parameter RESET            = 1;
   parameter IDLE             = 2;
   parameter LATCH_DST_LOOKUP = 4;
   parameter CHECK_SRC_MATCH  = 8;
   parameter UPDATE_ENTRY     = 16;
   parameter ADD_ENTRY        = 32;

   //---------------------- Wires and regs----------------------------

   wire                                  cam_busy;
   wire                                  cam_match;
   wire [LUT_DEPTH_BITS-1:0]             cam_match_addr;
   reg  [LUT_DEPTH_BITS-1:0]             cam_match_addr_d1;
   reg  [15:0]                           cam_cmp_din;
   reg  [15:0]                           cam_din, cam_din_next;
   reg                                   cam_we, cam_we_next;
   reg  [LUT_DEPTH_BITS-1:0]             cam_wr_addr, cam_wr_addr_next;

   reg  [15:0]                           comm_id_latched;
   reg	[2:0]				 barrier_state_latched;
   reg                                   latch_comm_id;

   reg  [5:0]                            lookup_state, lookup_state_next;   

   reg [LUT_DEPTH_BITS-1:0]              lut_rd_addr, lut_wr_addr, lut_wr_addr_next;
   reg                                   lut_wr_en, lut_wr_en_next;
   reg [19:0]				 lut_wr_data, lut_wr_data_next;
   reg [19:0]				 lut_rd_data;
   reg [19:0]          			 lut[LUT_DEPTH-1:0];
   
   reg                                   reset_count_inc;
   reg [LUT_DEPTH_BITS:0]                reset_count;
   reg                                   lookup_ack_next;
   reg                                   lut_hit_next, lut_miss_next;

   //------------------------- Modules-------------------------------

   /* 1 cycle read latency, 16 cycles write latency
   cam_16x48 mac_cam
     (
      // Outputs
      .busy                             (cam_busy),
      .match                            (cam_match),
      .match_addr                       (cam_match_addr[LUT_DEPTH_BITS-1:0]),
      // Inputs
      .clk                              (clk),
      .cmp_din                          (cam_cmp_din[15:0]),
      .din                              (cam_din[15:0]),
      .we                               (cam_we),
      .wr_addr                          (cam_wr_addr[LUT_DEPTH_BITS-1:0]));
   */
   //------------------------- Logic --------------------------------

   assign barrier_state_out  = (lookup_ack & lut_miss) ? 0 : lut_rd_data[2:0];

   assign entry_needs_update = ((barrier_state_in != barrier_state_out));

   always @(*) begin
      cam_wr_addr_next = cam_match_addr;
      cam_din_next     = comm_id_latched;
      cam_we_next      = 0;
      cam_cmp_din      = 0;
      lut_rd_addr      = cam_match_addr;
      lut_wr_en_next   = 1'b0;
      lut_wr_data_next = {1'b0, comm_id_latched, barrier_state_latched};
      lut_wr_addr_next = cam_match_addr;
      reset_count_inc  = 0;
      latch_comm_id    = 0;
      lookup_ack_next  = 0;
      lut_hit_next     = 0;
      lut_miss_next    = 0;

      lookup_state_next = lookup_state;

      case(lookup_state)
        /* write to all locations 
        RESET: begin
           if( !cam_we && !cam_busy && reset_count <= LUT_DEPTH-1) begin
              cam_wr_addr_next = reset_count;
              cam_we_next = 1;
              cam_din_next = 0;
              reset_count_inc = 1;
              lut_wr_addr_next = reset_count;
              lut_wr_data_next = 0;
              lut_wr_en_next = 1;
           end
           else if( !cam_we && !cam_busy) begin
              lookup_state_next = IDLE;
           end
        end // case: RESET
	*/

        IDLE: begin
	   //cam_cmp_din = comm_id;  //burayi cozemedim daha
           if(lookup_req && !lookup_ack) begin
              lookup_state_next = CHECK_SRC_MATCH; //LATCH_DST_LOOKUP;
              latch_comm_id = 1;
           end
        end // case: IDLE

        CHECK_SRC_MATCH: begin
           /* look for an empty address in case we need it */
           cam_cmp_din = 0;
           /* if we have a match then we need to update lut */
           if(cam_match && barrier_state_latched != 0) begin
	      lookup_ack_next = 1;
              lut_hit_next = 1;
              lookup_state_next = UPDATE_ENTRY;
           end
	   /* if we have a match then wait for lut output */
	   else if(cam_match && barrier_state_latched == 0) begin
              lookup_ack_next = 1;
              lut_hit_next = 1;
              lookup_state_next = IDLE;
           end
           /* otherwise we need to add the entry */
           else begin
	      lookup_ack_next = 1;
              lut_miss_next = 1;
              lookup_state_next = ADD_ENTRY;
           end
        end // case: CHECK_SRC_MATCH

        UPDATE_ENTRY: begin
           if(entry_needs_update) begin
              lut_wr_addr_next = cam_match_addr_d1;
              lut_wr_en_next = 1;
           end
           lookup_state_next = IDLE;
        end

        ADD_ENTRY: begin
           /* if we found an empty spot */
           if(cam_match) begin
              lut_wr_addr_next = cam_match_addr;
              lut_wr_en_next = 1;
              cam_wr_addr_next = cam_match_addr;
              cam_we_next = 1;
           end
           lookup_state_next = IDLE;
        end

        default: begin end
      endcase // case(lookup_state)
   end // always @ (*)

   always @(posedge clk) begin
      if(reset) begin
         lut_rd_data		<= 0;
         reset_count		<= 0;
         barrier_state_latched  <= 0;
         comm_id_latched   	<= 0;
         lookup_ack        	<= 0;
         lut_hit           	<= 0;
         lut_miss          	<= 0;
         cam_match_addr_d1 	<= 0;

         cam_wr_addr       	<= 0;
         cam_din           	<= 0;
         cam_we            	<= 0;
         lut_wr_en         	<= 0;
         lut_wr_data       	<= 0;
         lut_wr_addr       	<= 0;

         lookup_state      	<= RESET;
      end
      else begin
         reset_count		<= reset_count_inc ? reset_count + 1 : reset_count;
         barrier_state_latched  <= latch_comm_id ? barrier_state_in : barrier_state_latched;
         comm_id_latched   	<= latch_comm_id ? comm_id : comm_id_latched;
	 
         if(lookup_ack_next) begin
            lookup_ack        <= 1;
         end
         else if(!lookup_req) begin
            lookup_ack        <= 0;
         end
         lut_hit           <= lut_hit_next;
         lut_miss          <= lut_miss_next;

	 lut_rd_data	   <= lut[lut_rd_addr];

         if(lut_wr_en) begin
            lut[lut_wr_addr] <= lut_wr_data;
         end

         cam_match_addr_d1 <= cam_match_addr;

         cam_wr_addr       <= cam_wr_addr_next;
         cam_din           <= cam_din_next;
         cam_we            <= cam_we_next;
         lut_wr_en         <= lut_wr_en_next;
         lut_wr_data       <= lut_wr_data_next;
         lut_wr_addr       <= lut_wr_addr_next;

         lookup_state      <= lookup_state_next;
      end
   end


endmodule // mac_lut






