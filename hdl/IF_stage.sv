import CPU_pkg::*;

`define	BYPASS_JUMP_ADDR
//`undef	BYPASS_JUMP_ADDR

module IF_stage
(
	input	logic			clk,
	input	logic			reset,

	output	logic			valid_out,
	input	logic			ready_in,
	
	// write address channel
	output	logic	[31:0]	imem_axi_awaddr,
	output	logic	[2:0]	imem_axi_awprot,
	output	logic			imem_axi_awvalid,
	input	logic			imem_axi_awready,
	// write data channel
	output	logic	[31:0]	imem_axi_wdata,
	output	logic	[3:0]	imem_axi_wstrb,
	output	logic			imem_axi_wvalid,
	input	logic			imem_axi_wready,
	// write response channel
	input	logic	[1:0]	imem_axi_bresp,
	input	logic			imem_axi_bvalid,
	output	logic			imem_axi_bready,
	// read address channel
	output	logic	[31:0]	imem_axi_araddr,
	output	logic	[2:0]	imem_axi_arprot,
	output	logic			imem_axi_arvalid,
	input	logic			imem_axi_arready,
	// read data channel
	input	logic	[31:0]	imem_axi_rdata,
	input	logic	[1:0]	imem_axi_rresp,
	input	logic			imem_axi_rvalid,
	output	logic			imem_axi_rready,

	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF,
	// exceptions
	output	logic	[1:0]	imem_axi_rresp_IF,
	
	input	logic			jump_pred_IF,
	input	logic	[31:0]	jump_addr_IF,
	
	input	logic			jump_mpred_EX,
	input	logic	[31:0]	jump_addr_EX
);

	logic			start_cycle;
	logic	[31:0]	imem_addr_reg;
	logic	[31:0]	PC;

	logic			valid_reg;
	logic			jump_pend;
	logic	[31:0]	jump_addr_reg;
	
	logic			jump_taken;
	logic	[31:0]	jump_addr;
	
	assign			jump_taken			= jump_mpred_EX || jump_pred_IF;
	assign			jump_addr			= jump_mpred_EX ? jump_addr_EX : jump_addr_IF;

	// imem is read only
	assign			imem_axi_awaddr		= 32'h00000000;
	assign			imem_axi_awprot		= 3'b110;
	assign			imem_axi_awvalid	= 1'b0;

	assign			imem_axi_wdata		= 32'h00000000;
	assign			imem_axi_wstrb		= 4'b0000;
	assign			imem_axi_wvalid		= 1'b0;

	assign			imem_axi_bready		= 1'b0;

//	assign			imem_axi_araddr		= PC;
	assign			imem_axi_arprot		= 3'b110;
	assign			imem_axi_arvalid	= !start_cycle;

	assign			imem_axi_rready		= ready_in;

	assign			valid_out			= valid_reg && !jump_mpred_EX;

`ifndef BYPASS_JUMP_ADDR
	assign			imem_axi_araddr		= PC;
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			PC	<= RESET_VEC;

		else if (imem_axi_arvalid) begin
			if (jump_taken)
				PC	<= jump_addr;
			
			else if (imem_axi_arready)
				PC	<= PC + 32'd4;
		end
	end
	
`else
	assign			imem_axi_araddr		= jump_taken ? jump_addr : PC;
	
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
`endif

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
			valid_reg			<= 1'b0;
			jump_pend			<= 1'b0;
			jump_addr_reg		<= 32'h00000000;
			PC_IF				<= 32'h00000000;
			IR_IF				<= 32'h00000000;
			imem_axi_rresp_IF	<= 2'b00;
		end

		else if (jump_taken) begin
			valid_reg			<= 1'b0;
			jump_pend			<= 1'b1;
			jump_addr_reg		<= jump_addr;
			PC_IF				<= 32'h00000000;
			IR_IF				<= 32'h00000000;
			imem_axi_rresp_IF	<= 2'b00;
		end

		else if (imem_axi_rvalid && imem_axi_rready) begin
			if (!jump_pend) begin
				valid_reg			<= 1'b1;
				PC_IF				<= imem_addr_reg;
				IR_IF				<= |imem_axi_rresp ? RV32I_NOP : imem_axi_rdata;
				imem_axi_rresp_IF	<= imem_axi_rresp;
			end
			
			else if (imem_addr_reg == jump_addr_reg) begin
				valid_reg			<= 1'b1;
				jump_pend			<= 1'b0;
				PC_IF				<= imem_addr_reg;
				IR_IF				<= |imem_axi_rresp ? RV32I_NOP : imem_axi_rdata;
				imem_axi_rresp_IF	<= imem_axi_rresp;
			end
		end

		else if (valid_reg && ready_in) begin
			valid_reg			<= 1'b0;
			PC_IF				<= 32'h00000000;
			IR_IF				<= 32'h00000000;
			imem_axi_rresp_IF	<= 2'b00;
		end
	end

endmodule