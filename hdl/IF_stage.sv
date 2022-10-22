`include "AmberFive_constants.svh"

module IF_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			stall,
	
	output	logic	[31:0]	imem_addr,
	input	logic	[31:0]	imem_din,
	output	logic			imem_ena,
	
	input	logic			jump_taken,
	input	logic	[31:0]	jump_addr,
	
	output	logic	[31:0]	PC_IF,
	output	logic	[31:0]	IR_IF
);

	logic	[31:0]	PC;
	logic	[31:0]	imem_addr_reg;
	logic			insert_bubble;
	
	assign			imem_addr	= jump_taken ? jump_addr : PC;
	assign			imem_ena	= !stall;
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			PC	<= `RESET_VEC;
			
		else if (!stall) begin
			if (jump_taken)
				PC	<= jump_addr + 32'd4;
			
			else
				PC	<= PC + 32'd4;
		end
	end
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			imem_addr_reg	<= `RESET_VEC;
			insert_bubble	<= 1'b1;
		end
		
		else if (!stall) begin
			imem_addr_reg	<= imem_addr;
			insert_bubble	<= 1'b0;
		end
	end
	
	// IF/ID pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			PC_IF	<= 32'h00000000;
			IR_IF	<= `RV32I_NOP;
		end
		
		else if (!stall) begin
			if (jump_taken || insert_bubble) begin
				PC_IF	<= 32'h00000000;
				IR_IF	<= `RV32I_NOP;
			end
			
			else begin
				PC_IF	<= imem_addr_reg;
				IR_IF	<= imem_din;
			end
		end
	end

endmodule