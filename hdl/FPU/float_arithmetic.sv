module float_arithmetic
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_add,
	input	logic			op_sub,
	input	logic			op_mul,
	input	logic			op_div,
	input	logic			op_sqrt,

	input	logic	[2:0]	rm,

	input	logic	[23:0]	man_a,
	input	logic	[9:0]	exp_a,
	input	logic			sgn_a,
	input	logic			zero_a,
	input	logic			inf_a,
	input	logic			sNaN_a,
	input	logic			qNaN_a,

	input	logic	[23:0]	man_b,
	input	logic	[9:0]	exp_b,
	input	logic			sgn_b,
	input	logic			zero_b,
	input	logic			inf_b,
	input	logic			sNaN_b,
	input	logic			qNaN_b,

	output	logic	[31:0]	float_out,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE,

	output	logic			ready
);

	// adder
	logic	[23:0]	man_y_add;
	logic	[9:0]	exp_y_add;
	logic			sgn_y_add;
	logic			round_bit_add;
	logic			sticky_bit_add;
	logic			IV_add;
	logic			final_res_add;
	logic			ready_add;

	// multiplier
	logic	[23:0]	man_y_mul;
	logic	[9:0]	exp_y_mul;
	logic			sgn_y_mul;
	logic			round_bit_mul;
	logic			sticky_bit_mul;
	logic			IV_mul;
	logic			final_res_mul;
	logic			ready_mul;

	// divider
	logic	[23:0]	man_y_div;
	logic	[9:0]	exp_y_div;
	logic			sgn_y_div;
	logic			round_bit_div;
	logic			sticky_bit_div;
	logic			IV_div;
	logic			DZ_div;
	logic			final_res_div;
	logic			ready_div;

	// square root
	logic	[23:0]	man_y_sqrt;
	logic	[9:0]	exp_y_sqrt;
	logic			sgn_y_sqrt;
	logic			round_bit_sqrt;
	logic			sticky_bit_sqrt;
	logic			IV_sqrt;
	logic			final_res_sqrt;
	logic			ready_sqrt;

	// output
	logic	[23:0]	man_y;
	logic	[9:0]	exp_y;
	logic			sgn_y;
	logic			round_bit;
	logic			sticky_bit;
	logic			IV_int;
	logic			DZ_int;
	logic	[2:0]	reg_rm;
	logic			final_res;

	// output selector
	always_comb begin
		man_y		= 24'h000000;
		exp_y		= 10'h000;
		sgn_y		= 1'b0;
		round_bit	= 1'b0;
		sticky_bit	= 1'b0;
		IV_int		= 1'b0;
		DZ_int		= 1'b0;
		final_res	= 1'b0;

		if (ready_add) begin
			man_y		= man_y_add;
			exp_y		= exp_y_add;
			sgn_y		= sgn_y_add;
			round_bit	= round_bit_add;
			sticky_bit	= sticky_bit_add;
			IV_int		= IV_add;
			final_res	= final_res_add;
		end

		else if (ready_mul) begin
			man_y		= man_y_mul;
			exp_y		= exp_y_mul;
			sgn_y		= sgn_y_mul;
			round_bit	= round_bit_mul;
			sticky_bit	= sticky_bit_mul;
			IV_int		= IV_mul;
			final_res	= final_res_mul;
		end

		else if (ready_div) begin
			man_y		= man_y_div;
			exp_y		= exp_y_div;
			sgn_y		= sgn_y_div;
			round_bit	= round_bit_div;
			sticky_bit	= sticky_bit_div;
			IV_int		= IV_div;
			DZ_int		= DZ_div;
			final_res	= final_res_div;
		end

		else if (ready_sqrt) begin
			man_y		= man_y_sqrt;
			exp_y		= exp_y_sqrt;
			sgn_y		= sgn_y_sqrt;
			round_bit	= round_bit_sqrt;
			sticky_bit	= sticky_bit_sqrt;
			IV_int		= IV_sqrt;
			final_res	= final_res_sqrt;
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			reg_rm	<= 3'b000;

		else if (load)
			reg_rm	<= rm;
	end

	float_adder float_adder_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_add(op_add),
		.op_sub(op_sub),
		.rm(rm),

		.man_a(man_a),
		.exp_a(exp_a),
		.sgn_a(sgn_a),
		.zero_a(zero_a),
		.inf_a(inf_a),
		.sNaN_a(sNaN_a),
		.qNaN_a(qNaN_a),

		.man_b(man_b),
		.exp_b(exp_b),
		.sgn_b(sgn_b),
		.zero_b(zero_b),
		.inf_b(inf_b),
		.sNaN_b(sNaN_b),
		.qNaN_b(qNaN_b),

		.man_y(man_y_add),
		.exp_y(exp_y_add),
		.sgn_y(sgn_y_add),

		.round_bit(round_bit_add),
		.sticky_bit(sticky_bit_add),

		.IV(IV_add),

		.final_res(final_res_add),
		.ready(ready_add)
	);

	float_multiplier float_multiplier_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),
		
		.op_mul(op_mul),

		.man_a(man_a),
		.exp_a(exp_a),
		.sgn_a(sgn_a),
		.zero_a(zero_a),
		.inf_a(inf_a),
		.sNaN_a(sNaN_a),
		.qNaN_a(qNaN_a),

		.man_b(man_b),
		.exp_b(exp_b),
		.sgn_b(sgn_b),
		.zero_b(zero_b),
		.inf_b(inf_b),
		.sNaN_b(sNaN_b),
		.qNaN_b(qNaN_b),

		.man_y(man_y_mul),
		.exp_y(exp_y_mul),
		.sgn_y(sgn_y_mul),

		.round_bit(round_bit_mul),
		.sticky_bit(sticky_bit_mul),

		.IV(IV_mul),

		.final_res(final_res_mul),
		.ready(ready_mul)
	);

	float_divider float_divider_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),
		
		.op_div(op_div),

		.man_a(man_a),
		.exp_a(exp_a),
		.sgn_a(sgn_a),
		.zero_a(zero_a),
		.inf_a(inf_a),
		.sNaN_a(sNaN_a),
		.qNaN_a(qNaN_a),

		.man_b(man_b),
		.exp_b(exp_b),
		.sgn_b(sgn_b),
		.zero_b(zero_b),
		.inf_b(inf_b),
		.sNaN_b(sNaN_b),
		.qNaN_b(qNaN_b),

		.man_y(man_y_div),
		.exp_y(exp_y_div),
		.sgn_y(sgn_y_div),

		.round_bit(round_bit_div),
		.sticky_bit(sticky_bit_div),

		.IV(IV_div),
		.DZ(DZ_div),

		.final_res(final_res_div),
		.ready(ready_div)
	);

	float_sqrt float_sqrt_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),
		
		.op_sqrt(op_sqrt),

		.man(man_a),
		.Exp(exp_a),
		.sgn(sgn_a),
		.zero(zero_a),
		.inf(inf_a),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),

		.man_y(man_y_sqrt),
		.exp_y(exp_y_sqrt),
		.sgn_y(sgn_y_sqrt),

		.round_bit(round_bit_sqrt),
		.sticky_bit(sticky_bit_sqrt),

		.IV(IV_sqrt),

		.final_res(final_res_sqrt),
		.ready(ready_sqrt)
	);

	post_processing post_processing_inst
	(
		.clk(clk),
		.reset(reset),
		.clear(load),
		.load(ready_add || ready_mul || ready_div || ready_sqrt),

		.rm(reg_rm),

		.man(man_y),
		.Exp(exp_y),
		.sgn(sgn_y),

		.round_bit(round_bit),
		.sticky_bit(sticky_bit),

		.IV_in(IV_int),
		.DZ_in(DZ_int),

		.final_res(final_res),

		.float_out(float_out),

		.IV(IV),
		.DZ(DZ),
		.OF(OF),
		.UF(UF),
		.IE(IE),

		.ready(ready)
	);

endmodule