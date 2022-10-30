module float_comparator_seq
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_seq,
	input	logic			op_slt,
	input	logic			op_sle,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic	[31:0]	int_out,
	output	logic			IV,

	output	logic			ready
);

	logic	y;

	logic	sNaN_a;
	logic	qNaN_a;
	logic	sNaN_b;
	logic	qNaN_b;

	logic	equal;
	logic	less;

	assign	int_out	= {31'h00000000, y};

	always_ff @(posedge clk, posedge reset) begin
		if (reset ||(load && !(op_seq || op_sle || op_slt))) begin
			y		<= 1'b0;
			IV		<= 1'b0;
			ready	<= 1'b0;
		end

		else if (load) begin
			if (op_seq) begin
				y	<= equal;
				IV	<= sNaN_a || sNaN_b;
			end

			else if (op_slt) begin
				y	<= less;
				IV	<= sNaN_a || qNaN_a || sNaN_b || qNaN_b;
			end

			else if (op_sle) begin
				y	<= less || equal;
				IV	<= sNaN_a || qNaN_a || sNaN_b || qNaN_b;
			end

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

		.greater(),
		.equal(equal),
		.less(less),
		.unordered()
	);

endmodule
