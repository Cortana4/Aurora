import FPU_pkg::*;

module selector
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
	input	logic	[31:0]	b,

	output	logic	[31:0]	float_out,
	output	logic			IV
);

	logic	greater;
	logic	equal;
	logic	less;
	logic	sNaN_a;
	logic	qNaN_a;
	logic	sNaN_b;
	logic	qNaN_b;
	
	logic	valid_out_int;
	
	assign	valid_out	= valid_out_int && !flush;
	assign	ready_out	= ready_in && (op == FPU_OP_MIN || op == FPU_OP_MAX);

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_out_int	<= 1'b0;
			float_out		<= 32'h00000000;
			IV				<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out_int	<= 1'b1;
			float_out		<= 32'h00000000;
			IV				<= sNaN_a || sNaN_b;
			
			case (op)
			FPU_OP_MIN:	begin
							if ((qNaN_a || sNaN_a) && (qNaN_b || sNaN_b))
								float_out	<= 32'h7fc00000;

							else if (less)
								float_out	<= a;

							else if (greater || qNaN_a || sNaN_a)
								float_out	<= b;

							else if (equal)	// -0.0f < 0.0f
								float_out	<= {a[31] | b[31], a[30:0]};

							else			// less
								float_out	<= a;
						end
			FPU_OP_MAX:	begin
							if ((qNaN_a || sNaN_a) && (qNaN_b || sNaN_b))
								float_out	<= 32'h7fc00000;

							else if (less || qNaN_a || sNaN_a)
								float_out	<= b;

							else if (equal)	// -0.0f < 0.0f
								float_out	<= {a[31] & b[31], a[30:0]};

							else			// greater
								float_out	<= a;
						end
			endcase
		end

		else if (valid_out_int && ready_in) begin
			valid_out_int	<= 1'b0;
			float_out		<= 32'h00000000;
			IV				<= 1'b0;
		end
	end

	float_comparator_comb float_comparator_inst
	(
		.a(a),
		.b(b),

		.sNaN_a(sNaN_a),
		.qNaN_a(qNaN_a),
		.sNaN_b(sNaN_b),
		.qNaN_b(qNaN_b),

		.greater(greater),
		.equal(equal),
		.less(less),
		.unordered()
	);

endmodule
