module tb_fallthrough_small_fifo;

   reg	clk;
   reg reset;

   reg [71:0]            		din;
   reg                             	wr_en;
   reg                             	rd_en;

   wire [71:0]            		dout;	
   wire                             	full;
   wire                             	nearly_full;   
   wire                             	empty;

   initial begin
//    		$monitor ("din=%x\tdout=%x\twr_en=%b\trd_en=%b\tempty=%b\tnearly_full=%b\tfull=%b", din,dout,wr_en,rd_en,empty,nearly_full,full);
//    		clk=0;
//    		reset=0;
//    		wr_en=0;
//    		rd_en=0;
//    		din=72'h1;
//    		#5 wr_en=1;
//    		#10 din=72'h2;
//    		#10 din=72'h3;
//    		#10 rd_en=1;
//    		#10 din=72'h4;
//    		#10 wr_en=0;
//    		#20 $finish;
  	   $from_myhdl(
	 	din,
		wr_en,
		rd_en,
		clk,
		reset
	   );
	   $to_myhdl(
		dout,
		full,
		nearly_full,
		empty
	   );
   end		

//   always begin
//       clk =  ! clk;
//   end
   
   fallthrough_small_fifo  input_fifo      // --- data path interface
     (.din                               (din),
      .wr_en                             (wr_en),
      .rd_en                             (rd_en),

      .dout                              (dout),
      .full                              (full),
      .nearly_full                       (nearly_full),
      .empty                             (empty),
      // --- Misc
      .clk                               (clk),
      .reset                             (reset)
   );

   defparam input_fifo.WIDTH = `width;
   defparam input_fifo.MAX_DEPTH_BITS = `dept;
 
endmodule