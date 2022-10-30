module selector
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_min,
	input	logic			op_max,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic	[31:0]	float_out,
	output	logic			IV,

	output	logic			ready
);

	logic	greater;
	logic	equal;
	logic	less;
	logic	sNaN_a;
	logic	qNaN_a;
	logic	sNaN_b;
	logic	qNaN_b;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !(op_min || op_max))) begin
			float_out	<= 32'h00000000;
			IV			<= 1'b0;
			ready		<= 1'b0;
		end

		else if (load) begin
			if (op_min) begin
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

			else if (op_max) begin
				if ((qNaN_a || sNaN_a) && (qNaN_b || sNaN_b))
					float_out	<= 32'h7fc00000;

				else if (less || qNaN_a || sNaN_a)
					float_out	<= b;

				else if (equal)	// -0.0f < 0.0f
					float_out	<= {a[31] & b[31], a[30:0]};

				else			// greater
					float_out	<= a;
			end
			
			IV		<= sNaN_a || sNaN_b;
			ready	<= 1'b1;
		end

		else
			ready	<= 1'b0;
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
