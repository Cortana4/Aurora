import FPU_pkg::*;

module classifier
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,

	input	logic			sgn_a,
	input	logic			zero_a,
	input	logic			inf_a,
	input	logic			sNaN_a,
	input	logic			qNaN_a,
	input	logic			denormal_a,

	output	logic	[31:0]	int_out
);
	logic	valid_in_int;
	assign	valid_in_int	= valid_in && (op == FPU_OP_CLASS);
	assign	ready_out		= ready_in;

	always_ff @(posedge clk) begin
		if (reset) begin
			int_out		<= 32'h00000000;
			valid_out	<= 1'b0;
		end

		else if (valid_in_int && ready_out) begin
			int_out		<= 32'h00000000;
			valid_out	<= 1'b1;

			// 0.0
			if (!sgn_a && zero_a)
				int_out		<= 32'h00000010;
			// -0.0
			else if (sgn_a && zero_a)
				int_out		<= 32'h00000008;
			// +inf
			else if (!sgn_a && inf_a)
				int_out		<= 32'h00000080;
			// -inf
			else if (sgn_a && inf_a)
				int_out		<= 32'h00000001;
			// sNaN
			else if (sNaN_a)
				int_out		<= 32'h00000100;
			// qNaN
			else if (qNaN_a)
				int_out		<= 32'h00000200;
			// positive normal number
			else if (!sgn_a && !denormal_a)
				int_out		<= 32'h00000040;
			// negative normal number
			else if (sgn_a && !denormal_a)
				int_out		<= 32'h00000002;
			// positive denormal number
			else if (!sgn_a && denormal_a)
				int_out	<= 32'h00000020;
			// negative denormal number
			else if (sgn_a && denormal_a)
				int_out		<= 32'h00000004;
		end

		else if (valid_out && ready_in) begin
			int_out		<= 32'h00000000;
			valid_out	<= 1'b0;
		end
	end

endmodule