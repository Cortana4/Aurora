module FPGA_top_tb();

	logic	clk;
	logic	reset;

	initial begin
		$readmemh("uart.mem", FPGA_top_inst.genblk2.RAM_inst.ram);

		clk		= 1'b0;
		reset	= 1'b1;

		@(negedge clk)
		reset	= 1'b0;
	end

	always #10 clk = !clk;
	
	FPGA_top
	#(
		.SIM			(1),
		.USE_BRAM_IP	(0)
	) FPGA_top_inst
	(
		.ref_clk		(clk),
		.reset_btn		(reset),

		.tx				(),
		.rx				(1'b1),
		.cts			(1'b0),
		.rts			(),

		.tx_led			(),
		.rx_led			()
	);

endmodule