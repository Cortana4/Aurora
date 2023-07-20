// gshare branch prediction

module branch_predictor
#(
	parameter	n			= 2,	// considered PC bits
	parameter	INFER_RAM	= 1		// add/remove PHT reset and thus
)									// infer registers or distributed RAM
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	input	logic			ready_in,

	input	logic	[31:0]	trap_raddr_csr,

	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IM_IF,
	input	logic			jump_ena_IF,
	input	logic			jump_alw_IF,
	input	logic			jump_ind_IF,
	input	logic			trap_ret_IF,
	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,

	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX
);

	// prediction history table (PHT), global branch history (GBH)
	// all branches are initially considered "strongly taken"
	logic	[1:0]	PHT		[2**n]	= '{default: 2'b11};
	logic	[n-1:0]	GBH;

	logic	[n-1:0]	wPtr;
	logic	[n-1:0]	rPtr;
	assign			wPtr			= GBH ^ PC_EX[n+1:2];
	assign			rPtr			= GBH ^ PC_IF[n+1:2];

	// only branches (!jump_alw) update the history
	logic			update_history;
	assign			update_history	= ready_in && jump_ena_EX && !jump_alw_EX;

	// direct jumps (jump_alw):
	// JAL	is always "predicted" taken
	// JALR	is always "predicted" not taken, because the jump
	// 		address is not known until the instruction reaches EX stage
	// MRET	is also always "predicted" taken
	assign			jump_addr_IF	= trap_ret_IF ? trap_raddr_csr : PC_IF + IM_IF;
	assign			jump_pred_IF	= valid_in && jump_ena_IF && !jump_ind_IF &&
									  (PHT[rPtr][1] || jump_alw_IF);

	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			GBH	<= 0;

		else if (update_history)
			GBH	<= (GBH << 1) | jump_taken_EX;
	end

	generate
		if (INFER_RAM) begin
			always_ff @(posedge clk) begin
				if (update_history) begin
					if (jump_taken_EX)
						PHT[wPtr]	<= PHT[wPtr] + ~&PHT[wPtr];
					else
						PHT[wPtr]	<= PHT[wPtr] - |PHT[wPtr];
				end
			end
		end
		
		else begin
			always_ff @(posedge clk, posedge reset) begin
				if (reset) begin
					for (integer i = 0; i < 2**n; i = i+1)
						PHT[i]		<= 2'b11;
				end

				else if (update_history) begin
					if (jump_taken_EX)
						PHT[wPtr]	<= PHT[wPtr] + ~&PHT[wPtr];

					else
						PHT[wPtr]	<= PHT[wPtr] - |PHT[wPtr];
				end
			end
		end
	endgenerate

endmodule