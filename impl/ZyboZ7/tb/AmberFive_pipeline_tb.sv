module AmberFive_pipeline_tb();

	logic			clk;
	logic			reset;
	
	logic	[31:0]	imem_addr;
	logic	[31:0]	imem_din;
	logic			imem_ena;
	
	logic	[31:0]	dmem_addr;
	logic	[31:0]	dmem_dout;
	logic	[31:0]	dmem_din;
	logic			dmem_ena;
	logic	[3:0]	dmem_wen;
	
	initial begin
		clk		= 1'b0;
		reset	= 1'b1;
		
		@(negedge clk)
		reset	= 1'b0;
		
	end
	
	always #10 clk = !clk;

	// dual port SRAM
	// port a: instructions
	// port b: data
	RAM RAM_inst
	(
		.clka(clk),
		.addra(imem_addr[14:2]),
		.dina(32'h00000000),
		.douta(imem_din),
		.ena(imem_ena),
		.wea(4'b0000),
		
		.clkb(clk),
		.addrb(dmem_addr[14:2]),
		.dinb(dmem_dout),
		.doutb(dmem_din),
		.enb(dmem_ena),
		.web(dmem_wen)
	);

	AmberFive_pipeline AmberFive
	(
		.clk(clk),
		.reset(reset),

		.imem_addr(imem_addr),
		.imem_din(imem_din),
		.imem_ena(imem_ena),

		.dmem_addr(dmem_addr),
		.dmem_dout(dmem_dout),
		.dmem_din(dmem_din),
		.dmem_ena(dmem_ena),
		.dmem_wen(dmem_wen)
	);

endmodule