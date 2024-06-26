import CPU_pkg::*;

module IF_stage
(
	input	logic			clk,
	input	logic			reset,

	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,

	output	logic	[31:0]	imem_axi_araddr,	// read address channel
	output	logic	[2:0]	imem_axi_arprot,
	output	logic			imem_axi_arvalid,
	input	logic			imem_axi_arready,
	input	logic	[31:0]	imem_axi_rdata,		// read data channel
	input	logic	[1:0]	imem_axi_rresp,
	input	logic			imem_axi_rvalid,
	output	logic			imem_axi_rready,

	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF,
	output	logic			exc_pend_IF,
	output	logic	[31:0]	exc_cause_IF,

	input	logic			jump_pred_IF,
	input	logic	[31:0]	jump_addr_IF,

	input	logic			jump_mpred_EX,
	input	logic	[31:0]	jump_addr_EX,

	input	logic			trap_taken_csr,
	input	logic	[31:0]	trap_addr_csr
);

	logic			start_cycle;
	logic	[31:0]	jump_addr_buf;
	logic			jump_pend;
	logic			PC_valid;
	logic	[31:0]	PC;
	logic	[31:0]	PC_IF_int;

	logic			imem_addr_buf_wena;
	logic			imem_addr_buf_rena;
	logic	[31:0]	imem_addr_buf_rdata;
	logic			imem_addr_buf_valid;

	logic			jump_taken;
	logic	[31:0]	jump_addr;
	
	logic			valid_in;
	logic			ready_out;
	logic			stall;

	assign			imem_addr_buf_wena	= imem_axi_arvalid && imem_axi_arready;
	assign			imem_addr_buf_rena	= imem_axi_rvalid  && imem_axi_rready;

	assign			imem_axi_araddr		= PC;
	assign			imem_axi_arprot		= 3'b110;
	assign			imem_axi_arvalid	= PC_valid;
	assign			imem_axi_rready		= ready_in;
	
	assign			valid_in			= imem_axi_rvalid;
	assign			ready_out			= ready_in && !stall;
	assign			stall				= !imem_addr_buf_valid || jump_pred_IF;

	addr_buf
	#(
		.ADDR_WIDTH	(1),
		.DATA_WIDTH	(32)
	) imem_addr_buf
	(
		.clk		(clk),
		.reset		(reset),
		.flush		(jump_taken || jump_pend),

		.wena		(imem_addr_buf_wena),
		.wdata		(imem_axi_araddr),

		.rena		(imem_addr_buf_rena),
		.rdata		(imem_addr_buf_rdata),
		.valid		(imem_addr_buf_valid),

		.empty		(imem_addr_buf_empty),
		.full		()
	);

	always_ff @(posedge clk) begin
		if (reset) begin
			start_cycle		<= 1'b1;
			jump_addr_buf	<= 32'h00000000;
			jump_pend		<= 1'b0;
			PC_valid		<= 1'b0;
			PC				<= RESET_VEC;
		end

		else if (start_cycle) begin
			start_cycle	<= 1'b0;
			PC_valid	<= 1'b1;
		end

		else begin
			if (jump_taken) begin
				jump_addr_buf	<= jump_addr;
				jump_pend		<= 1'b1;
			end

			if (imem_axi_arready) begin
				if (imem_addr_buf_empty || imem_addr_buf_rena) begin
					if (jump_taken) begin
						jump_addr_buf	<= 32'h00000000;
						jump_pend		<= 1'b0;
						PC_valid		<= 1'b1;
						PC				<= jump_addr;
					end

					else if (jump_pend) begin
						jump_addr_buf	<= 32'h00000000;
						jump_pend		<= 1'b0;
						PC_valid		<= 1'b1;
						PC				<= jump_addr_buf;
					end

					else begin
						jump_addr_buf	<= 32'h00000000;
						jump_pend		<= 1'b0;
						PC_valid		<= 1'b1;
						PC				<= PC + 32'd4;
					end
				end

				else if (imem_axi_arvalid)
					PC_valid	<= 1'b0;
			end
		end
	end

	// IF/ID pipeline registers
	always_ff @(posedge clk) begin
		if (reset || flush_in) begin
			PC_IF_int		<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			exc_pend_IF		<= 1'b0;
			exc_cause_IF	<= 32'h00000000;
			valid_out		<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			if (|imem_axi_rresp) begin
				PC_IF_int		<= imem_addr_buf_rdata;
				IR_IF			<= RV32I_NOP;
				exc_pend_IF		<= 1'b1;
				exc_cause_IF	<= CAUSE_IMEM_BUS_ERROR;
				valid_out		<= 1'b1;
			end

			else begin
				PC_IF_int		<= imem_addr_buf_rdata;
				IR_IF			<= imem_axi_rdata;
				exc_pend_IF		<= 1'b0;
				exc_cause_IF	<= 32'h00000000;
				valid_out		<= 1'b1;
			end
		end

		else if (valid_out && ready_in) begin
			PC_IF_int		<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			exc_pend_IF		<= 1'b0;
			exc_cause_IF	<= 32'h00000000;
			valid_out		<= 1'b0;
		end
	end

	always_comb begin
		jump_taken	= 1'b0;
		jump_addr	= 32'h00000000;

		if (trap_taken_csr) begin
			jump_taken	= 1'b1;
			jump_addr	= trap_addr_csr;
		end

		else if (jump_mpred_EX) begin
			jump_taken	= 1'b1;
			jump_addr	= jump_addr_EX;
		end

		else if (jump_pred_IF) begin
			jump_taken	= 1'b1;
			jump_addr	= jump_addr_IF;
		end
	end

	always_comb begin
		if (valid_out)
			PC_IF	= PC_IF_int;

		else if (imem_addr_buf_valid)
			PC_IF	= imem_addr_buf_rdata;

		else
			PC_IF	= PC;
	end


endmodule