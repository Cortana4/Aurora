`include "AmberFive_constants.svh"

module IF_stage
(
	input	logic			clk,
	input	logic			reset,
	
	output	logic			valid_out,
	input	logic			ready_in,
	
	// read address channel
	output	logic	[31:0]	imem_axi_araddr,
	output	logic	[2:0]	imem_axi_arprot,
	input	logic			imem_axi_arready,
	output	logic			imem_axi_arvalid,
	// read data channel
	input	logic	[31:0]	imem_axi_rdata,
	output	logic			imem_axi_rready,
	input	logic	[1:0]	imem_axi_rresp,
	input	logic			imem_axi_rvalid,
	
	input	logic			jump_taken,
	input	logic	[31:0]	jump_addr,
	
	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF
);
	// stall und jump_taken treten nie gleichzeitig auf
	logic	[31:0]	PC;
	logic	[31:0]	imem_addr_reg;
	logic			start_cycle;
	
	logic			valid_in;
	logic			ready_out;
	logic			stall;

	assign			imem_axi_araddr		= jump_taken ? jump_addr : PC;
	assign			imem_axi_arprot		= 3'b110;
	assign			imem_axi_arvalid	= ready_in && !start_cycle && imem_axi_rready;
	
	assign			imem_axi_rready		= ready_in;
	
	
	assign			valid_in			= imem_axi_rvalid;
	assign			ready_out			= ready_in && !stall;
	assign			stall				= start_cycle ||
										  (dmem_axi_arvalid && !dmem_axi_arready);
	
	

	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			PC	<= `RESET_VEC;
			
		else if (ready_out) begin
			if (jump_taken)
				PC	<= jump_addr + 32'd4;
			
			else
				PC	<= PC + 32'd4;
		end
	end
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			imem_addr_reg	<= `RESET_VEC;
			start_cycle		<= 1'b1;
		end
		
		else if (start_cycle)
			start_cycle		<= 1'b0;
		
		else if (ready_out)
			imem_addr_reg	<= imem_axi_araddr;
	end
	
	// IF/ID pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out	<= 1'b0;
			PC_IF		<= 32'h00000000;
			IR_IF		<= `RV32I_NOP;
		end
		
		else if (valid_in && ready_out) begin
			valid_out	<= 1'b1;
			PC_IF		<= imem_addr_reg;
			IR_IF		<= imem_axi_rdata;
		end
		
		else if (valid_out && ready_in) begin
			valid_out	<= 1'b0;
			PC_IF		<= 32'h00000000;
			IR_IF		<= `RV32I_NOP;
		end
	end

endmodule