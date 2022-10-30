`include "FPU_constants.svh"

module ftoi_converter
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_cvtfi,
	input	logic			op_cvtfu,
	input	logic	[2:0]	rm,

	input	logic	[23:0]	man,
	input	logic	[7:0]	Exp,
	input	logic			sgn,
	input	logic			zero,
	input	logic			inf,
	input	logic			sNaN,
	input	logic			qNaN,

	output	logic	[31:0]	int_out,

	output	logic			IV,
	output	logic			IE,

	output	logic			ready
);

	logic	[31:0]	cmp_min;
	logic			less;

	logic	[31:0]	cmp_max;
	logic			greater;

	logic	[7:0]	offset;
	logic	[32:0]	shifter_out;
	logic			sticky_bit;

	logic	[2:0]	reg_rm;
	logic	[31:0]	reg_int;
	logic			reg_sgn;
	logic			reg_round_bit;
	logic			reg_sticky_bit;
	logic			reg_IV;
	logic			reg_IE;
	logic			negate;
	logic			final_res;

	logic	[31:0]	int_rounded;
	logic			inexact;

	logic			lower_limit_exc;
	logic			upper_limit_exc;
	logic			rounded_zero;

	assign			lower_limit_exc	= inf && sgn;
	assign			upper_limit_exc	= (inf && !sgn) || sNaN || qNaN;
	assign			rounded_zero	= op_cvtfu && sgn;

	assign			offset			= 8'h9e - Exp;

	/* calculate offset:
	 *   31 - exp_unbiased
	 * = 31 + bias - (exp_unbiased + bias)
	 * = 31 + bias - exp_biased
	 * = 31 + 127 - exp_biased
	 */

	always_comb begin
		if (final_res) begin
			int_out	= reg_int;
			IV		= reg_IV;
			IE		= reg_IE;
		end

		else begin
			int_out	= negate ? -int_rounded : int_rounded;
			IV		= reg_IV;
			IE		= inexact;
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !(op_cvtfi || op_cvtfu))) begin
			reg_rm			<= 3'b000;
			reg_int			<= 32'h00000000;
			reg_sgn			<= 1'b0;
			reg_round_bit	<= 1'b0;
			reg_sticky_bit	<= 1'b0;
			reg_IV			<= 1'b0;
			reg_IE			<= 1'b0;
			negate			<= 1'b0;
			final_res		<= 1'b0;
			ready			<= 1'b0;
		end

		else if (load) begin
			reg_rm	<= rm;
			reg_sgn	<= sgn;
			ready	<= 1'b1;
			// implemented non signaling IE (IEEE 754 2019 p. 39f)
			// input is below lower limit
			if (less || lower_limit_exc) begin
				reg_int			<= op_cvtfi ? 32'h80000000 : 32'h00000000;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b1;
				reg_IE			<= lower_limit_exc;
				negate			<= 1'b0;
				final_res		<= 1'b1;
			end
			// input is above upper limit or NaN
			else if (greater || upper_limit_exc) begin
				reg_int			<= op_cvtfi ? 32'h7fffffff : 32'hffffffff;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b1;
				reg_IE			<= upper_limit_exc;
				negate			<= 1'b0;
				final_res		<= 1'b1;
			end
			// rounded input is zero
			else if (zero || rounded_zero) begin
				reg_int			<= 32'h0000000;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b0;
				reg_IE			<= rounded_zero;
				negate			<= 1'b0;
				final_res		<= 1'b1;
			end

			else begin
				reg_int			<= shifter_out[32:1];
				reg_round_bit	<= shifter_out[0];
				reg_sticky_bit	<= sticky_bit;
				reg_IV			<= 1'b0;
				reg_IE			<= 1'b0;
				negate			<= op_cvtfi && sgn;
				final_res		<= 1'b0;
			end
		end

		else
			ready			<= 1'b0;
	end

	always_comb begin
		// set min and max valid int value to compare
		if (op_cvtfi) begin
			cmp_min	= 32'hcf000000;
			cmp_max	= 32'h4effffff;
		end
		// set min and max valid unsigned int value to compare
		else begin
			// inputs less than 0.0 are normally invalid
			// inputs less than 0.0 but greater than -1.0
			// can be valid if rounded to 0.0
			case (rm)
			`FPU_RM_RNE:	cmp_min = 32'hbf700000; // < -0.5
			`FPU_RM_RTZ,
			`FPU_RM_RUP:	cmp_min = 32'hbf7fffff; // < -0.99...
			`FPU_RM_RMM:	cmp_min = 32'hbeffffff; // < -0.49...
			default:		cmp_min = 32'h00000000; // <  0.0
			endcase

			cmp_max	= 32'h4f7fffff;
		end
	end

	float_comparator_comb float_comparator_inst_1
	(
		.a({sgn, Exp, man[22:0]}),
		.b(cmp_min),

		.sNaN_a(),
		.qNaN_a(),
		.sNaN_b(),
		.qNaN_b(),

		.greater(),
		.equal(),
		.less(less),
		.unordered()
	);

	float_comparator_comb float_comparator_inst_2
	(
		.a({sgn, Exp, man[22:0]}),
		.b(cmp_max),

		.sNaN_a(),
		.qNaN_a(),
		.sNaN_b(),
		.qNaN_b(),

		.greater(greater),
		.equal(),
		.less(),
		.unordered()
	);

	rshifter #(33, 6) rshifter_inst
	(
		.in({man, 9'h00}),
		.sel(|offset[7:6] ? 6'b111111 : offset[5:0]),
		.sgn(1'b0),

		.out(shifter_out),
		.sticky_bit(sticky_bit)
	);

	rounding_logic #(32) rounding_logic_inst
	(
		.rm(reg_rm),

		.sticky_bit(reg_sticky_bit),
		.round_bit(reg_round_bit),

		.in(reg_int),
		.sgn(reg_sgn),

		.out(int_rounded),
		.carry(),

		.inexact(inexact)
	);

endmodule