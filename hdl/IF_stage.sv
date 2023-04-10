import CPU_pkg::*;

module IF_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,

	output	logic			valid_out,
	input	logic			ready_in,
	
	output	logic	[31:0]	imem_axi_araddr,	// read address channel
	output	logic	[2:0]	imem_axi_arprot,
	output	logic			imem_axi_arvalid,
	input	logic			imem_axi_arready,
	input	logic	[31:0]	imem_axi_rdata,		// read data channel
	input	logic	[1:0]	imem_axi_rresp,
	input	logic			imem_axi_rvalid,
	output	logic			imem_axi_rready,

	input	logic			jump_taken,
	input	logic	[31:0]	jump_addr,
	
	output	logic	[31:0]	PC_int,

	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF,
	output	logic			exc_pend_IF,
	output	logic	[31:0]	exc_cause_IF
);

	logic			start_cycle;
	logic	[31:0]	imem_addr_reg;
	logic	[31:0]	PC;

	logic			valid_out_int;
	logic			jump_pend;
	logic	[31:0]	jump_addr_reg;

	assign			imem_axi_araddr		= PC;
	assign			imem_axi_arprot		= 3'b110;
	assign			imem_axi_arvalid	= PC_valid;

	assign			imem_axi_rready		= ready_in;

	assign			valid_out			= valid_out_int && !flush;
	
	
	assign			imem_addr_buf_wena	= imem_axi_arvalid && imem_axi_arready;
	assign			imem_addr_buf_rena	= imem_axi_rvalid  && imem_axi_rready;
	
	fifo_buf
	#(
		.ADDR_WIDTH(1),
		.DATA_WIDTH(32)
	) imem_addr_buf
	(
		.clk(clk),
		.reset(reset),

		.wena(imem_addr_buf_wena),
		.wdata(imem_axi_araddr),

		.rena(imem_addr_buf_rena),
		.rdata(imem_addr_buf_rdata),

		.empty(imem_addr_buf_empty),
		.full()
	);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			start_cycle			<= 1'b1;
			imem_axi_araddr		<= RESET_VEC;
			imem_axi_arvalid	<= 1'b0;
			
		end
		
		else if (start_cycle) begin
			imem_axi_arvalid	<= 1'b1;
			start_cycle			<= 1'b0;
		end
		
		else if (imem_axi_arready) begin
			if (imem_addr_buf_empty || imem_addr_buf_rena) begin
				if (jump_taken) begin
					imem_axi_araddr		<= jump_addr;
					jump_addr_buf		<= jump_addr;
				end
				
				else if (jump_pend) begin
					imem_axi_araddr		<= jump_addr_buf;
					imem_axi_arvalid	<= 1'b1;
				end
				
				else begin
					imem_axi_araddr		<= imem_axi_araddr + 32'd4;
					imem_axi_arvalid	<= 1'b1;
				end
				
				imem_axi_arvalid	<= 1'b1;
				jump_pend			<= 1'b0;
			end
			
			else if (imem_axi_arvalid)
				imem_axi_arvalid	<= 1'b0;
		end

		else if (jump_taken) begin
			jump_addr_buf	<= jump_addr;
			jump_pend		<= 1'b1;
		end
	end
	
	

	// IF/ID pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out_int	<= 1'b0;
			jump_pend		<= 1'b0;
			PC_IF			<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			exc_pend_IF		<= 1'b0;
			exc_cause_IF	<= 32'h00000000;
		end

		else if (jump_taken) begin
			valid_out_int	<= 1'b0;
			jump_pend		<= 1'b1;
			PC_IF			<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			exc_pend_IF		<= 1'b0;
			exc_cause_IF	<= 32'h00000000;
		end

		else if (imem_axi_rvalid && imem_axi_rready) begin
			if (jump_pend)
				jump_pend	<= 1'b0;
				
			else if (imem_addr_reg_valid) begin
				valid_out_int	<= 1'b1;
				jump_pend		<= 1'b0;
				PC_IF			<= imem_addr_reg;

				if (|imem_axi_rresp) begin
					IR_IF			<= RV32I_NOP;
					exc_pend_IF		<= 1'b1;
					exc_cause_IF	<= CAUSE_IMEM_BUS_ERROR;
				end

				else begin
					IR_IF			<= imem_axi_rdata;
					exc_pend_IF		<= 1'b0;
					exc_cause_IF	<= 32'h00000000;
				end
			end

		end

		else if (valid_out_int && ready_in) begin
			valid_out_int		<= 1'b0;
			jump_pend			<= 1'b0;
			PC_IF				<= 32'h00000000;
			IR_IF				<= 32'h00000000;
			exc_pend_IF			<= 1'b0;
			exc_cause_IF		<= 32'h00000000;
		end
	end
	
	always_comb begin
		if (valid_out)
			PC_int	= PC_IF;
		
		else if ()
	end

endmodule