module pre_normalizer
(
	input	logic			zero,
	input	logic			denormal,

	input	logic	[23:0]	man_in,
	input	logic	[7:0]	exp_in,

	output	logic	[23:0]	man_out,
	output	logic	[9:0]	exp_out
);

	logic	[4:0]	leading_zeros;

	always_comb begin
		// input is zero: exponent is zero
		if (zero) begin
			exp_out = 10'h000;
			man_out = 24'h000000;
		end

		// input is denormal (but not zero)
		else if (denormal) begin
			// normalize mantissa
			man_out = man_in << leading_zeros;

			//exponent is smallest possible (-126) minus the number of shifts needed to normalize
			exp_out = 10'h382 - {5'b0, leading_zeros};
		end

		else begin
			// mantissa is normalized
			man_out = man_in;

			//subtract bias from exponent
			exp_out = {2'b00, exp_in[7:0]} - 10'h07f;
		end
	end

	leading_zero_counter_24 LZC_24_inst
	(
		.in(man_in),
		.y(leading_zeros),
		.a()
	);

endmodule