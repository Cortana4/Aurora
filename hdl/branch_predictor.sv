// gshare branch prediction

module branch_predictor
#(
	parameter	n	= 2,	// considered PC bits
	parameter	m	= 2		// bits per entry on the PHT
)
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	input	logic			ready_in,
	
	input	logic	[31:0]	trap_raddr,

	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IM_IF,
	input	logic			jump_ena_IF,
	input	logic			jump_alw_IF,
	input	logic			jump_ind_IF,
	input	logic			trap_ret_IF,
	input	logic	[31:0]	trap_raddr_IF,
	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,
	

	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX
);

	logic	[m-1:0]	PHT		[2**n];	// prediction history table
	logic	[n-1:0]	GBH;			// global branch history

	logic	[n-1:0]	wPtr;
	logic	[n-1:0]	rPtr;

	assign			wPtr			= GBH ^ PC_EX[n+1:2];
	assign			rPtr			= GBH ^ PC_IF[n+1:2];

	// direct jumps (jump_alw):
	// JAL is always "predicted" taken
	// JALR is always "predicted" not taken, because the jump
	// address is not known until the instruction reaches EX stage
	// MRET is also always "predicted" taken

	assign			jump_addr_IF	= trap_ret_IF ? trap_raddr : PC_IF + IM_IF;
	assign			jump_pred_IF	= valid_in && jump_ena_IF && !jump_ind_IF &&
									  (PHT[rPtr] >= 2**(n-2) || jump_alw_IF);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			// all branches are considered "strongly taken" after reset
			for (integer i = 0; i < 2**n; i = i+1)
				PHT[i]	<= -1;

			GBH	<= 0;
		end
		// only branches (!jump_alw) update the history
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