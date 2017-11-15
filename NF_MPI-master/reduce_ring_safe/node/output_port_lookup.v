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
   
   
   localparam REDUCE_IDLE       = 0;
   localparam REDUCE_LR         = 1;
   localparam REDUCE_RR         = 2;
   localparam REDUCE_HR         = 3;
   localparam REDUCE_T_HR       = 4;
   localparam REDUCE_T_LHR      = 5;
   localparam REDUCE_T_RHR      = 6;
   localparam REDUCE_T_HLR      = 7;
   localparam REDUCE_T_HRR      = 8;
   localparam REDUCE_T_RLR      = 9;
   localparam REDUCE_T_LRR      = 10;
   localparam REDUCE_TE_HR      = 11;
   localparam REDUCE_LOCK_R		= 12;
   localparam REDUCE_LOCK_L		= 13;
   localparam REDUCE_R_LOCK_R	= 14;
   localparam REDUCE_L_LOCK_L	= 15;
   localparam REDUCE_LOCK_R_E	= 16;
   localparam REDUCE_LOCK_L_E	= 17;
   localparam REDUCE_RR_LOCK	= 18;
   localparam REDUCE_LR_LOCK	= 19;
   

   
   localparam TOPO_RING		   = 1;
   localparam TOPO_TREE		   = 2;
   localparam TOPO_BUTTERFLY   = 3;
   localparam TOPO_TRUNK	   = 4;
   localparam TOPO_STAR        = 5;
  
	
   localparam NODE_RING_TARGET        = 0;
   localparam NODE_RING_EDGE          = 1;
   localparam NODE_RING_INTERNAL_R    = 2;
   localparam NODE_RING_INTERNAL_L    = 3;
   localparam NODE_RING_TARGET_EDGE_L = 4;
   localparam NODE_RING_TARGET_EDGE_R = 5;




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
   reg [6:0]   					reduce_state, reduce_state_next;
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
   small_fifo #(.WIDTH(DATA_WIDTH+CTRL_WIDTH), .MAX_DEPTH_BITS(4))
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
				  if(reduce_pkt && !not_reduce_pkt && in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
					  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = 0;
					  $display("Reduce packet : %d %d %d", rank_latched, root_latched, size_latched);
					  case(topo_type_latched)
						  TOPO_RING: begin
							  //ring_topo_edge_non_target_node_state_machine
							  $display("Reduce State: %d \t Node_type : %d ---- %d %d %d",reduce_state, node_type_latched, pkt_is_from_cpu, pkt_is_from_A, pkt_is_from_B);
							  
							  if(node_type_latched == NODE_RING_EDGE && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  $display("NODE_RING_EDGE");
								  if(rank_latched < root_latched) begin
									  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000001};
									  reduce_state_next = REDUCE_LOCK_L_E;
								  end
								  else begin
									  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000100};
									  reduce_state_next = REDUCE_LOCK_R_E;
								  end
								  state_next = STORE_PKT_FIELDS;
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_B && reduce_state == REDUCE_LOCK_R_E) begin
								  $display("NODE_RING_EDGE_1");
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_A && reduce_state == REDUCE_LOCK_L_E) begin
								  $display("NODE_RING_EDGE_2");
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
							  end
							  //ring_topo_node_internal_r
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  $display("NODE_RING_EDGE_3");
								  reduce_state_next = REDUCE_HR;
								  state_next = STORE_PKT_FIELDS;
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_IDLE) begin
								  reduce_state_next = REDUCE_RR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_4");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_cpu && reduce_state == REDUCE_RR) begin
								  reduce_state_next = REDUCE_LOCK_R;
								  state_next = STORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_5");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_HR) begin
								  reduce_state_next = REDUCE_LOCK_R;
								  state_next = UPDATE_REDUCE_MSG;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_6");
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_B && reduce_state == REDUCE_LOCK_R) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  $display("NODE_RING_EDGE_7");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_LOCK_R) begin
								  reduce_state_next = REDUCE_R_LOCK_R;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_8");
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_B && reduce_state == REDUCE_R_LOCK_R) begin
								  reduce_state_next = REDUCE_RR_LOCK;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  $display("NODE_RING_EDGE_9");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_cpu && reduce_state == REDUCE_RR_LOCK) begin
								  reduce_state_next = REDUCE_LOCK_R;
								  state_next = STORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_10");
							  end
							  //ring_topo_node_internal_l
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  $display("NODE_RING_EDGE_11");
								  reduce_state_next = REDUCE_HR;
								  state_next = STORE_PKT_FIELDS;
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_IDLE) begin
								  reduce_state_next = REDUCE_LR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_12");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_cpu && reduce_state == REDUCE_LR) begin
								  reduce_state_next = REDUCE_LOCK_L;
								  state_next = STORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_13");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_HR) begin
								  reduce_state_next = REDUCE_LOCK_L;
								  state_next = UPDATE_REDUCE_MSG;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_14");
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_A && reduce_state == REDUCE_LOCK_L) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  $display("NODE_RING_EDGE_15");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_LOCK_L) begin
								  reduce_state_next = REDUCE_L_LOCK_L;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_16");
							  end
							  else if(message_latched == MSG_RLS_REDUCE && pkt_is_from_A && reduce_state == REDUCE_L_LOCK_L) begin
								  reduce_state_next = REDUCE_LR_LOCK;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000010};
								  $display("NODE_RING_EDGE_17");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_cpu && reduce_state == REDUCE_LR_LOCK) begin
								  reduce_state_next = REDUCE_LOCK_L;
								  state_next = STORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000101};
								  $display("NODE_RING_EDGE_18");
							  end
							  //ring_topo_target_edge_r
							  else if(node_type_latched == NODE_RING_TARGET_EDGE_R && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  reduce_state_next = REDUCE_TE_HR;
								  state_next = STORE_PKT_FIELDS;
								  $display("NODE_RING_EDGE_19");
							  end
							  else if(node_type_latched == NODE_RING_TARGET_EDGE_R && pkt_is_from_cpu && reduce_state == REDUCE_LR) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = REVERSE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000110};
								  $display("NODE_RING_EDGE_20");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_TE_HR) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000110};
								  $display("NODE_RING_EDGE_21");
							  end
							  //ring_topo_target_edge_l
							  else if(node_type_latched == NODE_RING_TARGET_EDGE_L && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  reduce_state_next = REDUCE_TE_HR;
								  state_next = STORE_PKT_FIELDS;
								  $display("NODE_RING_EDGE_22");
							  end
							  else if(node_type_latched == NODE_RING_TARGET_EDGE_L && pkt_is_from_cpu && reduce_state == REDUCE_RR) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = REVERSE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
								  $display("NODE_RING_EDGE_23");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_TE_HR) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
								  $display("NODE_RING_EDGE_24");
							  end
							  //ring_topo_target_internal
							  else if(node_type_latched == NODE_RING_TARGET && pkt_is_from_cpu && reduce_state == REDUCE_IDLE) begin
								  reduce_state_next = REDUCE_T_HR;
								  state_next = STORE_PKT_FIELDS;
								  $display("NODE_RING_EDGE_25");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_T_HR) begin
								  reduce_state_next = REDUCE_T_RHR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_26");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_T_HR) begin
								  reduce_state_next = REDUCE_T_LHR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_27");
							  end
							  else if(node_type_latched == NODE_RING_TARGET && pkt_is_from_cpu && reduce_state == REDUCE_LR) begin
								  reduce_state_next = REDUCE_T_HLR;
								  state_next = STORE_PKT_FIELDS;
								  $display("NODE_RING_EDGE_28");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && reduce_state == REDUCE_LR) begin
								  reduce_state_next = REDUCE_T_RLR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_29");
							  end
							  else if(node_type_latched == NODE_RING_TARGET && pkt_is_from_cpu && reduce_state == REDUCE_RR) begin
								  reduce_state_next = REDUCE_T_HRR;
								  state_next = STORE_PKT_FIELDS;
								  $display("NODE_RING_EDGE_30");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && reduce_state == REDUCE_RR) begin
								  reduce_state_next = REDUCE_T_LRR;
								  state_next = WAIT_PAYLOAD;
								  $display("NODE_RING_EDGE_31");
							  end
							  else if(node_type_latched == NODE_RING_TARGET && pkt_is_from_cpu && (reduce_state == REDUCE_T_LRR || reduce_state == REDUCE_T_RLR)) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = REVERSE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
								  $display("NODE_RING_EDGE_32");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_L && pkt_is_from_B && (reduce_state == REDUCE_T_HRR || reduce_state == REDUCE_T_RHR)) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
								  $display("NODE_RING_EDGE_33");
							  end
							  else if(node_type_latched == NODE_RING_INTERNAL_R && pkt_is_from_A && (reduce_state == REDUCE_T_HLR || reduce_state == REDUCE_T_LHR)) begin
								  reduce_state_next = REDUCE_IDLE;
								  state_next = RESTORE_PKT_FIELDS;
								  out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000111};
								  $display("NODE_RING_EDGE_34");
							  end
						  end// case: TOPO_RING
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
				  end	
				  //contingency case, packet is dropped since not classified.
				  else begin 
					  if(in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
						  out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = 0;
					  end
					  state_next = WAIT_EOP;
				  end
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
							  if( (reduce_state == REDUCE_LOCK_L_E || reduce_state == REDUCE_LOCK_R_E) && node_type_latched == NODE_RING_EDGE ) begin
								  if(rank_latched < root_latched) begin
									  out_data[7:0] = NODE_RING_INTERNAL_L;
									  $display("Node type is being changed_L");
								  end
								  else begin
									  out_data[7:0] = NODE_RING_INTERNAL_R;
									  $display("Node type is being changed_R");
								  end
								  state_next = WAIT_EOP;
							  end
							  
							  if( reduce_state == REDUCE_IDLE || reduce_state == REDUCE_LOCK_R || reduce_state == REDUCE_LOCK_L ) begin
								  out_data[47:32] = MSG_RLS_REDUCE;
								  $display("Release message is tagged");
							  end
							  
							 
							  	
						  end
						  default: begin
							  word_count_next = 0;
							  state_next = WAIT_EOP;
						  end
					  endcase
				  end
				  
			  end
			  if(!in_fifo_empty & out_rdy) begin
				  in_fifo_rd_en   = 1;
				  //out_wr          = 1;
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
					  if(reduce_state == REDUCE_LOCK_R || reduce_state == REDUCE_LOCK_L || reduce_state == REDUCE_LOCK_R_E || reduce_state == REDUCE_LOCK_L_E) begin
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
					  $display("CASH_PACKET : %d", word_count);
					  if(reduce_state != REDUCE_HR && reduce_state != REDUCE_LR && reduce_state != REDUCE_RR && reduce_state != REDUCE_T_HR && reduce_state != REDUCE_TE_HR && 
					     reduce_state != REDUCE_R_LOCK_R && reduce_state != REDUCE_L_LOCK_L ) begin
						  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
						  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
						  buffer_rd_addr_next = buffer_rd_addr_next+1;
					  end
					  
					  if(reduce_state == REDUCE_RR_LOCK && message_latched == MSG_RLS_REDUCE) begin
						  buffer_wr_data_next = buffer_rd_data;
						  buffer_rd_addr_next = buffer_rd_addr_next+1;
						  out_data = buffer_rd_data;
						  buffer_wr_en_next = 0;
					  end
					  
					  if(reduce_state == REDUCE_LR_LOCK && message_latched == MSG_RLS_REDUCE) begin
						  buffer_wr_data_next = buffer_rd_data;
						  buffer_rd_addr_next = buffer_rd_addr_next+1;
						  out_data = buffer_rd_data;
						  buffer_wr_en_next = 0;
					  end
					  
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
				  if(reduce_state != REDUCE_HR && reduce_state != REDUCE_LR && reduce_state != REDUCE_RR && reduce_state != REDUCE_T_HR && reduce_state != REDUCE_TE_HR &&
				     reduce_state != REDUCE_R_LOCK_R && reduce_state != REDUCE_L_LOCK_L ) begin
					  out_data = in_fifo_data_dout + buffer_rd_data; //buffer[buffer_rd_addr];
					  buffer_rd_addr_next = buffer_rd_addr_next+1;
					  buffer_wr_data_next = in_fifo_data_dout + buffer_rd_data;
				  end	 
				  
				  if(reduce_state == REDUCE_RR_LOCK && message_latched == MSG_RLS_REDUCE) begin
					  buffer_wr_data_next = buffer_rd_data;
					  buffer_rd_addr_next = buffer_rd_addr_next+1;
					  out_data = buffer_rd_data;
					  buffer_wr_en_next = 0;
				  end
				  
				  if(reduce_state == REDUCE_LR_LOCK && message_latched == MSG_RLS_REDUCE) begin
					  buffer_wr_data_next = buffer_rd_data;
					  buffer_rd_addr_next = buffer_rd_addr_next+1;
					  out_data = buffer_rd_data;
					  buffer_wr_en_next = 0;
				  end
				  
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
					  $display("WAIT_EOP : %d", word_count);
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

