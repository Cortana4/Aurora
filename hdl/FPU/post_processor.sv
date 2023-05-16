import FPU_pkg::*;

module post_processor
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[2:0]	rm,

	input	logic	[23:0]	man_in,
	input	logic	[9:0]	exp_in,
	input	logic			sgn_in,

	input	logic			round_bit,
	input	logic			sticky_bit,
	input	logic			skip_round,

	input	logic			IV_in,
	input	logic			DZ_in,

	output	logic	[31:0]	float_out,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE
);

	logic	[2:0]	reg_rm;
	logic	[22:0]	reg_man;
	logic	[9:0]	reg_exp;
	logic			reg_sgn;
	logic			reg_round_bit;
	logic			reg_sticky_bit;
	logic			reg_skip_round;
	logic			reg_equal;
	logic			reg_less;

	logic	[9:0]	exp_biased;
	logic			equal;
	logic			less;
	logic	[9:0]	offset;

	logic	[24:0]	shifter_out;
	logic			sticky_bitt;

	logic	[22:0]	man_rounded;
	logic	[9:0]	exp_rounded;
	logic			inc_exp;
	logic			inexact;

	logic			RTZ;
	logic			RDN;
	logic			RUP;

	assign			RTZ			= reg_rm == FPU_RM_RTZ;
	assign			RDN			= reg_rm == FPU_RM_RDN;
	assign			RUP			= reg_rm == FPU_RM_RUP;

	assign			ready_out	= ready_in;

	// input logic
	always_comb begin
		// add bias to exponent
		exp_biased	= exp_in + 10'h07f;

		// check if result is denormal
		equal		= ~|exp_biased;		// exp_biased == 0
		less		= exp_biased[9];	// exp_biased < 0

		/* If exp_biased is less or equal 0, the result is (probably) a denormal
		 * number and the mantissa needs to be right shifted accordingly. The only
		 * case when the result is not a denormal number, is when exp_biased equals
		 * 0 and there was a carry to the MSB of mantissa in rounding. In this case
		 * the mantissa gets shifted anyway because a carry results all mantissa
		 * bits, except for the hidden bit, to be zero. But the hidden bit is
		 * defined by the exponent anyway.
		 */

		if (equal || less) begin
			offset		= 10'd1 - exp_biased;	// calculate number of shifts needed to denormalize
			exp_biased	= 10'd0;				// exponent is 0 if result might be denormal
		end

		else
			offset = 10'd0;
	end

	// output logic
	always_comb begin
		exp_rounded	= 10'h000;
		float_out	= {reg_sgn, reg_exp[7:0], reg_man};
		OF			= 1'b0;
		UF			= 1'b0;
		IE			= 1'b0;

		if (!reg_skip_round) begin
			// rounding can cause a carry to the exponent
			exp_rounded = reg_exp + inc_exp;

			// overflow
			if (&exp_rounded[7:0] || exp_rounded[8] || exp_rounded[9]) begin
				IE = 1'b1;
				OF = 1'b1;
				UF = 1'b0;

				// setFmax
				if (RTZ || (RDN && !reg_sgn) || (RUP && reg_sgn))
					float_out = {reg_sgn, 31'h7fffffff};

				// setInf
				else
					float_out = {reg_sgn, 31'h7f800000};
			end

			else begin
				// underflow
				if (inexact && ((reg_equal && !inc_exp) || reg_less)) begin
					IE	= 1'b1;
					UF	= 1'b1;
				end

				// normal
				else begin
					IE	= inexact;
					UF	= 1'b0;
				end

				float_out = {reg_sgn, exp_rounded[7:0], man_rounded};
			end

			// If (before rounding) mantissa is 0 but round or sticky are 1
			// and man_in is still 0 after rounding, exp_in should be 0. This
			// can only happen if result is denormal but for denormal results
			// exp_in is 0 anyway
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_out		<= 1'b0;
			reg_rm			<= 3'b000;
			reg_man			<= 23'h000000;
			reg_exp			<= 10'h000;
			reg_sgn			<= 1'b0;
			reg_round_bit	<= 1'b0;
			reg_sticky_bit	<= 1'b0;
			reg_equal		<= 1'b0;
			reg_less		<= 1'b0;
			IV				<= 1'b0;
			DZ				<= 1'b0;
			reg_skip_round	<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out		<= 1'b1;
			reg_rm			<= rm;
			reg_man			<= shifter_out[23:1];
			reg_exp			<= exp_biased;
			reg_sgn			<= sgn_in;
			reg_round_bit	<= shifter_out[0];
			reg_sticky_bit	<= sticky_bit || sticky_bitt;
			reg_equal		<= equal;
			reg_less		<= less;
			IV				<= 1'b0;
			DZ				<= 1'b0;
			reg_skip_round	<= skip_round;

			if (skip_round) begin
				reg_man			<= man_in[22:0];
				reg_exp			<= exp_in;
				reg_sgn			<= sgn_in;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_equal		<= 1'b0;
				reg_less		<= 1'b0;
				IV				<= IV_in;
				DZ				<= DZ_in;
			end
		end

		else if (valid_out && ready_in) begin
			valid_out		<= 1'b0;
			reg_rm			<= 3'b000;
			reg_man			<= 23'h000000;
			reg_exp			<= 10'h000;
			reg_sgn			<= 1'b0;
			reg_round_bit	<= 1'b0;
			reg_sticky_bit	<= 1'b0;
			reg_equal		<= 1'b0;
			reg_less		<= 1'b0;
			IV				<= 1'b0;
			DZ				<= 1'b0;
			reg_skip_round	<= 1'b0;
		end
	end

	rshifter #(25, 5) rshifter_inst
	(
		.in({man_in, round_bit}),
		.sel(|offset[9:5] ? 5'b11111 : offset[4:0]),
		.sgn(1'b0),

		.out(shifter_out),
		.sticky_bit(sticky_bitt)
	);

	rounding_logic #(23) rounding_logic_inst
	(
		.rm(reg_rm),

		.sticky_bit(reg_sticky_bit),
		.round_bit(reg_round_bit),

		.in(reg_man),
		.sgn(reg_sgn),

		.out(man_rounded),
		.carry(inc_exp),

		.inexact(inexact)
	);

endmodule