module classifier
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_class,

	input	logic			sgn,
	input	logic			zero,
	input	logic			inf,
	input	logic			sNaN,
	input	logic			qNaN,
	input	logic			denormal,

	output	logic	[31:0]	int_out,

	output	logic			ready
);

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !op_class)) begin
			int_out	<= 32'h00000000;
			ready	<= 1'b0;
		end

		else if (load) begin
			// 0.0
			if (!sgn && zero)
				int_out	<= 32'h00000010;

			// -0.0
			else if (sgn && zero)
				int_out	<= 32'h00000008;

			// +inf
			else if (!sgn && inf)
				int_out	<= 32'h00000080;

			// -inf
			else if (sgn && inf)
				int_out	<= 32'h00000001;

			// sNaN
			else if (sNaN)
				int_out	<= 32'h00000100;

			// qNaN
			else if (qNaN)
				int_out	<= 32'h00000200;

			// positive normal number
			else if (!sgn && !denormal)
				int_out	<= 32'h00000040;

			// negative normal number
			else if (sgn && !denormal)
				int_out	<= 32'h00000002;

			// positive denormal number
			else if (!sgn && denormal)
				int_out	<= 32'h00000020;

			// negative denormal number
			else if (sgn && denormal)
				int_out	<= 32'h00000004;

			else
				int_out	<= 32'h00000000;

			ready	<= 1'b1;
		end

		else
			ready	<= 1'b0;
	end

endmodule