module branch_predictor
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IM_IF,
	
	input	logic			jump_ena,
	input	logic			jump_alw,
	input	logic			jump_ind,
	
	output	logic	[31:0]	target_addr,
	
);

endmodule