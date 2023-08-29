import FPU_pkg::*;

module sign_modifier
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,

	input	logic	[31:0]	a,
	input	logic			sgn_b,

	output	logic	[31:0]	float_out
);

	logic	sgn_a;
	assign	sgn_a			= a[31];

	logic	valid_in_int;
	assign	valid_in_int	= valid_in && (op == FPU_OP_SGNJ || op == FPU_OP_SGNJN || op == FPU_OP_SGNJX);
	assign	ready_out		= ready_in;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			float_out	<= 32'h00000000;
			valid_out	<= 1'b0;
		end

		else if (valid_in_int && ready_out) begin
			float_out	<= 32'h00000000;
			valid_out	<= 1'b1;

			case (op)
			FPU_OP_SGNJ:	float_out <= {sgn_b, a[30:0]};
			FPU_OP_SGNJN:	float_out <= {!sgn_b, a[30:0]};
			FPU_OP_SGNJX:	float_out <= {sgn_a ^ sgn_b, a[30:0]};
			endcase
		end

		else if (valid_out && ready_in) begin
			float_out	<= 32'h00000000;
			valid_out	<= 1'b0;
		end
	end

endmodule