///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: output_port_lookup.v 5240 2009-03-14 01:50:42Z grg $
//
// Module: switch_output_port.v
// Project: NF2.1
// Description: reads incoming packets parses them and decides on the output port
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
  module output_port_lookup
    #(parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH=DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter INPUT_ARBITER_STAGE_NUM = 2,
      parameter NUM_OUTPUT_QUEUES = 8,
      parameter STAGE_NUM = 4,
      parameter NUM_IQ_BITS = 3)

   (// --- data path interface
    output reg [DATA_WIDTH-1:0]        out_data,
    output reg [CTRL_WIDTH-1:0]        out_ctrl,
    output reg                         out_wr,
    input                              out_rdy,

    input  [DATA_WIDTH-1:0]            in_data,
    input  [CTRL_WIDTH-1:0]            in_ctrl,
    input                              in_wr,
    output                             in_rdy,

    // --- Register interface
    input                              reg_req_in,
    input                              reg_ack_in,
    input                              reg_rd_wr_L_in,
    input  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_in,
    input  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_in,
    input  [UDP_REG_SRC_WIDTH-1:0]     reg_src_in,

    output                             reg_req_out,
    output                             reg_ack_out,
    output                             reg_rd_wr_L_out,
    output  [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
    output  [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
    output  [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,


    // --- Misc
    input                              clk,
    input                              reset);

   function integer log2;
      input integer number;
      begin
	     log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   //--------------------- Internal Parameter-------------------------
   parameter LUT_DEPTH_BITS = 4;
   parameter DEFAULT_MISS_OUTPUT_PORTS = 8'b01010101; // exclude the CPU queues

   parameter NUM_STATES            = 4;
   
   parameter WAIT_TILL_DONE_DECODE = 0;
   parameter WRITE_HDR             = 1;
   parameter STORE_PKT_FIELDS      = 2;
   parameter RESTORE_PKT_FIELDS    = 3;
   parameter REVERSE_PKT_FIELDS    = 4;
   parameter CASH_PACKET           = 5;
   parameter UPDATE_REDUCE_MSG     = 6;
   parameter WAIT_PAYLOAD          = 7;
   parameter WAIT_EOP              = 8;

   localparam LOOPEND           = 256;
   
   //states
  
   localparam REDUCE_IDLE       = 0;
   
   localparam REDUCE_RING_HELT  	= 1;
   localparam REDUCE_RING_HERT  	= 2;
   localparam REDUCE_RING_HIL	  	= 3;
   localparam REDUCE_RING_HIR 	 	= 4;
   localparam REDUCE_RING_HIT		= 5;
   localparam REDUCE_RING_L			= 6;
   localparam REDUCE_RING_R			= 7;
   localparam REDUCE_RING_RL		= 8;
   localparam REDUCE_RING_L_HIT		= 9;
   localparam REDUCE_RING_R_HIT		= 10;
   localparam REDUCE_RING_LOCK_A	= 11;
   localparam REDUCE_RING_LOCK_A_R	= 12;
   localparam REDUCE_RING_LOCK_A_L	= 13;
   localparam REDUCE_RING_LOCK_B	= 14;
   localparam REDUCE_RING_LOCK_B_R	= 15;
   localparam REDUCE_RING_LOCK_B_L	= 16;
   
   localparam REDUCE_TREE_HRT		= 17; //
   localparam REDUCE_TREE_HRNT		= 18;
   localparam REDUCE_TREE_HIT		= 19; //
   localparam REDUCE_TREE_HLT		= 20; 
   localparam REDUCE_TREE_HITNIS	= 21; //
   localparam REDUCE_TREE_HITILS	= 22; //
   localparam REDUCE_TREE_HITIRS	= 23; //
   localparam REDUCE_TREE_L			= 24;
   localparam REDUCE_TREE_R			= 25;
   localparam REDUCE_TREE_P			= 26;  
   localparam REDUCE_TREE_RL		= 27;
   localparam REDUCE_TREE_PL		= 28;
   localparam REDUCE_TREE_PR		= 29;
   localparam REDUCE_TREE_PRL		= 30;
   localparam REDUCE_TREE_L_HRT		= 31;
   localparam REDUCE_TREE_L_HIT		= 32;
   localparam REDUCE_TREE_L_HITNIS	= 33;
   localparam REDUCE_TREE_L_HITIRS	= 34;
   localparam REDUCE_TREE_R_HRT		= 35;
   localparam REDUCE_TREE_R_HIT		= 36;
   localparam REDUCE_TREE_R_HITNIS	= 37;
   localparam REDUCE_TREE_R_HITILS	= 38;
   localparam REDUCE_TREE_P_HIT		= 39;
   localparam REDUCE_TREE_P_HITILS	= 40;
   localparam REDUCE_TREE_P_HITIRS	= 41;
   localparam REDUCE_TREE_PR_HIT	= 42;
   localparam REDUCE_TREE_PL_HIT	= 43;
   localparam REDUCE_TREE_RL_HIT	= 44;
   localparam REDUCE_TREE_LOCK_A	= 45;
   localparam REDUCE_TREE_LOCK_A_P	= 46;
   localparam REDUCE_TREE_LOCK_A_L	= 47;
   localparam REDUCE_TREE_LOCK_A_R	= 48;
   localparam REDUCE_TREE_LOCK_A_PL	= 49;
   localparam REDUCE_TREE_LOCK_A_PR	= 50;
   localparam REDUCE_TREE_LOCK_A_RL	= 51;
   localparam REDUCE_TREE_LOCK_A_PRL= 52;
   localparam REDUCE_TREE_LOCK_B	= 53;
   localparam REDUCE_TREE_LOCK_B_P	= 54;
   localparam REDUCE_TREE_LOCK_B_L	= 55;
   localparam REDUCE_TREE_LOCK_B_R	= 56;
   localparam REDUCE_TREE_LOCK_B_PL	= 57;
   localparam REDUCE_TREE_LOCK_B_PR	= 58;
   localparam REDUCE_TREE_LOCK_B_RL	= 59;
   localparam REDUCE_TREE_LOCK_B_PRL= 60;
   localparam REDUCE_TREE_LOCK_C	= 61;
   localparam REDUCE_TREE_LOCK_C_P	= 62;
   localparam REDUCE_TREE_LOCK_C_L	= 63;
   localparam REDUCE_TREE_LOCK_C_R	= 64;
   localparam REDUCE_TREE_LOCK_C_PL	= 65;
   localparam REDUCE_TREE_LOCK_C_PR	= 66;
   localparam REDUCE_TREE_LOCK_C_RL	= 67;
   localparam REDUCE_TREE_LOCK_C_PRL= 68;
    
   //topology types
      
   localparam TOPO_RING		   = 1;
   localparam TOPO_TREE		   = 2;
   localparam TOPO_BUTTERFLY   = 3;
   localparam TOPO_TRUNK	   = 4;
   localparam TOPO_STAR        = 5;
  
	
   //node types
   localparam NODE_RING_ELT		= 0;
   localparam NODE_RING_ERT		= 1;
   localparam NODE_RING_ELNT  	= 2;
   localparam NODE_RING_ERNT   	= 3;
   localparam NODE_RING_IT 		= 4;
   localparam NODE_RING_IR  	= 5;
   localparam NODE_RING_IL   	= 6;
   localparam NODE_RING			= 7;
   
   localparam NODE_TREE_LT		= 0; 
   localparam NODE_TREE_LNT	    = 1; 
   localparam NODE_TREE_RT		= 2; 
   localparam NODE_TREE_RNT     = 3; 
   localparam NODE_TREE_IT		= 4; 
   localparam NODE_TREE_ITNIS	= 5;
   localparam NODE_TREE_ITILS	= 6;
   localparam NODE_TREE_ITIRS	= 7;
   localparam NODE_TREE			= 8;




   localparam MSG_AT_REDUCE             = 65;
   localparam MSG_PREV_AT_REDUCE        = 66;
   localparam MSG_RELEASE_REDUCE        = 67;
   localparam MSG_SIBBLING_AT_REDUCE    = 68;
   localparam MSG_CHILDREN_AT_REDUCE    = 69;
 
   localparam MSG_AT_BR				= 65;   
   localparam MSG_PREV_AT_BR		= 66;
   localparam MSG_RLS_BR			= 67;
   localparam MSG_CHILD_AT_BR		= 68;
   
   localparam MSG_RLS_REDUCE		= 1;
   localparam MSG_RLS_L				= 2;
   localparam MSG_RLS_H				= 3;
   
   
   //---------------------- Wires and regs----------------------------

   wire                         lookup_ack;
   //wire [47:0] 			dst_mac;
   //wire [47:0]                  src_mac;
   wire [15:0]                  ethertype;
   wire [NUM_IQ_BITS-1:0]       src_port;
   wire                         decode_done;
   wire			      			reduce_pkt;
   wire	       					not_reduce_pkt;
   wire [15:0]	       			message;
   wire [15:0]		       		comm_id;
   wire [7:0]	       			topo_type;
   wire [7:0]		       		node_type;
   wire [15:0]					rank;
   wire [15:0]					root;
   wire [15:0]					size;
   wire [15:0]					op;
   wire [15:0]					count;
   wire [15:0]					data_type;
   wire [15:0]					on_the_path;
   wire [15:0]       			comm_id_latched;
   wire [7:0]                   topo_type_latched;
   wire [7:0]                   node_type_latched;
   wire [15:0]		       		message_latched;
   wire [15:0]					rank_latched;
   wire [15:0]					root_latched;
   wire [15:0]					size_latched;
   wire [15:0]					op_latched;
   wire [15:0]					count_latched;
   wire [15:0]					data_type_latched;
   wire [15:0]					on_the_path_latched;
   
   reg [31:0] 			src_ip, src_ip_next;
   reg [31:0] 			dst_ip, dst_ip_next;
   reg [15:0] 			ip_cksum, ip_cksum_next; 			
   reg [47:0] 			src_mac, src_mac_next;
   reg [47:0] 			dst_mac, dst_mac_next;
   reg [15:0] 			udp_src, udp_src_next;
   reg [15:0] 			udp_dst, udp_dst_next;
   
   
   wire [47:0] 			src_mac_cur;
   wire [47:0] 			dst_mac_cur;
   wire [31:0] 			src_ip_cur;
   wire [31:0] 			dst_ip_cur;
   wire [15:0] 			ip_cksum_cur;
   wire [15:0] 			udp_src_cur;
   wire [15:0] 			udp_dst_cur;
 			
			
   wire [NUM_OUTPUT_QUEUES-1:0] dst_ports;
   wire [NUM_OUTPUT_QUEUES-1:0] dst_ports_latched;

   wire [LUT_DEPTH_BITS-1:0]    rd_addr;          // address in table to read
   wire                         rd_req;           // request a read
   wire [NUM_OUTPUT_QUEUES-1:0] rd_oq;            // data read from the LUT at rd_addr
   wire                         rd_wr_protect;    // wr_protect bit read
   wire [47:0]                  rd_mac;           // data to match in the CAM
   wire                         rd_ack;           // pulses high when data is rdy

   wire [LUT_DEPTH_BITS-1:0]    wr_addr;
   wire                         wr_req;
   wire [NUM_OUTPUT_QUEUES-1:0] wr_oq;
   wire                         wr_protect;       // wr_protect bit to write
   wire [47:0]                  wr_mac;           // data to match in the CAM
   wire                         wr_ack;           // pulses high when wr is done

   wire                         lut_hit;          // pulses high on a hit
   wire                         lut_miss;         // pulses high on a miss

   reg                          in_fifo_rd_en;
   wire [CTRL_WIDTH-1:0]        in_fifo_ctrl_dout;
   wire [DATA_WIDTH-1:0]        in_fifo_data_dout;
   wire                         in_fifo_nearly_full;
   wire                         in_fifo_empty;

   reg                          dst_port_rd;
   wire                         dst_port_fifo_nearly_full;
   wire                         dst_port_fifo_empty;

   reg [15:0]		       		decoded_src;

   reg [NUM_STATES-1:0]         state, state_next;
   reg [7:0]   					reduce_state, reduce_state_next;
   reg [7:0]   					prev_reduce_state, prev_reduce_state_next;
   
   reg [2:0]	       			word_count, word_count_next;

   reg [63:0] 					buffer [0:255];
   reg [8:0] 					buffer_rd_addr, buffer_rd_addr_next;
   reg [8:0] 					buffer_wr_addr, buffer_wr_addr_next;
   reg [63:0] 					buffer_rd_data, buffer_rd_data_next;
   reg [63:0] 					buffer_wr_data, buffer_wr_data_next;
   reg 							buffer_wr_en, buffer_wr_en_next;
 			
   
   //------------------------- Modules-------------------------------
   //------------------------- Modules-------------------------------
   is_reduce_pkt
     #(.DATA_WIDTH (DATA_WIDTH),
       .CTRL_WIDTH (CTRL_WIDTH),
       .NUM_IQ_BITS(NUM_IQ_BITS),
       .INPUT_ARBITER_STAGE_NUM(INPUT_ARBITER_STAGE_NUM))
     is_reduce_pkt
         (.in_data(in_data),
          .in_ctrl(in_ctrl),
          .in_wr(in_wr),
          .reduce_pkt (reduce_pkt),
          .not_reduce_pkt (not_reduce_pkt),
          .decode_done (decode_done),
          .message (message),
          .comm_id (comm_id),
          .topo_type (topo_type),
          .node_type (node_type),
          .rank (rank),
          .root (root),
          .size (size),
          .op (op),
          .count (count),
          .data_type (data_type),
          .on_the_path (on_the_path),
          .src_mac (src_mac_cur),
          .dst_mac (dst_mac_cur),
          .src_ip (src_ip_cur),
          .dst_ip (dst_ip_cur),
          .ip_cksum (ip_cksum_cur),
          .udp_src (udp_src_cur),
          .udp_dst (udp_dst_cur),
          .reset(reset),
          .clk(clk));
   
   /* The size of this fifo has to be large enough to fit the previous modules' headers
    * and the ethernet header */
   small_fifo #(.WIDTH(DATA_WIDTH+CTRL_WIDTH), .MAX_DEPTH_BITS(5))
   input_fifo
     (.din ({in_ctrl,in_data}),     // Data in
      .wr_en (in_wr),               // Write enable
      .rd_en (in_fifo_rd_en),       // Read the next word
      .dout ({in_fifo_ctrl_dout, in_fifo_data_dout}),
      .full (),
      .prog_full (),
      .nearly_full (in_fifo_nearly_full),
      .empty (in_fifo_empty),
      .reset (reset),
      .clk (clk)
      );
   
   small_fifo #(.WIDTH(160), .MAX_DEPTH_BITS(2))
   dst_port_fifo
     (.din ({message, comm_id, topo_type, node_type, rank, root, size, op, count, data_type, on_the_path}),     // Data in
      .wr_en (decode_done),             // Write enable
      .rd_en (dst_port_rd),       // Read the next word
      .dout ({message_latched, comm_id_latched, topo_type_latched, node_type_latched, rank_latched, root_latched, size_latched, op_latched, count_latched, data_type_latched, on_the_path_latched}),
      .full (),
      .prog_full (),
      .nearly_full (dst_port_fifo_nearly_full),
      .empty (dst_port_fifo_empty),
      .reset (reset),
      .clk (clk)
      );
   
   //----------------------- Logic -----------------------------
   
   assign    in_rdy = !in_fifo_nearly_full && !dst_port_fifo_nearly_full;
   
   /* pkt is from the cpu if it comes in on an odd numbered port */
   assign pkt_is_from_cpu = in_fifo_data_dout[`IOQ_SRC_PORT_POS];
   assign pkt_is_from_A = decoded_src[0];
   assign pkt_is_from_B = decoded_src[2];
   assign pkt_is_from_C = decoded_src[4];
   
   /* Decode the source port */
   always @(*) begin
      decoded_src = 0;
      decoded_src[in_fifo_data_dout[`IOQ_SRC_PORT_POS+15:`IOQ_SRC_PORT_POS]] = 1'b1;
   end
   
   /*********************************************************************
    * Wait until the ethernet header has been decoded and the output
    * port is found, then write the module header and move the packet
    * to the output
    **********************************************************************/
   always @(*) begin
      out_ctrl           = in_fifo_ctrl_dout;
      out_data           = in_fifo_data_dout;
      state_next	  = state;
      reduce_state_next = reduce_state;
      prev_reduce_state_next = prev_reduce_state;
      out_wr 	       	  = 0;
      in_fifo_rd_en 	  = 0;
      dst_port_rd 	  = 0;
      word_count_next    = word_count;
      src_ip_next        = src_ip;
      dst_ip_next        = dst_ip;
      ip_cksum_next      = ip_cksum;
      dst_mac_next       = dst_mac;
      src_mac_next       = src_mac;
      udp_src_next       = udp_src;
      udp_dst_next       = udp_dst;

      buffer_wr_en_next = 0;
      buffer_rd_addr_next = buffer_rd_addr;
      buffer_wr_data_next = in_fifo_data_dout;
      buffer_wr_addr_next = buffer_wr_addr;


      case(state)
	      WAIT_TILL_DONE_DECODE: begin
		      if(!dst_port_fifo_empty) begin
			      dst_port_rd     = 1;
			      state_next      = WRITE_HDR;
			      in_fifo_rd_en   = 1;
			  end
		  end
		  
		  WRITE_HDR: begin
			  if(out_rdy) begin
				  out_wr = 1;
				  in_fifo_rd_en = 1;
				  //reduce traffic
				  $display("WRITE_HEADER : %d %d %d",reduce_pkt, not_reduce_pkt, in_fifo_ctrl_dout);
				  if(reduce_pkt && !not_reduce_pkt && in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
					  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = 0;
					  $display("Reduce packet : %d %d %d %d", topo_type_latched, rank_latched, root_latched, size_latched);
					  case(topo_type_latched)
						  TOPO_RING: begin
							  //ring_topo_edge_non_target_node_state_machine
							  $display("Reduce State RING: %d \t Node_type : %d ---- %d %d %d",reduce_state, node_type_latched, pkt_is_from_cpu, pkt_is_from_A, pkt_is_from_B);
							  case(reduce_state)
								  REDUCE_IDLE: begin
									  if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_RING_ELT: begin
												  reduce_state_next = REDUCE_RING_HELT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("1");
											  end
											  NODE_RING_ERT: begin
												  reduce_state_next = REDUCE_RING_HERT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("2");
											  end
											  NODE_RING_ELNT: begin
												  reduce_state_next = REDUCE_RING_LOCK_A;
												  prev_reduce_state_next = REDUCE_IDLE;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000001};
												  $display("3");
											  end
											  NODE_RING_ERNT: begin
												  reduce_state_next = REDUCE_RING_LOCK_B;
												  prev_reduce_state_next = REDUCE_IDLE;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000100};
												  $display("4");
											  end
											  NODE_RING_IT: begin
												  reduce_state_next = REDUCE_RING_HIT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("5");
											  end
											  NODE_RING_IR: begin
												  reduce_state_next = REDUCE_RING_HIR;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("6");
											  end
											  NODE_RING_IL: begin
												  reduce_state_next = REDUCE_RING_HIL;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("7");
											  end
										  endcase
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_RING_R;
										  prev_reduce_state_next = REDUCE_IDLE;
										  state_next = WAIT_PAYLOAD;
										  $display("8");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_RING_L;
										  prev_reduce_state_next = REDUCE_IDLE;
										  state_next = WAIT_PAYLOAD;
										  $display("9");
									  end
								  end
								  REDUCE_RING_HELT: begin
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_RING_HELT;
										  state_next = RESTORE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
										  $display("10");
									  end
								  end
								  REDUCE_RING_HERT: begin
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_RING_HERT;
										  state_next = RESTORE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000110};
										  $display("11");
									  end
								  end
								  REDUCE_RING_HIL: begin
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_RING_LOCK_A;
										  prev_reduce_state_next = REDUCE_RING_HIT;
										  state_next = UPDATE_REDUCE_MSG;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
										  $display("12");
									  end
								  end
								  REDUCE_RING_HIR: begin
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_RING_LOCK_B;
										  prev_reduce_state_next = REDUCE_RING_HIR;
										  state_next = UPDATE_REDUCE_MSG;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
										  $display("13");
									  end
								  end
								  REDUCE_RING_HIT: begin
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_RING_R_HIT;
										  prev_reduce_state_next = REDUCE_RING_HIT;
										  state_next = WAIT_PAYLOAD;
										  $display("14");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_RING_L_HIT;
										  prev_reduce_state_next = REDUCE_RING_HIT;
										  state_next = WAIT_PAYLOAD;
										  $display("15");
									  end
								  end
								  REDUCE_RING_L: begin
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_RING_RL;
										  prev_reduce_state_next = REDUCE_RING_L;
										  state_next = WAIT_PAYLOAD;
										  $display("16_");
									  end
									  else if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_RING_IL: begin
												  reduce_state_next = REDUCE_RING_LOCK_A;
												  prev_reduce_state_next = REDUCE_RING_L;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
												  $display("17");
											  end
											  NODE_RING_IT: begin
												  reduce_state_next = REDUCE_RING_L_HIT;
												  prev_reduce_state_next = REDUCE_RING_L;
												  $display("18");
											  end
											  NODE_RING_ERT: begin
												  state_next = REVERSE_PKT_FIELDS;
												  reduce_state_next = REDUCE_IDLE;
												  prev_reduce_state_next = REDUCE_RING_L;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000110};
												  $display("19");
											  end
										  endcase
									  end
								  end
								  REDUCE_RING_R: begin
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_RING_RL;
										  prev_reduce_state_next = REDUCE_RING_R;
										  state_next = WAIT_PAYLOAD;
										  $display("20");
									  end
									  else if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_RING_IR: begin
												  reduce_state_next = REDUCE_RING_LOCK_B;
												  prev_reduce_state_next = REDUCE_RING_R;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
												  $display("21");
											  end
											  NODE_RING_IT: begin
												  reduce_state_next = REDUCE_RING_R_HIT;
												  prev_reduce_state_next = REDUCE_RING_R;
												  $display("22");
											  end
											  NODE_RING_ELT: begin
												  state_next = REVERSE_PKT_FIELDS;
												  reduce_state_next = REDUCE_IDLE;
												  prev_reduce_state_next = REDUCE_RING_R;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
												  $display("23");
											  end
										  endcase
									  end
								  end
								  REDUCE_RING_RL: begin
									  if(pkt_is_from_cpu && node_type_latched == NODE_RING_IT) begin
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_RING_RL;
										  state_next = REVERSE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
										  $display("24");
									  end
								  end
								  REDUCE_RING_L_HIT: begin
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_RING_L_HIT;
										  state_next = RESTORE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
										  $display("25");
									  end
								  end
								  REDUCE_RING_R_HIT: begin
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_RING_R_HIT;
										  state_next = RESTORE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
										  $display("26");
									  end
								  end
								  REDUCE_RING_LOCK_A: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_IDLE;
											  prev_reduce_state_next = REDUCE_RING_LOCK_A;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("27");
										  end
										  else begin
											  reduce_state_next = REDUCE_RING_LOCK_A_R;
											  prev_reduce_state_next = REDUCE_RING_LOCK_A;
											  state_next = WAIT_PAYLOAD;
											  $display("28");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_RING_LOCK_A_L;
										  prev_reduce_state_next = REDUCE_RING_LOCK_A;
										  state_next = WAIT_PAYLOAD;
										  $display("29");
									  end
								  end
								  REDUCE_RING_LOCK_A_R: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_RING_R;
											  prev_reduce_state_next = REDUCE_RING_LOCK_A_R;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("30");
										  end
									  end
								  end
								  REDUCE_RING_LOCK_A_L: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_RING_L;
											  prev_reduce_state_next = REDUCE_RING_LOCK_A_L;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("31");
										  end
									  end
								  end
								  REDUCE_RING_LOCK_B: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_IDLE;
											  prev_reduce_state_next = REDUCE_RING_LOCK_B;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("32");
										  end
										  else begin
											  reduce_state_next = REDUCE_RING_LOCK_B_L;
											  prev_reduce_state_next = REDUCE_RING_LOCK_B;
											  state_next = WAIT_PAYLOAD;
											  $display("33");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_RING_LOCK_B_R;
										  prev_reduce_state_next = REDUCE_RING_LOCK_B;
										  state_next = WAIT_PAYLOAD;
										  $display("34");
									  end
								  end
								  REDUCE_RING_LOCK_B_R: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_RING_R;
											  prev_reduce_state_next = REDUCE_RING_LOCK_B_R;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("35");
										  end
									  end
								  end
								  REDUCE_RING_LOCK_B_L: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_RING_L;
											  prev_reduce_state_next = REDUCE_RING_LOCK_B_L;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("36");
										  end
									  end
								  end
								  default: begin
									  $display("37");
								  end
							  endcase
							  
						  end// case: TOPO_RING
						  
						  TOPO_TREE: begin
							  $display("Reduce State TREE: %d \t Node_type : %d ---- %d %d %d",reduce_state, node_type_latched, pkt_is_from_cpu, pkt_is_from_A, pkt_is_from_B);
							  case(reduce_state)
								  REDUCE_IDLE: begin
									  if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_TREE_LNT: begin
												  reduce_state_next = REDUCE_TREE_LOCK_C;
												  prev_reduce_state_next = REDUCE_IDLE;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010000};
												  $display("1");
											  end
											  NODE_TREE_LT: begin
												  reduce_state_next = REDUCE_TREE_HLT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("2");
											  end
											  NODE_TREE_RT: begin
												  reduce_state_next = REDUCE_TREE_HRT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("3");
											  end
											  NODE_TREE_RNT: begin
												  reduce_state_next = REDUCE_TREE_HRNT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("4");
											  end
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_HIT;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("5");
											  end
											  NODE_TREE_ITNIS: begin
												  reduce_state_next = REDUCE_TREE_HITNIS;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("6");
											  end
											  NODE_TREE_ITILS: begin
												  reduce_state_next = REDUCE_TREE_HITILS;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("7");
											  end
											  NODE_TREE_ITIRS: begin
												  reduce_state_next = REDUCE_TREE_HITIRS;
												  prev_reduce_state_next = REDUCE_IDLE;
												  $display("8");
											  end
										  endcase
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_L;
										  prev_reduce_state_next = REDUCE_IDLE;
										  state_next = WAIT_PAYLOAD;
										  $display("9");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_R;
										  prev_reduce_state_next = REDUCE_IDLE;
										  state_next = WAIT_PAYLOAD;
										  $display("10");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_P;
										  prev_reduce_state_next = REDUCE_IDLE;
										  state_next = WAIT_PAYLOAD;
										  $display("11");
									  end
								  end
								  REDUCE_TREE_HRT: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_L_HRT;
										  prev_reduce_state_next = REDUCE_TREE_HRT;
										  $display("12");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_R_HRT;
										  prev_reduce_state_next = REDUCE_TREE_HRT;
										  $display("13");
									  end
								  end
								  REDUCE_TREE_HRNT: begin
									  state_next = UPDATE_REDUCE_MSG;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B;
										  prev_reduce_state_next = REDUCE_TREE_HRNT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
										  $display("14");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A;
										  prev_reduce_state_next = REDUCE_TREE_HRNT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
										  $display("15");
									  end
								  end
								  REDUCE_TREE_HIT: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_L_HIT;
										  prev_reduce_state_next = REDUCE_TREE_HIT;
										  $display("16");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_R_HIT;
										  prev_reduce_state_next = REDUCE_TREE_HIT;
										  $display("17");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_P_HIT;
										  prev_reduce_state_next = REDUCE_TREE_HIT;
										  $display("18");
									  end
								  end
								  REDUCE_TREE_HLT: begin	
									  if(pkt_is_from_C) begin
										  state_next = RESTORE_PKT_FIELDS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010010};
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_HLT;
										  $display("19");
									  end
								  end
								  REDUCE_TREE_HITNIS: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_L_HITNIS;
										  prev_reduce_state_next = REDUCE_TREE_HITNIS;
										  $display("20");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_R_HITNIS;
										  prev_reduce_state_next = REDUCE_TREE_HITNIS;
										  $display("21");
									  end
								  end
								  REDUCE_TREE_HITILS: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_R_HITILS;
										  prev_reduce_state_next = REDUCE_TREE_HITILS;
										  $display("22");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_P_HITILS;
										  prev_reduce_state_next = REDUCE_TREE_HITILS;
										  $display("23");
									  end
								  end
								  REDUCE_TREE_HITIRS: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_L_HITIRS;
										  prev_reduce_state_next = REDUCE_TREE_HITIRS;
										  $display("24");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_P_HITIRS;
										  prev_reduce_state_next = REDUCE_TREE_HITIRS;
										  $display("25");
									  end
								  end
								  REDUCE_TREE_L: begin
									  if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_TREE_RT: begin
												  reduce_state_next = REDUCE_TREE_L_HRT;
												  prev_reduce_state_next = REDUCE_TREE_L;
												  $display("26");
											  end
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_L_HIT;
												  prev_reduce_state_next = REDUCE_TREE_L;
												  $display("27");
											  end
											  NODE_TREE_RNT: begin
												  reduce_state_next = REDUCE_TREE_LOCK_B;
												  prev_reduce_state_next = REDUCE_TREE_L;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
												  $display("28");
											  end
											  NODE_TREE_ITNIS: begin
												  reduce_state_next = REDUCE_TREE_L_HITNIS;
												  prev_reduce_state_next = REDUCE_TREE_L;
												  $display("29");
											  end
											  NODE_TREE_ITIRS: begin
												  reduce_state_next = REDUCE_TREE_L_HITIRS;
												  prev_reduce_state_next = REDUCE_TREE_L;
												  $display("30");
											  end
										  endcase
									  end
									  else if(pkt_is_from_B) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_RL;
										  prev_reduce_state_next = REDUCE_TREE_L;
										  $display("31");
									  end
									  else if(pkt_is_from_C) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PL;
										  prev_reduce_state_next = REDUCE_TREE_L;
										  $display("32");
									  end
								  end
								  REDUCE_TREE_R: begin
									  if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_TREE_RT: begin
												  reduce_state_next = REDUCE_TREE_R_HRT;
												  prev_reduce_state_next = REDUCE_TREE_R;
												  $display("33");
											  end
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_R_HIT;
												  prev_reduce_state_next = REDUCE_TREE_R;
												  $display("34");
											  end
											  NODE_TREE_RNT: begin
												  reduce_state_next = REDUCE_TREE_LOCK_A;
												  prev_reduce_state_next = REDUCE_TREE_R;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
												  $display("35");
											  end
											  NODE_TREE_ITNIS: begin
												  reduce_state_next = REDUCE_TREE_R_HITNIS;
												  prev_reduce_state_next = REDUCE_TREE_R;
												  $display("36");
											  end
											  NODE_TREE_ITILS: begin
												  reduce_state_next = REDUCE_TREE_R_HITILS;
												  prev_reduce_state_next = REDUCE_TREE_R;
												  $display("37");
											  end
										  endcase
									  end
									  else if(pkt_is_from_A) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_RL;
										  prev_reduce_state_next = REDUCE_TREE_R;
										  $display("38");
									  end
									  else if(pkt_is_from_C) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PR;
										  prev_reduce_state_next = REDUCE_TREE_R;
										  $display("39");
									  end
								  end
								  REDUCE_TREE_P: begin
									  if(pkt_is_from_cpu) begin
										  state_next = STORE_PKT_FIELDS;
										  case(node_type_latched)
											  NODE_TREE_LT: begin
												  reduce_state_next = REDUCE_IDLE;
												  prev_reduce_state_next = REDUCE_TREE_P;
												  state_next = REVERSE_PKT_FIELDS;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010010};
												  $display("40");
											  end
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_P_HIT;
												  prev_reduce_state_next = REDUCE_TREE_P;
												  $display("41");
											  end
											  NODE_TREE_ITIRS: begin
												  reduce_state_next = REDUCE_TREE_P_HITIRS;
												  prev_reduce_state_next = REDUCE_TREE_P;
												  $display("42");
											  end
											  NODE_TREE_ITILS: begin
												  reduce_state_next = REDUCE_TREE_P_HITILS;
												  prev_reduce_state_next = REDUCE_TREE_P;
												  $display("43");
											  end
										  endcase
									  end
									  else if(pkt_is_from_A) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PL;
										  prev_reduce_state_next = REDUCE_TREE_P;
										  $display("44");
									  end
									  else if(pkt_is_from_B) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PR;
										  prev_reduce_state_next = REDUCE_TREE_P;
										  $display("45");
									  end
								  end
								  REDUCE_TREE_RL: begin
									  if(pkt_is_from_cpu) begin
										  case(node_type_latched)
											  NODE_TREE_RT: begin
												  reduce_state_next = REDUCE_IDLE;
												  prev_reduce_state_next = REDUCE_TREE_RL;
												  state_next = REVERSE_PKT_FIELDS;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
												  $display("46");
											  end
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_RL_HIT;
												  prev_reduce_state_next = REDUCE_TREE_RL;
												  state_next = STORE_PKT_FIELDS;
												  $display("47");
											  end
											  NODE_TREE_ITNIS: begin
												  state_next = STORE_PKT_FIELDS;
												  reduce_state_next = REDUCE_TREE_LOCK_C;
												  prev_reduce_state_next = REDUCE_TREE_RL;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
												  $display("48");
											  end
										  endcase
									  end
									  else if(pkt_is_from_C) begin
										  state_next = WAIT_PAYLOAD;
										  prev_reduce_state_next = REDUCE_TREE_RL;
										  reduce_state_next = REDUCE_TREE_PRL;
										  $display("49");
									  end
								  end
								  REDUCE_TREE_PL: begin	
									  if(pkt_is_from_cpu) begin
										  case(node_type_latched)
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_PL_HIT;
												  prev_reduce_state_next = REDUCE_TREE_PL;
												  state_next = STORE_PKT_FIELDS;
												  $display("50");
											  end
											  NODE_TREE_ITIRS: begin
												  state_next = STORE_PKT_FIELDS;
												  reduce_state_next = REDUCE_TREE_LOCK_B;
												  prev_reduce_state_next = REDUCE_TREE_PL;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
												  $display("51");
											  end
										  endcase
									  end
									  else if(pkt_is_from_B) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PRL;
										  prev_reduce_state_next = REDUCE_TREE_PL;
										  $display("52");
									  end
								  end
								  REDUCE_TREE_PR: begin
									  if(pkt_is_from_cpu) begin
										  case(node_type_latched)
											  NODE_TREE_IT: begin
												  reduce_state_next = REDUCE_TREE_PR_HIT;
												  prev_reduce_state_next = REDUCE_TREE_PR;
												  state_next = STORE_PKT_FIELDS;
												  $display("53");
											  end
											  NODE_TREE_ITILS: begin
												  state_next = STORE_PKT_FIELDS;
												  reduce_state_next = REDUCE_TREE_LOCK_A;
												  prev_reduce_state_next = REDUCE_TREE_PR;
												  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
												  $display("54");
											  end
										  endcase
									  end
									  else if(pkt_is_from_A) begin
										  state_next = WAIT_PAYLOAD;
										  reduce_state_next = REDUCE_TREE_PRL;
										  prev_reduce_state_next = REDUCE_TREE_PR;
										  $display("55");
									  end
								  end
								  REDUCE_TREE_PRL: begin
									  if(pkt_is_from_cpu && node_type_latched == NODE_TREE_IT) begin
										  state_next = REVERSE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_PRL;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010111};
										  $display("56");
									  end
								  end
								  REDUCE_TREE_L_HRT: begin
									  if(pkt_is_from_B) begin
										  state_next = RESTORE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_L_HRT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
										  $display("57");
									  end
								  end
								  REDUCE_TREE_L_HIT: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_RL_HIT;
										  prev_reduce_state_next = REDUCE_TREE_L_HIT;
										  $display("58");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_PL_HIT;
										  prev_reduce_state_next = REDUCE_TREE_L_HIT;
										  $display("59");
									  end
								  end
								  REDUCE_TREE_L_HITNIS: begin
									  if(pkt_is_from_B) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_C;
										  prev_reduce_state_next = REDUCE_TREE_L_HITNIS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("60");
									  end
								  end
								  REDUCE_TREE_L_HITIRS: begin
									  if(pkt_is_from_C) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_B;
										  prev_reduce_state_next = REDUCE_TREE_L_HITIRS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("61");
									  end
								  end
								  REDUCE_TREE_R_HRT: begin
									  if(pkt_is_from_A) begin
										  state_next = RESTORE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_R_HRT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
										  $display("62");
									  end
								  end
								  REDUCE_TREE_R_HIT	: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_RL_HIT;
										  prev_reduce_state_next = REDUCE_TREE_R_HIT;
										  $display("63");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_PR_HIT;
										  prev_reduce_state_next = REDUCE_TREE_R_HIT;
										  $display("64");
									  end
								  end
								  REDUCE_TREE_R_HITNIS: begin
									  if(pkt_is_from_A) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_C;
										  prev_reduce_state_next = REDUCE_TREE_R_HITNIS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("65");
									  end
								  end
								  REDUCE_TREE_R_HITILS: begin
									  if(pkt_is_from_C) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_A;
										  prev_reduce_state_next = REDUCE_TREE_R_HITILS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("66");
									  end
								  end
								  REDUCE_TREE_P_HIT: begin
									  state_next = WAIT_PAYLOAD;
									  if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_PL_HIT;
										  prev_reduce_state_next = REDUCE_TREE_P_HIT;
										  $display("67");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_PR_HIT;
										  prev_reduce_state_next = REDUCE_TREE_P_HIT;
										  $display("68");
									  end
								  end
								  REDUCE_TREE_P_HITILS: begin
									  if(pkt_is_from_B) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_A;
										  prev_reduce_state_next = REDUCE_TREE_P_HITILS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("69");
									  end
								  end
								  REDUCE_TREE_P_HITIRS: begin
									  if(pkt_is_from_A) begin
										  state_next = UPDATE_REDUCE_MSG;
										  reduce_state_next = REDUCE_TREE_LOCK_B;
										  prev_reduce_state_next = REDUCE_TREE_P_HITIRS;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010101};
										  $display("70");
									  end
								  end
								  REDUCE_TREE_PR_HIT: begin
									  if(pkt_is_from_A) begin
										  state_next = RESTORE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_PR_HIT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010111};
										  $display("71");
									  end
								  end
								  REDUCE_TREE_PL_HIT: begin
									  if(pkt_is_from_B) begin
										  state_next = RESTORE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_PL_HIT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010111};
										  $display("72");
									  end
								  end
								  REDUCE_TREE_RL_HIT: begin
									  if(pkt_is_from_C) begin
										  state_next = RESTORE_PKT_FIELDS;
										  reduce_state_next = REDUCE_IDLE;
										  prev_reduce_state_next = REDUCE_TREE_RL_HIT;
										  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00010111};
										  $display("73");
									  end
								  end
								  REDUCE_TREE_LOCK_A: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_IDLE;
											  state_next = RESTORE_PKT_FIELDS;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("74");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_A_L;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A;
											  state_next = WAIT_PAYLOAD;
											  $display("75");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_R;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A;
										  state_next = WAIT_PAYLOAD;
										  $display("76");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_P;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A;
										  state_next = WAIT_PAYLOAD;
										  $display("77");
									  end
								  end
								  REDUCE_TREE_LOCK_A_P: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_P;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_P;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("78");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_A_PL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_P;
											  state_next = WAIT_PAYLOAD;
											  $display("79");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_PR;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_P;
										  state_next = WAIT_PAYLOAD;
										  $display("80");
									  end
								  end
								  REDUCE_TREE_LOCK_A_L: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_L;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_L;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("81");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_RL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_L;
										  state_next = WAIT_PAYLOAD;
										  $display("82");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_PL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_L;
										  state_next = WAIT_PAYLOAD;
										  $display("83");
									  end
								  end
								  REDUCE_TREE_LOCK_A_R: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_R;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_R;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("84");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_A_RL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_R;
											  state_next = WAIT_PAYLOAD;
											  $display("85");
										  end
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_PR;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_R;
										  state_next = WAIT_PAYLOAD;
										  $display("86");
									  end
								  end
								  REDUCE_TREE_LOCK_A_PL: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_PL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("87");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_PL;
										  state_next = WAIT_PAYLOAD;
										  $display("88");
									  end
								  end
								  REDUCE_TREE_LOCK_A_PR: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PR;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_PR;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("89");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_A_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_PR;
											  state_next = WAIT_PAYLOAD;
											  $display("90");
										  end
									  end
								  end
								  REDUCE_TREE_LOCK_A_RL: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_RL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_RL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("91");
										  end
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_A_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_A_RL;
										  state_next = WAIT_PAYLOAD;
										  $display("92");
									  end
								  end
								  REDUCE_TREE_LOCK_A_PRL: begin
									  if(pkt_is_from_A) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_A_PRL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("93");
										  end
									  end
								  end
								  REDUCE_TREE_LOCK_B: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_IDLE;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("94");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_B_R;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B;
											  state_next = WAIT_PAYLOAD;
											  $display("95");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_L;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B;
										  state_next = WAIT_PAYLOAD;
										  $display("96");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_P;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B;
										  state_next = WAIT_PAYLOAD;
										  $display("97");
									  end
								  end
								  REDUCE_TREE_LOCK_B_P: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_P;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_P;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("98");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_B_PR;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_P;
											  state_next = WAIT_PAYLOAD;
											  $display("99");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_PL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_P;
										  state_next = WAIT_PAYLOAD;
										  $display("100");
									  end
								  end
								  REDUCE_TREE_LOCK_B_L: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_L;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_L;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("101");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_B_RL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_L;
											  state_next = WAIT_PAYLOAD;
											  $display("102");
										  end
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_PL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_L;
										  state_next = WAIT_PAYLOAD;
										  $display("103");
									  end
								  end
								  REDUCE_TREE_LOCK_B_R: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_R;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_R;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("104");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_RL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_R;
										  state_next = WAIT_PAYLOAD;
										  $display("105");
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_PR;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_R;
										  state_next = WAIT_PAYLOAD;
										  $display("106");
									  end
								  end
								  REDUCE_TREE_LOCK_B_PL: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_PL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("107");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_B_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_PL;
											  state_next = WAIT_PAYLOAD;
											  $display("108");
										  end
									  end
								  end
								  REDUCE_TREE_LOCK_B_PR: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PR;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_PR;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("109");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_PR;
										  state_next = WAIT_PAYLOAD;
										  $display("110");
									  end
								  end
								  REDUCE_TREE_LOCK_B_RL: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_RL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_RL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("111");
										  end
									  end
									  else if(pkt_is_from_C) begin
										  reduce_state_next = REDUCE_TREE_LOCK_B_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_B_RL;
										  state_next = WAIT_PAYLOAD;
										  $display("112");
									  end
								  end
								  REDUCE_TREE_LOCK_B_PRL: begin
									  if(pkt_is_from_B) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_B_PRL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("113");
										  end
									  end
								  end
								  REDUCE_TREE_LOCK_C: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_IDLE;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("114");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_C_P;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C;
											  state_next = WAIT_PAYLOAD;
											  $display("115");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_L;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C;
										  state_next = WAIT_PAYLOAD;
										  $display("116");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_R;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C;
										  state_next = WAIT_PAYLOAD;
										  $display("117");
									  end
								  end
								  REDUCE_TREE_LOCK_C_P: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_P;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_P;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("118");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_PL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_P;
										  state_next = WAIT_PAYLOAD;
										  $display("119");
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_PR;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_P;
										  state_next = WAIT_PAYLOAD;
										  $display("120");
									  end
								  end
								  REDUCE_TREE_LOCK_C_L: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_L;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_L;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("121");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_C_PL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_L;
											  state_next = WAIT_PAYLOAD;
											  $display("122");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_RL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_L;
										  state_next = WAIT_PAYLOAD;
										  $display("123");
									  end
								  end
								  REDUCE_TREE_LOCK_C_R: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_R;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_R;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("124");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_C_PR;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_R;
											  state_next = WAIT_PAYLOAD;
											  $display("125");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_RL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_R;
										  state_next = WAIT_PAYLOAD;
										  $display("126");
									  end
								  end
								  REDUCE_TREE_LOCK_C_PL: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_PL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("127");
										  end
									  end
									  else if(pkt_is_from_B) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_PL;
										  state_next = WAIT_PAYLOAD;
										  $display("128");
									  end
								  end
								  REDUCE_TREE_LOCK_C_PR: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PR;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_PR;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("129");
										  end
									  end
									  else if(pkt_is_from_A) begin
										  reduce_state_next = REDUCE_TREE_LOCK_C_PRL;
										  prev_reduce_state_next = REDUCE_TREE_LOCK_C_PR;
										  state_next = WAIT_PAYLOAD;
										  $display("130");
									  end
								  end
								  REDUCE_TREE_LOCK_C_RL: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_RL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_RL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("131");
										  end
										  else begin
											  reduce_state_next = REDUCE_TREE_LOCK_C_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_RL;
											  state_next = WAIT_PAYLOAD;
											  $display("132");
										  end
									  end
								  end
								  REDUCE_TREE_LOCK_C_PRL: begin
									  if(pkt_is_from_C) begin
										  if(message_latched == MSG_RLS_REDUCE) begin
											  reduce_state_next = REDUCE_TREE_PRL;
											  prev_reduce_state_next = REDUCE_TREE_LOCK_C_PRL;
											  state_next = RESTORE_PKT_FIELDS;
											  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
											  $display("133");
										  end
									  end
								  end
								  default: begin
								  end
							  endcase
						  end

						  default: begin
							  state_next = WAIT_PAYLOAD;
						  end
					  endcase
				  end // if (reduce_pkt && !not_reduce_pkt && in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM)	      
				  //regular ethernet NIC traffic
				  else if(!reduce_pkt && not_reduce_pkt) begin
					  if(in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
						  if(pkt_is_from_cpu) begin		    					 
							  out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = {1'b0, decoded_src[15:1]};
						  end
						  else begin
							  out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = {decoded_src[14:0], 1'b0};
						  end
					  end
					  state_next = WAIT_EOP;
					  $display("WAIT_EOP'ye gececek 1");
				  end	
				  //contingency case, packet is dropped since not classified.
				  else begin 
					  if(in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
						  out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = 0;
					  end
					  state_next = WAIT_EOP;
					  $display("WAIT_EOP'ye gececek 2");
				  end
			  end
		  end
		  
		  
		  
		  STORE_PKT_FIELDS: begin
			  if(in_fifo_ctrl_dout!=255 & out_rdy) begin
				  out_wr = 1;
				  word_count_next = word_count+1;
				  $display("STORE_PKT_FIELDS : %d", word_count);
				  if(word_count == 0) begin
					  src_mac_next[47:32] = in_fifo_data_dout[15:0];
					  dst_mac_next = in_fifo_data_dout[63:16];
				  end
				  
				  if(word_count == 1) begin
					  src_mac_next[31:0] = in_fifo_data_dout[63:32];
				  end
				  
				  if(word_count == 3) begin
					  src_ip_next = in_fifo_data_dout[47:16];
					  dst_ip_next[31:16] = in_fifo_data_dout[15:0];
					  ip_cksum_next = in_fifo_data_dout[63:48];
				  end
				  
				  if(word_count == 4) begin
					  dst_ip_next[15:0] = in_fifo_data_dout[63:48];
					  udp_src_next = in_fifo_data_dout[47:32];
					  udp_dst_next = in_fifo_data_dout[31:16];
					  if(reduce_state == REDUCE_RING_LOCK_A || reduce_state == REDUCE_RING_LOCK_B ||
					  	 reduce_state == REDUCE_TREE_LOCK_A || reduce_state == REDUCE_TREE_LOCK_B || reduce_state == REDUCE_TREE_LOCK_C ) begin
						  state_next = UPDATE_REDUCE_MSG;
					  end
					  else begin
						  state_next = WAIT_PAYLOAD;
					  end
				  end
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
			  end
		  end
		  
		  RESTORE_PKT_FIELDS: begin
			  if(in_fifo_ctrl_dout!=255 & out_rdy) begin
				  out_wr = 1;
				  word_count_next = word_count+1;
				  $display("RESTORE_PKT_FIELDS : %d", word_count);
				  if(word_count == 0) begin
					  out_data = {src_mac,dst_mac[47:32]};
				  end
				  
				  if(word_count == 1) begin
					  out_data[63:32] = dst_mac[31:0];
				  end
				  
				  if(word_count == 3) begin
					  out_data = {ip_cksum, dst_ip,src_ip[31:16]};
				  end
				  
				  if(word_count == 4) begin
					  out_data[63:16] = {src_ip[15:0],udp_dst,udp_src};
					  state_next = UPDATE_REDUCE_MSG;
				  end
				  
				  
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
			  end
		  end
				  
		  REVERSE_PKT_FIELDS: begin
			  if(in_fifo_ctrl_dout!=255 & out_rdy) begin
				  out_wr = 1;
				  word_count_next = word_count+1;
				  $display("REVERSE_PKT_FIELDS : %d", word_count);
				  if(word_count == 0) begin
					  out_data = {src_mac_cur,dst_mac_cur[47:32]};
				  end
				  
				  if(word_count == 1) begin
					  out_data[63:32] = dst_mac_cur[31:0];
				  end
				  
				  if(word_count == 3) begin
					  out_data = {ip_cksum_cur, dst_ip_cur,src_ip_cur[31:16]};
				  end
				  
				  if(word_count == 4) begin
					  out_data[63:16] = {src_ip_cur[15:0],udp_dst_cur,udp_src_cur};
					  state_next = UPDATE_REDUCE_MSG;
				  end
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
			  end
		  end
		  
		  UPDATE_REDUCE_MSG: begin
			  if(in_fifo_ctrl_dout!=255 & out_rdy) begin
				  out_wr = 1;
				  $display("UPDATE_REDUCE_MSG : %d", word_count);
				  word_count_next = word_count + 1;
				  if(word_count == 5) begin
					  out_data[63:48] = 0;
					  case(topo_type_latched)
						  TOPO_RING: begin
							  state_next = WAIT_PAYLOAD;
							  if( node_type_latched != NODE_RING ) begin
								  out_data[7:0] = NODE_RING;
								  $display("Node type is changed to generic type");
							  end
							  
							  if( message_latched == MSG_RLS_REDUCE) begin
								  out_data[47:32] = 0;
								  $display("Release message is cleared");
							  end
							  
							  if( (reduce_state == REDUCE_IDLE || reduce_state == REDUCE_RING_LOCK_A || reduce_state == REDUCE_RING_LOCK_B) &&
							      node_type_latched != NODE_RING_ELNT && node_type_latched != NODE_RING_ERNT ) begin
								  out_data[47:32] = MSG_RLS_REDUCE;
								  $display("Release message is tagged");
							  end							  	
						  end
						  TOPO_TREE: begin
							  state_next = WAIT_PAYLOAD;
							  if( node_type_latched != NODE_TREE ) begin
								  out_data[7:0] = NODE_TREE;
								  $display("Node type is changed to generic type");
							  end
							  
							  if( message_latched == MSG_RLS_REDUCE) begin
								  out_data[47:32] = 0;
								  $display("Release message is cleared");
							  end
							  
							  if( (reduce_state == REDUCE_IDLE || reduce_state == REDUCE_TREE_LOCK_A || reduce_state == REDUCE_TREE_LOCK_B || reduce_state == REDUCE_TREE_LOCK_C) &&
							      node_type_latched != NODE_TREE_LNT ) begin
								  out_data[47:32] = MSG_RLS_REDUCE;
								  $display("Release message is tagged");
							  end
							  	
						  end
						  default: begin
							  word_count_next = 0;
							  state_next = WAIT_EOP;
							  $display("WAIT_EOP'ye gececek 3");
						  end
					  endcase
				  end
				  
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
			  end
		  end
		  
		  WAIT_PAYLOAD: begin
			  if(in_fifo_ctrl_dout!=255 & out_rdy) begin
				  out_wr = 1;
				   $display("WAIT_PAYLOAD : %d", word_count);
				  if(word_count==7) begin
					  word_count_next = 0;
					  buffer_rd_addr_next = 0;
					  buffer_wr_addr_next = 0;
					  //buffer_wr_en_next = 1;
					  state_next = CASH_PACKET;
				  end
				  else begin
					  word_count_next = word_count+1;
				  end			   
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
			  end	   
		  end	
		  
		  // write all data 
		  CASH_PACKET: begin
			  if(in_fifo_ctrl_dout!=0)begin
				  if(out_rdy) begin
					  state_next   = WAIT_TILL_DONE_DECODE;
					  word_count_next = 0;
					  out_wr       = 1;
					  buffer_wr_en_next = 1;
					  $display("CASH_PACKET last : %d", word_count);
					  case(topo_type_latched)
						  TOPO_RING: begin
							  if( reduce_state == REDUCE_RING_RL || reduce_state == REDUCE_RING_L_HIT || reduce_state == REDUCE_RING_R_HIT || 
							  	  (reduce_state == REDUCE_RING_LOCK_B && node_type_latched != NODE_RING_ERNT) || 
							  	  (reduce_state == REDUCE_RING_LOCK_A && node_type_latched != NODE_RING_ELNT) || reduce_state == REDUCE_IDLE) begin
								  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
								  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  $display("CASH_PACKET last 1 : %d %x %x %x", word_count, buffer_wr_data_next, in_fifo_data_dout, buffer_rd_data);
							  end
							  if(((reduce_state == REDUCE_RING_R && (prev_reduce_state == REDUCE_RING_LOCK_A_R || prev_reduce_state == REDUCE_RING_LOCK_B_R)) || 
							      (reduce_state == REDUCE_RING_L && (prev_reduce_state == REDUCE_RING_LOCK_A_L || prev_reduce_state == REDUCE_RING_LOCK_B_L))) && 
							  	 message_latched == MSG_RLS_REDUCE) begin
								  buffer_wr_data_next = buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  out_data = buffer_rd_data;
								  buffer_wr_en_next = 0;
								  $display("CASH_PACKET last 2 : %d", word_count);
							  end
						  end
						  TOPO_TREE: begin
							  if(((reduce_state == REDUCE_TREE_R && (prev_reduce_state == REDUCE_TREE_LOCK_A_R || prev_reduce_state == REDUCE_TREE_LOCK_B_R || prev_reduce_state == REDUCE_TREE_LOCK_C_R))  || 
							  	  (reduce_state == REDUCE_TREE_L && (prev_reduce_state == REDUCE_TREE_LOCK_A_L || prev_reduce_state == REDUCE_TREE_LOCK_B_L || prev_reduce_state == REDUCE_TREE_LOCK_C_L))  ||
							  	  (reduce_state == REDUCE_TREE_P && (prev_reduce_state == REDUCE_TREE_LOCK_A_P || prev_reduce_state == REDUCE_TREE_LOCK_B_P || prev_reduce_state == REDUCE_TREE_LOCK_C_P))  ||
							  	  (reduce_state == REDUCE_TREE_PR && (prev_reduce_state == REDUCE_TREE_LOCK_A_PR || prev_reduce_state == REDUCE_TREE_LOCK_B_PR || prev_reduce_state == REDUCE_TREE_LOCK_C_PR))  ||
							  	  (reduce_state == REDUCE_TREE_PL && (prev_reduce_state == REDUCE_TREE_LOCK_A_PL || prev_reduce_state == REDUCE_TREE_LOCK_B_PL || prev_reduce_state == REDUCE_TREE_LOCK_C_PL))  ||
							  	  (reduce_state == REDUCE_TREE_RL && (prev_reduce_state == REDUCE_TREE_LOCK_A_RL || prev_reduce_state == REDUCE_TREE_LOCK_B_RL || prev_reduce_state == REDUCE_TREE_LOCK_C_RL))  ||
							  	  (reduce_state == REDUCE_TREE_PRL && (prev_reduce_state == REDUCE_TREE_LOCK_A_PRL || prev_reduce_state == REDUCE_TREE_LOCK_B_PRL || prev_reduce_state == REDUCE_TREE_LOCK_C_PRL))) &&
							      message_latched == MSG_RLS_REDUCE ) begin
								  buffer_wr_data_next = buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  out_data = buffer_rd_data;
								  buffer_wr_en_next = 0;
								  $display("CASH_PACKET last 2 : %d", word_count);
							  end
							  else if( reduce_state ==  REDUCE_TREE_RL ||
							      reduce_state ==  REDUCE_TREE_PL ||
							      reduce_state ==  REDUCE_TREE_PR ||
							      reduce_state ==  REDUCE_TREE_PRL ||
							      reduce_state ==  REDUCE_TREE_L_HRT ||
							      reduce_state ==  REDUCE_TREE_L_HIT ||
							      reduce_state ==  REDUCE_TREE_L_HITNIS ||
							      reduce_state ==  REDUCE_TREE_L_HITIRS ||
							      reduce_state ==  REDUCE_TREE_R_HRT ||
							      reduce_state ==  REDUCE_TREE_R_HIT ||
							      reduce_state ==  REDUCE_TREE_R_HITNIS ||
							      reduce_state ==  REDUCE_TREE_R_HITILS ||
							      reduce_state ==  REDUCE_TREE_P_HIT ||
							      reduce_state ==  REDUCE_TREE_P_HITILS ||
							      reduce_state ==  REDUCE_TREE_P_HITIRS ||
							      reduce_state ==  REDUCE_TREE_PR_HIT ||
							      reduce_state ==  REDUCE_TREE_PL_HIT ||
							      reduce_state ==  REDUCE_TREE_RL_HIT ||
							      (reduce_state == REDUCE_TREE_LOCK_C && node_type_latched != NODE_TREE_LNT) ||
							      reduce_state ==  REDUCE_TREE_LOCK_A ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PRL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PRL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PRL ||
							      reduce_state == REDUCE_IDLE) begin
								  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
								  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  $display("CASH_PACKET last 1 : %d %x %x %x", word_count, buffer_wr_data_next, in_fifo_data_dout, buffer_rd_data);
							  end
							  
						  end
					  endcase
							  
						 
					  
					  buffer_wr_addr_next = buffer_wr_addr_next+1;
					  //$display("2 buffer_rd_data : %x \t buffer_wr_data : %x \t wr_ptr : %d \t rd_ptr : %d",buffer_rd_data,buffer_wr_data,buffer_wr_addr,buffer_rd_addr);
					  //$display("2 out_data : %x \t in_data : %x",out_data,in_fifo_data_dout);
				  end
			  end
			  else if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  out_wr          = 1;
				  buffer_wr_en_next = 1;
				  $display("CASH_PACKET : %d", word_count);
				  case(topo_type_latched)
						  TOPO_RING: begin
							  if( reduce_state == REDUCE_RING_RL || reduce_state == REDUCE_RING_L_HIT || reduce_state == REDUCE_RING_R_HIT || 
							  	  (reduce_state == REDUCE_RING_LOCK_B && node_type_latched != NODE_RING_ERNT) || 
							  	  (reduce_state == REDUCE_RING_LOCK_A && node_type_latched != NODE_RING_ELNT) || reduce_state == REDUCE_IDLE) begin
								  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
								  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  $display("CASH_PACKET 1 : %d %x %x %x", word_count, buffer_wr_data_next, in_fifo_data_dout, buffer_rd_data);
							  end
							  if(((reduce_state == REDUCE_RING_R && (prev_reduce_state == REDUCE_RING_LOCK_A_R || prev_reduce_state == REDUCE_RING_LOCK_B_R)) || 
							      (reduce_state == REDUCE_RING_L && (prev_reduce_state == REDUCE_RING_LOCK_A_L || prev_reduce_state == REDUCE_RING_LOCK_B_L))) && 
							  	 message_latched == MSG_RLS_REDUCE) begin
								  buffer_wr_data_next = buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  out_data = buffer_rd_data;
								  buffer_wr_en_next = 0;
								  $display("CASH_PACKET 2 : %d", word_count);
							  end
						  end
						  TOPO_TREE: begin
							  if(((reduce_state == REDUCE_TREE_R && (prev_reduce_state == REDUCE_TREE_LOCK_A_R || prev_reduce_state == REDUCE_TREE_LOCK_B_R || prev_reduce_state == REDUCE_TREE_LOCK_C_R))  || 
							  	  (reduce_state == REDUCE_TREE_L && (prev_reduce_state == REDUCE_TREE_LOCK_A_L || prev_reduce_state == REDUCE_TREE_LOCK_B_L || prev_reduce_state == REDUCE_TREE_LOCK_C_L))  ||
							  	  (reduce_state == REDUCE_TREE_P && (prev_reduce_state == REDUCE_TREE_LOCK_A_P || prev_reduce_state == REDUCE_TREE_LOCK_B_P || prev_reduce_state == REDUCE_TREE_LOCK_C_P))  ||
							  	  (reduce_state == REDUCE_TREE_PR && (prev_reduce_state == REDUCE_TREE_LOCK_A_PR || prev_reduce_state == REDUCE_TREE_LOCK_B_PR || prev_reduce_state == REDUCE_TREE_LOCK_C_PR))  ||
							  	  (reduce_state == REDUCE_TREE_PL && (prev_reduce_state == REDUCE_TREE_LOCK_A_PL || prev_reduce_state == REDUCE_TREE_LOCK_B_PL || prev_reduce_state == REDUCE_TREE_LOCK_C_PL))  ||
							  	  (reduce_state == REDUCE_TREE_RL && (prev_reduce_state == REDUCE_TREE_LOCK_A_RL || prev_reduce_state == REDUCE_TREE_LOCK_B_RL || prev_reduce_state == REDUCE_TREE_LOCK_C_RL))  ||
							  	  (reduce_state == REDUCE_TREE_PRL && (prev_reduce_state == REDUCE_TREE_LOCK_A_PRL || prev_reduce_state == REDUCE_TREE_LOCK_B_PRL || prev_reduce_state == REDUCE_TREE_LOCK_C_PRL))) &&
							      message_latched == MSG_RLS_REDUCE ) begin
								  buffer_wr_data_next = buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  out_data = buffer_rd_data;
								  buffer_wr_en_next = 0;
								  $display("CASH_PACKET 2 : %d", word_count);
							  end
							  else if( reduce_state ==  REDUCE_TREE_RL ||
							      reduce_state ==  REDUCE_TREE_PL ||
							      reduce_state ==  REDUCE_TREE_PR ||
							      reduce_state ==  REDUCE_TREE_PRL ||
							      reduce_state ==  REDUCE_TREE_L_HRT ||
							      reduce_state ==  REDUCE_TREE_L_HIT ||
							      reduce_state ==  REDUCE_TREE_L_HITNIS ||
							      reduce_state ==  REDUCE_TREE_L_HITIRS ||
							      reduce_state ==  REDUCE_TREE_R_HRT ||
							      reduce_state ==  REDUCE_TREE_R_HIT ||
							      reduce_state ==  REDUCE_TREE_R_HITNIS ||
							      reduce_state ==  REDUCE_TREE_R_HITILS ||
							      reduce_state ==  REDUCE_TREE_P_HIT ||
							      reduce_state ==  REDUCE_TREE_P_HITILS ||
							      reduce_state ==  REDUCE_TREE_P_HITIRS ||
							      reduce_state ==  REDUCE_TREE_PR_HIT ||
							      reduce_state ==  REDUCE_TREE_PL_HIT ||
							      reduce_state ==  REDUCE_TREE_RL_HIT ||
							      (reduce_state == REDUCE_TREE_LOCK_C && node_type_latched != NODE_TREE_LNT) ||
							      reduce_state ==  REDUCE_TREE_LOCK_A ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_A_PRL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_B_PRL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PR ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_RL ||
							      reduce_state ==  REDUCE_TREE_LOCK_C_PRL ||
							      reduce_state == REDUCE_IDLE) begin
								  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
								  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
								  buffer_rd_addr_next = buffer_rd_addr_next+1;
								  $display("CASH_PACKET 1 : %d %x %x %x", word_count, buffer_wr_data_next, in_fifo_data_dout, buffer_rd_data);
							  end
							  
						  end
					  endcase
				  
				  buffer_wr_addr_next = buffer_wr_addr_next+1;	      
				  //$display("1 buffer_rd_data : %x \t buffer_wr_data : %x \t wr_ptr : %d \t rd_ptr : %d",buffer_rd_data,buffer_wr_data,buffer_wr_addr,buffer_rd_addr); 
				  //$display("1 out_data :	 %x \t in_data :	%x",out_data,in_fifo_data_dout);
			  end
		  end // case: CASH_PACKET
		  
		  // write all data
		  WAIT_EOP: begin
			  if(in_fifo_ctrl_dout!=0)begin
				  if(out_rdy) begin
					  word_count_next = 0;
					  state_next   = WAIT_TILL_DONE_DECODE;
					  out_wr       = 1;
					  $display("WAIT_EOP last: %d", word_count);
				  end
			  end
			  else if(!in_fifo_empty & out_rdy) begin
				  word_count_next = 0;
				  in_fifo_rd_en   = 1;
				  out_wr          = 1;
				  $display("WAIT_EOP : %d", word_count);
			  end
		  end // case: WAIT_EOP
	  endcase // case(state)
   end // always @ (*)
   
   always @(posedge clk) begin
	   if(reset) begin
		   state	      	<= WAIT_TILL_DONE_DECODE;
		   reduce_state 	<= REDUCE_IDLE;
		   prev_reduce_state<= REDUCE_IDLE;
		   word_count    	<= 0;
		   src_ip         <= 0;
		   dst_ip         <= 0;
		   ip_cksum       <= 0;
		   src_mac        <= 0;
		   dst_mac        <= 0;
		   udp_src        <= 0;
		   udp_dst        <= 0;
		   buffer_rd_data <= 0;
		   buffer_rd_addr <= 0;
		   buffer_wr_addr <= 0;
		   buffer_wr_data <= 0;
		   buffer_wr_en   <= 0;
		   //buffer[0]      <= 0;
	   end
	   else begin
       		//$display("wr_addr : %d \t rd_addr : %d \t wr_data : %x \t rd_data : %x \t wr_en : %d",
            //       buffer_wr_addr-1, buffer_rd_addr_next, buffer_wr_data, buffer_rd_data, buffer_wr_en);
            state	       	        <= state_next;
            reduce_state 	        <= reduce_state_next;
            prev_reduce_state		<= prev_reduce_state_next;
            word_count    	        <= word_count_next;
            src_ip                 <= src_ip_next;
            dst_ip                 <= dst_ip_next;
            ip_cksum               <= ip_cksum_next;
            src_mac                <= src_mac_next;
            dst_mac                <= dst_mac_next;
            udp_src                <= udp_src_next;
            udp_dst                <= udp_dst_next;
            buffer_rd_data         <= buffer[buffer_rd_addr_next];
            buffer_rd_addr         <= buffer_rd_addr_next;
            buffer_wr_addr         <= buffer_wr_addr_next;
            buffer_wr_data         <= buffer_wr_data_next;
            buffer_wr_en           <= buffer_wr_en_next;
            //$display("wr_addr : %d \t rd_addr : %d \t wr_data : %x \t rd_data : %x \t wr_en : %d",
	        //buffer_wr_addr-1, buffer_rd_addr_next, buffer_wr_data, buffer_rd_data, buffer_wr_en);
	        if(buffer_wr_en) begin
		        buffer[buffer_wr_addr-1] <= buffer_wr_data;
		        //$display("buffer[%d] : %x",buffer_wr_addr,buffer_wr_data);
			end

	   end
   end
endmodule // switch_output_port

