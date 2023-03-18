module branch_predictor
#(
	parameter	n	= 2,
	parameter	m	= 2
)
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	input	logic			ready_in,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IM_IF,
	input	logic			jump_ena_IF,
	input	logic			jump_alw_IF,
	input	logic			jump_ind_IF,
	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,
	
	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX
);

	logic	[m-1:0]	PHT		[2**n];
	logic	[n-1:0]	GBH;
	
	logic	[n-1:0]	wPtr;
	logic	[n-1:0]	rPtr;
	
	assign			wPtr			= GBH ^ PC_EX[n+1:2];
	assign			rPtr			= GBH ^ PC_IF[n+1:2];

	assign			jump_pred_IF	= valid_in && jump_ena_IF && !jump_ind_IF && (PHT[rPtr] >= 2**(n-2) || jump_alw_IF);
	assign			jump_addr_IF	= PC_IF + IM_IF;
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			for (integer i = 0; i < 2**n; i = i+1)
				PHT[i]	<= -1;
				
			GBH	<= 0;
		end
		
		else if (ready_in && jump_ena_EX && !jump_alw_EX) begin
			if (jump_taken_EX) begin
				PHT[wPtr]	<= PHT[wPtr] + ~&PHT[wPtr];
				GBH			<= (GBH << 1) | 1'b1;
			end
			
			else begin
				PHT[wPtr]	<= PHT[wPtr] - |PHT[wPtr];
				GBH			<= (GBH << 1) | 1'b0;
			end
		end
	end

endmodule