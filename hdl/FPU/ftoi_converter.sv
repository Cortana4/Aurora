import FPU_pkg::*;

module ftoi_converter
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,
	input	logic	[2:0]	rm,

	input	logic	[23:0]	man_a,
	input	logic	[7:0]	exp_a,
	input	logic			sgn_a,
	input	logic			zero_a,
	input	logic			inf_a,
	input	logic			sNaN_a,
	input	logic			qNaN_a,

	output	logic	[31:0]	int_out,

	output	logic			IV,
	output	logic			IE
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
	logic			skip_round;

	logic	[31:0]	int_rounded;
	logic			inexact;

	logic			lower_limit_exc;
	logic			upper_limit_exc;
	logic			rounded_zero;

	assign			lower_limit_exc	= inf_a && sgn_a;
	assign			upper_limit_exc	= (inf_a && !sgn_a) || sNaN_a || qNaN_a;
	assign			rounded_zero	= op == FPU_OP_CVTFU && sgn_a;

	assign			offset			= 8'h9e - exp_a;
	
	/* calculate offset:
	 *   31 - exp_unbiased
	 * = 31 + bias - (exp_unbiased + bias)
	 * = 31 + bias - exp_biased
	 * = 31 + 127 - exp_biased
	 */

	assign			ready_out		= ready_in && (op == FPU_OP_CVTFI || op == FPU_OP_CVTFU);

	always_comb begin
		if (skip_round) begin
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
		if (reset || flush) begin
			valid_out		<= 1'b0;
			reg_rm			<= 3'b000;
			reg_int			<= 32'h00000000;
			reg_sgn			<= 1'b0;
			reg_round_bit	<= 1'b0;
			reg_sticky_bit	<= 1'b0;
			reg_IV			<= 1'b0;
			reg_IE			<= 1'b0;
			negate			<= 1'b0;
			skip_round		<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out		<= 1'b1;
			reg_rm			<= rm;
			reg_int			<= shifter_out[32:1];
			reg_sgn			<= sgn_a;
			reg_round_bit	<= shifter_out[0];
			reg_sticky_bit	<= sticky_bit;
			reg_IV			<= 1'b0;
			reg_IE			<= 1'b0;
			negate			<= op == FPU_OP_CVTFI && sgn_a;
			skip_round		<= 1'b0;

			// implemented non signaling IE (IEEE 754 2019 p. 39f)
			// input is below lower limit
			if (less || lower_limit_exc) begin
				reg_int			<= op == FPU_OP_CVTFI ? 32'h80000000 : 32'h00000000;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b1;
				reg_IE			<= lower_limit_exc;
				negate			<= 1'b0;
				skip_round		<= 1'b1;
			end
			// input is above upper limit or NaN
			else if (greater || upper_limit_exc) begin
				reg_int			<= op == FPU_OP_CVTFI ? 32'h7fffffff : 32'hffffffff;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b1;
				reg_IE			<= upper_limit_exc;
				negate			<= 1'b0;
				skip_round		<= 1'b1;
			end
			// rounded input is zero
			else if (zero_a || rounded_zero) begin
				reg_int			<= 32'h0000000;
				reg_round_bit	<= 1'b0;
				reg_sticky_bit	<= 1'b0;
				reg_IV			<= 1'b0;
				reg_IE			<= rounded_zero;
				negate			<= 1'b0;
				skip_round		<= 1'b1;
			end
		end

		else if (valid_out && ready_in) begin
			valid_out		<= 1'b0;
			reg_rm			<= 3'b000;
			reg_int			<= 32'h00000000;
			reg_sgn			<= 1'b0;
			reg_round_bit	<= 1'b0;
			reg_sticky_bit	<= 1'b0;
			reg_IV			<= 1'b0;
			reg_IE			<= 1'b0;
			negate			<= 1'b0;
			skip_round		<= 1'b0;
		end
	end

	always_comb begin
		// set min and max valid int value to compare
		if (op == FPU_OP_CVTFI) begin
			cmp_min	= 32'hcf000000;
			cmp_max	= 32'h4effffff;
		end
		// set min and max valid unsigned int value to compare
		else begin
			// inputs less than 0.0 are normally invalid
			// inputs less than 0.0 but greater than -1.0
			// can be valid if rounded to 0.0
			case (rm)
			FPU_RM_RNE:	cmp_min = 32'hbf700000; // < -0.5
			FPU_RM_RTZ,
			FPU_RM_RUP:	cmp_min = 32'hbf7fffff; // < -0.99...
			FPU_RM_RMM:	cmp_min = 32'hbeffffff; // < -0.49...
			default:	cmp_min = 32'h00000000; // <  0.0
			endcase

			cmp_max	= 32'h4f7fffff;
		end
	end

	float_comparator_comb float_comparator_inst_1
	(
		.a({sgn_a, exp_a, man_a[22:0]}),
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
		.a({sgn_a, exp_a, man_a[22:0]}),
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
		.in({man_a, 9'h00}),
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