module float_comparator_comb
(
	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic			sNaN_a,
	output	logic			qNaN_a,
	output	logic			sNaN_b,
	output	logic			qNaN_b,

	output	logic			greater,
	output	logic			equal,
	output	logic			less,
	output	logic			unordered
);

	// input a
	logic			sgn_a;
	logic	[23:0]	man_a;
	logic	[7:0]	exp_a;
	logic			zero_a;

	splitter splitter_a
	(
		.float_in(a),

		.man(man_a),
		.Exp(exp_a),
		.sgn(sgn_a),

		.zero(zero_a),
		.inf(),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),
		.denormal()
	);

	// input b
	logic			sgn_b;
	logic	[23:0]	man_b;
	logic	[7:0]	exp_b;
	logic			zero_b;

	splitter splitter_b
	(
		.float_in(b),

		.man(man_b),
		.Exp(exp_b),
		.sgn(sgn_b),

		.zero(zero_b),
		.inf(),
		.sNaN(sNaN_b),
		.qNaN(qNaN_b),
		.denormal()
	);

	logic	sgn_a_int;
	logic	sgn_b_int;

	assign	sgn_a_int	= sgn_a && !zero_a;
	assign	sgn_b_int	= sgn_b && !zero_b;
	assign	unordered	= sNaN_a || qNaN_a || sNaN_b || qNaN_b;

	always_comb begin
		if (unordered) begin
			greater	= 1'b0;
			equal	= 1'b0;
			less	= 1'b0;
		end

		else begin
			if (exp_a == exp_b) begin
				greater = man_a > man_b;
				less	= man_a < man_b;
			end

			else begin
				greater = exp_a > exp_b;
				less	= exp_a < exp_b;
			end

			if ((greater && sgn_a_int) || (less && sgn_b_int)) begin
				greater	= !greater;
				less	= !less;
			end

			equal = !(greater || less);

			// equal magnitude, different signs
			if (equal && (sgn_a_int ^ sgn_b_int)) begin
				greater	= sgn_b_int;
				less	= sgn_a_int;
				equal	= !(greater || less);
			end
		end
	end

endmodule