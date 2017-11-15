///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: user_data_path.v 4385 2008-08-05 02:10:01Z grg $
//
// Module: user_data_path.v
// Project: NF2.1
// Description: contains all the user instantiated modules
//
///////////////////////////////////////////////////////////////////////////////
//`timescale 1ns/1ps
module chain
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      // --- data path interface
      output [DATA_WIDTH-1:0]		 out_data,
      output [CTRL_WIDTH-1:0]        	 out_ctrl,
      output                         	 out_wr,
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
      input                              reset
   );

   //------- crypto wires/regs ------
   wire [CTRL_WIDTH-1:0]            crypto_in_ctrl;
   wire [DATA_WIDTH-1:0]            crypto_in_data;
   wire                             crypto_in_wr;
   wire                             crypto_in_rdy;

   wire                             crypto_in_reg_req;
   wire                             crypto_in_reg_ack;
   wire                             crypto_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   crypto_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  crypto_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     crypto_in_reg_src;

   crypto #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) encrypt (
      // --- data path interface
      .out_data                          (crypto_in_data),
      .out_ctrl                          (crypto_in_ctrl),
      .out_wr                            (crypto_in_wr),
      .out_rdy                           (crypto_in_rdy),

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

      .reg_req_out                       (crypto_in_reg_req),
      .reg_ack_out                       (crypto_in_reg_ack),
      .reg_rd_wr_L_out                   (crypto_in_reg_rd_wr_L),
      .reg_addr_out                      (crypto_in_reg_addr),
      .reg_data_out                      (crypto_in_reg_data),
      .reg_src_out                       (crypto_in_reg_src),
      

      // --- Misc
      .clk                               (clk),
      .reset                             (reset)
   );
   
   crypto #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) decrypt (
      // --- data path interface
      .out_data                          (out_data),
      .out_ctrl                          (out_ctrl),
      .out_wr                            (out_wr),
      .out_rdy                           (out_rdy),

      .in_data                           (crypto_in_data),
      .in_ctrl                           (crypto_in_ctrl),
      .in_wr                             (crypto_in_wr),
      .in_rdy                            (crypto_in_rdy),

      // --- Register interface
      .reg_req_in                        (crypto_in_reg_req),
      .reg_ack_in                        (crypto_in_reg_ack),
      .reg_rd_wr_L_in                    (crypto_in_reg_rd_wr_L),
      .reg_addr_in                       (crypto_in_reg_addr),
      .reg_data_in                       (crypto_in_reg_data),
      .reg_src_in                        (crypto_in_reg_src),

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


endmodule // user_data_path

