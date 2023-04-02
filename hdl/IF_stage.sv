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

	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF,
	output	logic			trap_taken_IF,
	output	logic	[31:0]	trap_cause_IF
);

	logic			start_cycle;
	logic	[31:0]	imem_addr_reg;
	logic	[31:0]	PC;

	logic			valid_out_int;
	logic			jump_pend;
	logic	[31:0]	jump_addr_reg;

	assign			imem_axi_araddr		= jump_taken ? jump_addr : PC;
	assign			imem_axi_arprot		= 3'b110;
	assign			imem_axi_arvalid	= !start_cycle;

	assign			imem_axi_rready		= ready_in;

	assign			valid_out			= valid_out_int && !flush;

	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			PC	<= RESET_VEC;

		else if (imem_axi_arvalid) begin
			if (imem_axi_arready) begin
				if (jump_taken)
					PC	<= jump_addr + 32'd4;

				else
					PC	<= PC + 32'd4;
			end

			else if (jump_taken)
				PC	<= jump_addr;
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			imem_addr_reg	<= 32'h00000000;
			start_cycle		<= 1'b1;
		end

		else if (start_cycle)
			start_cycle		<= 1'b0;

		else if (imem_axi_arvalid && imem_axi_arready)
			imem_addr_reg	<= imem_axi_araddr;
	end

	// IF/ID pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out_int	<= 1'b0;
			jump_pend		<= 1'b0;
			jump_addr_reg	<= 32'h00000000;
			PC_IF			<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			trap_taken_IF	<= 1'b0;
			trap_cause_IF	<= 32'h00000000;
		end

		else if (jump_taken) begin
			valid_out_int	<= 1'b0;
			jump_pend		<= 1'b1;
			jump_addr_reg	<= jump_addr;
			PC_IF			<= 32'h00000000;
			IR_IF			<= 32'h00000000;
			trap_taken_IF	<= 1'b0;
			trap_cause_IF	<= 32'h00000000;
		end

		else if (imem_axi_rvalid && imem_axi_rready) begin
			if (!jump_pend) begin
				valid_out_int	<= 1'b1;
				jump_pend		<= 1'b0;
				jump_addr_reg	<= 32'h00000000;
				PC_IF			<= imem_addr_reg;

				if (|imem_axi_rresp) begin
					IR_IF			<= RV32I_NOP;
					trap_taken_IF	<= 1'b1;
					trap_cause_IF	<= CAUSE_IMEM_BUS_ERROR;
				end

				else begin
					IR_IF			<= imem_axi_rdata;
					trap_taken_IF	<= 1'b0;
					trap_cause_IF	<= 32'h00000000;
				end
			end

			else if (imem_addr_reg == jump_addr_reg) begin
				valid_out_int	<= 1'b1;
				jump_pend		<= 1'b0;
				jump_addr_reg	<= 32'h00000000;
				PC_IF			<= imem_addr_reg;

				if (|imem_axi_rresp) begin
					IR_IF			<= RV32I_NOP;
					trap_taken_IF	<= 1'b1;
					trap_cause_IF	<= CAUSE_IMEM_BUS_ERROR;
				end

				else begin
					IR_IF			<= imem_axi_rdata;
					trap_taken_IF	<= 1'b0;
					trap_cause_IF	<= 32'h00000000;
				end
			end
		end

		else if (valid_out_int && ready_in) begin
			valid_out_int		<= 1'b0;
			jump_pend			<= 1'b0;
			jump_addr_reg		<= 32'h00000000;
			PC_IF				<= 32'h00000000;
			IR_IF				<= 32'h00000000;
			trap_taken_IF		<= 1'b0;
			trap_cause_IF		<= 32'h00000000;
		end
	end

endmodule