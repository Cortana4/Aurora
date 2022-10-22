`include "AmberFive_constants.svh"

module MEM_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic	[31:0]	PC_EX,
	input	logic	[31:0]	IR_EX,
	input	logic	[31:0]	IM_EX,
	input	logic	[4:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic			rd_access_EX,
	input	logic	[2:0]	MEM_op_EX,
	input	logic			dmem_access_EX,
	input	logic			illegal_inst_EX,
	input	logic			misaligned_addr_EX,
	
	input	logic	[31:0]	dmem_din,
	
	output	logic	[31:0]	PC_MEM,
	output	logic	[31:0]	IR_MEM,
	output	logic	[31:0]	IM_MEM,
	output	logic	[4:0]	rd_addr_MEM,
	output	logic	[31:0]	rd_data_MEM,
	output	logic			rd_access_MEM
);
	
	logic	[31:0]	dmem_din_aligned;
	assign			dmem_din_aligned = dmem_din >> rd_data_EX[1:0];

	// MEM/WB pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			PC_MEM			<= 32'h00000000;
			IR_MEM			<= 32'h00000000;
			IM_MEM			<= 32'h00000000;
			rd_addr_MEM		<= 4'h0;
			rd_data_MEM		<= 32'h00000000;
			rd_access_MEM	<= 1'b0;
		end
		
		else begin
			PC_MEM			<= PC_EX;
			IR_MEM			<= IR_EX;
			IM_MEM			<= IM_EX;
			rd_addr_MEM		<= rd_addr_EX;
			
			if (dmem_access_EX) begin
				case (MEM_op_EX)
				`MEM_LB:	rd_data_MEM	<= dmem_din_aligned | {24{dmem_din_aligned[7]}};
				`MEM_LH:	rd_data_MEM	<= dmem_din_aligned | {16{dmem_din_aligned[15]}};
				default:	rd_data_MEM	<= dmem_din_aligned;
				endcase
			end
			
			else
				rd_data_MEM	<= rd_data_EX;

			rd_access_MEM	<= rd_access_EX;
		end
	end
	
endmodule