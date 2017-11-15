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

   parameter NUM_STATES = 4;
   parameter WAIT_TILL_DONE_DECODE = 1;
   parameter WRITE_HDR             = 2;
   parameter SKIP_HDRS             = 4;
   parameter WAIT_EOP              = 8;
   parameter UPDATE_BARRIER_MSG= 3;

   localparam BARRIER_IDLE     = 0;
   localparam AT_BARRIER       = 1;
   localparam WAIT_CPU         = 2;
   localparam WAIT_NETWORK     = 3;
   localparam WAIT_NOTIFICATION= 4;
   
   localparam TOPO_RING		   = 1;
   localparam TOPO_TREE		   = 2;
   localparam TOPO_BUTTERFLY   = 3;
   localparam TOPO_TRUNK	   = 4;
   localparam TOPO_CENTRAL     = 5;
   
   localparam NODE_HEAD		   = 1;
   localparam NODE_NODE		   = 2;
   localparam NODE_LEAF		   = 3;
   localparam NODE_ROOT		   = 4;
   localparam NODE_CENTER	   = 5;
   localparam NODE_TRUNK	   = 6;

   localparam MSG_AT_BARRIER   			= 65;   
   localparam MSG_PREV_AT_BARRIER		= 66;
   localparam MSG_RELEASE_BARRIER		= 67;
   localparam MSG_SIBBLING_AT_BARRIER	= 68;
   localparam MSG_CHILDREN_AT_BARRIER	= 69;
   
   
   //---------------------- Wires and regs----------------------------

   wire                         lookup_ack;
   wire [47:0]                  dst_mac;
   wire [47:0]                  src_mac;
   wire [15:0]                  ethertype;
   wire [NUM_IQ_BITS-1:0]       src_port;
   wire                         decode_done;
   wire							barrier_pkt;
   wire							not_barrier_pkt;
   wire [15:0]					message;
   wire [15:0]					comm_id;
   wire [7:0]					topo_type;
   wire [7:0]					node_type;
   wire [15:0]          		comm_id_latched;
   wire [7:0]                   topo_type_latched;
   wire [7:0]                   node_type_latched;
   wire [15:0]					message_latched;

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

   reg [15:0]					decoded_src;

   reg [NUM_STATES-1:0]         state, state_next;
   reg [2:0]					barrier_state, barrier_state_next;
   reg [2:0]					word_count, word_count_next;

   //------------------------- Modules-------------------------------
   is_barrier_pkt
     #(.DATA_WIDTH (DATA_WIDTH),
       .CTRL_WIDTH (CTRL_WIDTH),
       .NUM_IQ_BITS(NUM_IQ_BITS),
       .INPUT_ARBITER_STAGE_NUM(INPUT_ARBITER_STAGE_NUM))
     is_barrier_pkt
         (.in_data(in_data),
          .in_ctrl(in_ctrl),
          .in_wr(in_wr),
          .barrier_pkt (barrier_pkt),
          .not_barrier_pkt (not_barrier_pkt),
          .decode_done (decode_done),
          .message (message),
          .comm_id (comm_id),
          .topo_type (topo_type),
          .node_type (node_type),
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

   small_fifo #(.WIDTH(48), .MAX_DEPTH_BITS(2))
      dst_port_fifo
        (.din ({message, comm_id, topo_type, node_type}),     // Data in
         .wr_en (decode_done),             // Write enable
         .rd_en (dst_port_rd),       // Read the next word
         .dout ({message_latched, comm_id_latched, topo_type_latched, node_type_latched}),
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
	    out_ctrl         = in_fifo_ctrl_dout;
	    out_data 		 = in_fifo_data_dout;
	    state_next 	 = state;
	    barrier_state_next = barrier_state;
	    out_wr 		 = 0;
	    in_fifo_rd_en 	 = 0;
	    dst_port_rd 	 = 0;
	    word_count_next  = word_count;
	    
	   	case(state)
		   	WAIT_TILL_DONE_DECODE: begin
			   	$display("WAIT_TILL_DONE_DECODE");
			   	if(!dst_port_fifo_empty) begin
				   	dst_port_rd     = 1;
				   	state_next      = WRITE_HDR;
				   	in_fifo_rd_en   = 1;
				end
			end

       	   	// write Destionation output ports */
       	   	WRITE_HDR: begin
	       	   	if(out_rdy) begin
		       	   	$display("WRITE_HEADER %b %b %d %d %d", barrier_pkt, not_barrier_pkt, in_fifo_ctrl_dout, `IO_QUEUE_STAGE_NUM, pkt_is_from_cpu);
		       	    out_wr = 1;
				    in_fifo_rd_en = 1;
		       	   	//barrier traffic
		       	   	if(barrier_pkt && !not_barrier_pkt && in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
			       	   	out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = 0;
			       	   	$display("Processing barrier_pkt %d %d %d %b %d", topo_type_latched, node_type_latched, message_latched, pkt_is_from_cpu, barrier_state);
			       	   	//ring_topo_head_node_state_machine
			       	   	if(topo_type_latched == TOPO_RING &&
				       	   node_type_latched == NODE_HEAD &&
				       	   message_latched == MSG_AT_BARRIER  &&
				       	   pkt_is_from_cpu &&
					       barrier_state == BARRIER_IDLE) begin
						       $display("RING_HEAD_NODE_BARRIER_IDLE");
						  	   out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000001};
						  	   barrier_state_next = AT_BARRIER;
						  	   state_next = UPDATE_BARRIER_MSG;
					    end
						else if(topo_type_latched == TOPO_RING &&
								message_latched == MSG_PREV_AT_BARRIER  &&
								!pkt_is_from_cpu &&
								barrier_state == AT_BARRIER) begin
									$display("RING_HEAD_NODE_AT_BARRIER");
									out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
									barrier_state_next = BARRIER_IDLE;
									state_next = UPDATE_BARRIER_MSG;			
			       	   	end
			       	   	//ring_topo_regular_node_state_machine
			       	   	else if(topo_type_latched == TOPO_RING &&
								node_type_latched == NODE_NODE &&
								message_latched == MSG_AT_BARRIER  &&
								pkt_is_from_cpu	&&
								barrier_state == BARRIER_IDLE) begin
									$display("RING_REGULAR_NODE_BARRIER_IDLE_1");
									barrier_state_next = WAIT_NETWORK;
									state_next = SKIP_HDRS;
						end	
						//this is buggy. I am not sure how a packet like this reaches to the head node, but if it does it crashes things up. NEEDS TO BE FIXED
						else if(topo_type_latched == TOPO_RING &&
								message_latched == MSG_PREV_AT_BARRIER  &&
								!pkt_is_from_cpu &&
								barrier_state == BARRIER_IDLE) begin
									$display("RING_REGULAR_NODE_BARRIER_IDLE_2");
									barrier_state_next = WAIT_CPU;
									state_next = SKIP_HDRS;
						end			
						else if(topo_type_latched == TOPO_RING &&
								message_latched == MSG_PREV_AT_BARRIER  &&
								!pkt_is_from_cpu &&
								barrier_state == WAIT_NETWORK) begin
									$display("RING_REGULAR_NODE_WAIT_NETWORK");
									out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000001};
									barrier_state_next = WAIT_NOTIFICATION;
									state_next = SKIP_HDRS;
						end						
						else if(topo_type_latched == TOPO_RING &&
								message_latched == MSG_AT_BARRIER  &&
								pkt_is_from_cpu &&
								barrier_state == WAIT_CPU) begin
									$display("RING_REGULAR_NODE_WAIT_CPU");
									out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000001};
									barrier_state_next = WAIT_NOTIFICATION;
									state_next = UPDATE_BARRIER_MSG;
						end
						else if(topo_type_latched == TOPO_RING &&
								message_latched == MSG_RELEASE_BARRIER  &&
								!pkt_is_from_cpu &&
								barrier_state == WAIT_NOTIFICATION) begin
									$display("RING_REGULAR_NODE_WAIT_NOTIFICATION");
									out_data[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = {8'b0,8'b00000011};
									barrier_state_next = BARRIER_IDLE;
									state_next = SKIP_HDRS;
						end							
						
			       	   	else if(topo_type_latched == TOPO_TREE) begin
			       	   	end
			       	   	else if(topo_type_latched == TOPO_BUTTERFLY) begin
			       	   	end
			       	   	else if(topo_type_latched == TOPO_TRUNK) begin
			       	   	end
			       	   	else if(topo_type_latched == TOPO_CENTRAL) begin
			       	   	end
			       	   	else begin
				       	   	state_next      = SKIP_HDRS;
			       	   	end
				    end
				    //regular ethernet NIC traffic
				    else if(!barrier_pkt && not_barrier_pkt) begin
					    $display("NON_BARRIER_TRAFFIC");
					    if(in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
						    if(pkt_is_from_cpu) begin		    					 
							    out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = {1'b0, decoded_src[15:1]};
							    $display("out_data_1 : %h %h",out_data,decoded_src);
							end
							else begin
								out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = {decoded_src[14:0], 1'b0};
								$display("out_data_2 : %h %h",out_data,decoded_src);
							end
						end
						state_next      = SKIP_HDRS;
					end	
					//contingency case, packet is dropped since not classified.
					else begin 
						if(in_fifo_ctrl_dout==`IO_QUEUE_STAGE_NUM) begin
						 	out_data[`IOQ_DST_PORT_POS + 15:`IOQ_DST_PORT_POS] = 0;
						end
						state_next      = SKIP_HDRS;
					end
				end
			end
			
			UPDATE_BARRIER_MSG: begin
				$display("UPDATE_BARRIER_MSG %d %d %d %d", word_count, barrier_state, node_type_latched, topo_type_latched);
				if(in_fifo_ctrl_dout!=255 & out_rdy) begin
					out_wr = 1;
					if(word_count==4) begin
						if( barrier_state == AT_BARRIER && 
							node_type_latched == NODE_HEAD && 
							topo_type_latched == TOPO_RING) begin
							$display("MSG_PREV_AT_BARRIER_1");	
							out_data[47:32] = MSG_PREV_AT_BARRIER;
							out_data[7:0] = NODE_NODE;
						end
						else if( barrier_state == BARRIER_IDLE && 
								 node_type_latched == NODE_NODE && 
								 topo_type_latched == TOPO_RING) begin
							$display("MSG_RELEASE_BARRIER");		 
							out_data[47:32] = MSG_RELEASE_BARRIER;
						end 
						else if( barrier_state == WAIT_NOTIFICATION && 
								 node_type_latched == NODE_NODE && 
								 topo_type_latched == TOPO_RING) begin
							$display("MSG_PREV_AT_BARRIER_2");		 
							out_data[47:32] = MSG_PREV_AT_BARRIER;
						end
						word_count_next = 0;
						state_next = WAIT_TILL_DONE_DECODE;//WAIT_EOP;
					end
					else begin
						word_count_next = word_count_next+1;	
					end
				end	
				if(!in_fifo_empty & out_rdy) begin
					in_fifo_rd_en   = 1;
					//out_wr          = 1;
				end
			end

           	// Skip the rest of the headers 
           	SKIP_HDRS: begin
	           	$display("SKIP_HDRS");
	           	if(in_fifo_ctrl_dout==0) begin
		           	state_next = WAIT_EOP;
				end
				if(!in_fifo_empty & out_rdy) begin
					in_fifo_rd_en   = 1;
					out_wr          = 1;
				end
			end

           	// write all data 
           	WAIT_EOP: begin
	           	$display("WAIT_EOP");
	           	if(in_fifo_ctrl_dout!=0)begin
		           	if(out_rdy) begin
			           	state_next   = WAIT_TILL_DONE_DECODE;
			           	out_wr       = 1;
					end
				end
				else if(!in_fifo_empty & out_rdy) begin
					in_fifo_rd_en   = 1;
					out_wr          = 1;
			    end
			end // case: WAIT_EOP
		endcase // case(state)
		//$display("out_data : %h", out_data);
	end // always @ (*)

	always @(posedge clk) begin
		if(reset) begin
			state			<= WAIT_TILL_DONE_DECODE;
			barrier_state 	<= BARRIER_IDLE;
			word_count		<= 0;
		end
		else begin
			state			<= state_next;
			barrier_state 	<= barrier_state_next;
			word_count		<= word_count_next;
		end
	end
 endmodule // switch_output_port

