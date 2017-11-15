module tb_output_port_lookup;

   reg	clk;
   reg reset;

   //------- output_port_lookup wires/regs ------
   reg [7:0]				in_ctrl;
   reg [63:0]            		in_data;
   reg                             	in_wr;
   wire                             	in_rdy;

   reg                             	reg_req_in;
   reg                             	reg_ack_in;
   reg                             	reg_rd_wr_L_in;
   reg [`UDP_REG_ADDR_WIDTH-1:0]	reg_addr_in;
   reg [`CPCI_NF2_DATA_WIDTH-1:0]  	reg_data_in;
   reg [1:0]				reg_src_in;

   //------- output queues wires/regs ------
   wire [7:0]				out_ctrl;
   wire [63:0]            		out_data;	
   wire                             	out_wr;
   reg                             	out_rdy;

   wire                             	reg_req_out;
   wire					reg_ack_out;	
   wire                             	reg_rd_wr_L_out;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   	reg_addr_out;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  	reg_data_out;
   wire [1:0]     			reg_src_out;

   initial begin
   	   $from_myhdl(
		in_data,
		in_ctrl,
		in_wr,
		out_rdy,
		reg_req_in,
		reg_ack_in,
		reg_rd_wr_L_in,
		reg_addr_in,
		reg_data_in,
		reg_src_in,
		clk,
		reset
	   );
	   $to_myhdl(
		out_data,
		out_ctrl,
		out_wr,
		in_rdy,
		reg_req_out,
		reg_ack_out,
		reg_rd_wr_L_out,
		reg_addr_out,
		reg_data_out,
		reg_src_out
	   );
   end		

   output_port_lookup #(
      .DATA_WIDTH(64),
      .CTRL_WIDTH(8),
      .UDP_REG_SRC_WIDTH (2)
   ) opl (
      // --- data path interface
      .out_data                          (out_data),
      .out_ctrl                          (out_ctrl),
      .out_wr                            (out_wr),
      .out_rdy                           (out_rdy),

      .in_data                           (in_data),
      .in_ctrl                           (in_ctrl),
      .in_wr                             (in_wr),
      .in_rdy                            (in_rdy),

      // --- Register interface
      .reg_req_in                        (reg_req_in),
      .reg_ack_in                        (reg_ack_in),
      .reg_rd_wr_L_in                    (reg_rd_wr_L_in),
      .reg_addr_in                       (reg_addr_in),
      .reg_data_in                       (reg_data_in),
      .reg_src_in                        (reg_src_in),

      .reg_req_out                       (reg_req_out),
      .reg_ack_out                       (reg_ack_out),
      .reg_rd_wr_L_out                   (reg_rd_wr_L_out),
      .reg_addr_out                      (reg_addr_out),
      .reg_data_out                      (reg_data_out),
      .reg_src_out                       (reg_src_out),
      

      // --- Misc
      .clk                               (clk),
      .reset                             (reset)
   );

endmodule