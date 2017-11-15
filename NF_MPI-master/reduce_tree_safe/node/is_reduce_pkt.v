///////////////////////////////////////////////////////////////////////////////
// $Id: is_reduce_pkt.v 2201 2013-05-08 01:58:51Z omerarap $
//
// Module: is_reduce_pkt.v
// Project: NF3.1
// Description: checks weather a packet is a reduce pkt or not
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
  module is_reduce_pkt
    #(parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH=DATA_WIDTH/8,
      parameter NUM_IQ_BITS = 3,
      parameter INPUT_ARBITER_STAGE_NUM = 2
      )
   (// --- Interface to the previous stage
    input  [DATA_WIDTH-1:0]            in_data,
    input  [CTRL_WIDTH-1:0]            in_ctrl,
    input                              in_wr,

    // --- Interface to output_port_lookup
    output reg 	       reduce_pkt,
    output reg	       not_reduce_pkt,
    output reg	       decode_done,
    output reg [15:0]  message,
    output reg [15:0]  comm_id,
    output reg [7:0]   topo_type,
    output reg [7:0]   node_type,
    output reg [15:0]  rank,
    output reg [15:0]  root,
    output reg [15:0]  size,
    output reg [15:0]  op,
    output reg [15:0]  count,
    output reg [15:0]  data_type,
    output reg [15:0]  on_the_path,
    output reg [47:0]  src_mac,
    output reg [47:0]  dst_mac,
    output reg [31:0]  src_ip,
    output reg [31:0]  dst_ip,
    output reg [15:0]  ip_cksum,
    output reg [15:0]  udp_src,
    output reg [15:0]  udp_dst,
    // --- Misc

    input                              reset,
    input                              clk
   );


   // ------------ Internal Params --------

   parameter NUM_STATES  = 9;
   parameter READ_WORD_1 = 1;
   parameter READ_WORD_2 = 2;
   parameter READ_WORD_3 = 3;
   parameter READ_WORD_4 = 4;
   parameter READ_WORD_5 = 5;
   parameter READ_WORD_6 = 6;
   parameter READ_WORD_7 = 7;
   parameter READ_WORD_8 = 8;
   parameter WAIT_EOP    = 9;

   // ------------- Regs/ wires -----------

   reg [NUM_STATES-1:0] state;
   reg [NUM_STATES-1:0] state_next;
   
   reg 	reduce_pkt_next;
   reg 	not_reduce_pkt_next;
   reg 	decode_done_next;
   reg [15:0] 	message_next;
   reg [15:0] 	comm_id_next;
   reg [7:0] 	topo_type_next;
   reg [7:0] 	node_type_next;
   reg [15:0] 	rank_next;
   reg [15:0] 	root_next;
   reg [15:0] 	size_next;
   reg [15:0] 	op_next;
   reg [15:0] 	count_next;
   reg [15:0] 	data_type_next;
   reg [15:0] 	on_the_path_next;
   reg [47:0] 	src_mac_next;
   reg [47:0] 	dst_mac_next;
   reg [31:0] 	src_ip_next;
   reg [31:0] 	dst_ip_next;
   reg [15:0] 	ip_cksum_next;
   reg [15:0] 	udp_src_next;
   reg [15:0] 	udp_dst_next;
   
   // ------------ Logic ----------------

   always @(*) begin
      state_next = state;
      reduce_pkt_next = reduce_pkt;
      not_reduce_pkt_next = not_reduce_pkt;
      message_next = message;
      comm_id_next = comm_id;
      topo_type_next = topo_type;
      node_type_next = node_type;
      rank_next = rank;
      root_next = root;
      size_next = size;
      op_next = op;
      count_next = count;
      data_type_next = data_type;
      on_the_path_next = on_the_path;
      decode_done_next = decode_done;
      src_mac_next = src_mac;
      dst_mac_next = dst_mac;
      src_ip_next = src_ip;
      dst_ip_next = dst_ip;
      ip_cksum_next = ip_cksum;
      udp_src_next = udp_src;
      udp_dst_next = udp_dst;
      
      case(state)
	      READ_WORD_1: begin
		      if(in_wr && in_ctrl==0) begin
			      reduce_pkt_next = 0;
			      not_reduce_pkt_next = 0;
			      dst_mac_next = in_data[63:16];
			      src_mac_next[47:32] = in_data[15:0];
			      state_next = READ_WORD_2;
			  end
		  end
		  
		  READ_WORD_2: begin
			  if(in_wr) begin
				  src_mac_next[31:0] = in_data[63:32];
				  state_next = READ_WORD_3;
			  end
		  end
		  
		  READ_WORD_3: begin
			  if(in_wr) begin
				  state_next = READ_WORD_4;
			  end
		  end
		  
		  READ_WORD_4: begin
			  if(in_wr) begin
				  ip_cksum_next = in_data[63:48];
				  src_ip_next = in_data[47:16];
				  dst_ip_next[31:16] = in_data[15:0];
				  state_next = READ_WORD_5;
			  end
		  end
		  
		  READ_WORD_5: begin
			  if(in_wr) begin
				  dst_ip_next[15:0] = in_data[63:48];
				  udp_src_next = in_data[47:32];
				  udp_dst_next = in_data[31:16];
				  if((in_data[47:32] == 45329) || (in_data[31:16] == 45329)) begin
					  state_next = READ_WORD_6;
				  end
				  else begin
					  not_reduce_pkt_next = 1;
					  reduce_pkt_next = 0;
					  message_next = 0;
					  comm_id_next = 0;
					  topo_type_next = 0;
					  node_type_next = 0;
					  rank_next = 0;
					  root_next = 0;
					  size_next = 0;
					  op_next = 0;
					  count_next = 0;
					  data_type_next = 0;
					  on_the_path_next = 0;
					  state_next = WAIT_EOP;
					  //decode_done_next = 1;
				  end		                   
			  end
		  end		    
		  
		  READ_WORD_6: begin
			  if(in_wr) begin
				  reduce_pkt_next = 1;
				  not_reduce_pkt_next = 0;
				  message_next = in_data[47:32];
				  comm_id_next = in_data[31:16];
				  topo_type_next = in_data[15:8];
				  node_type_next = in_data[7:0];
				  //decode_done_next = 1;
				  state_next = READ_WORD_7;
			  end
		  end // case: READ_WORD_6
		  
		  READ_WORD_7: begin
			  if(in_wr) begin
				  reduce_pkt_next = 1;
				  not_reduce_pkt_next = 0;
				  rank_next = in_data[63:48];
				  root_next = in_data[47:32];
				  size_next = in_data[31:16];
				  op_next = in_data[15:0];
				  //decode_done_next = 1;
				  state_next = READ_WORD_8;
			  end
		  end // case: READ_WORD_6
		  
		  READ_WORD_8: begin
			  if(in_wr) begin
				  reduce_pkt_next = 1;
				  not_reduce_pkt_next = 0;
				  data_type_next = in_data[47:32];
				  on_the_path_next = in_data[31:16];
				  count_next = in_data[63:48];
				  decode_done_next = 1;
				  $display("READ_WORD_8");
				  state_next = WAIT_EOP;
			  end
		  end // case: READ_WORD_6
		  
		  WAIT_EOP: begin
			  decode_done_next = 0;
			  if(in_wr && in_ctrl!=0) begin
				  state_next = READ_WORD_1;	       
			  end
		  end
      endcase // case(state)
   end // always @ (*)
   
   always @(posedge clk) begin
	   if(reset) begin
		   state <= READ_WORD_1;
		   reduce_pkt <= 0;
		   not_reduce_pkt <= 0;
		   message <= 0;
		   comm_id <= 0;
		   node_type <= 0;
		   topo_type <= 0;
		   rank <= 0;
		   root <= 0;
		   size <= 0;
		   op <= 0;
		   count <= 0;
		   data_type <= 0;
		   on_the_path <= 0;
		   decode_done <= 0;
		   src_mac <= 0;
		   dst_mac <= 0;
		   src_ip <= 0;
		   dst_ip <= 0;
		   ip_cksum <= 0;
		   udp_src <= 0;
		   udp_dst <= 0;
	   end
	   else begin
		   state <= state_next;
		   reduce_pkt <= reduce_pkt_next;
		   not_reduce_pkt <= not_reduce_pkt_next;
		   message <= message_next;
		   comm_id <= comm_id_next;
		   node_type <= node_type_next;
		   topo_type <= topo_type_next;
		   rank <= rank_next;
		   root <= root_next;
		   size <= size_next;
		   op <= op_next;
		   count <= count_next;
		   data_type <= data_type_next;
		   on_the_path <= on_the_path_next;
		   decode_done <= decode_done_next;
		   src_mac <= src_mac_next;
		   dst_mac <= dst_mac_next;
		   src_ip <= src_ip_next;
		   dst_ip <= dst_ip_next;
		   ip_cksum <= ip_cksum_next;
		   udp_src <= udp_src_next;
		   udp_dst <= udp_dst_next;
	   end // else: !if(reset)
   	end // always @ (posedge clk)
   
endmodule // is_reduce_pkt
