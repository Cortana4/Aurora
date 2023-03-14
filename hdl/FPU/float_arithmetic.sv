module float_arithmetic
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,
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
	output	logic			IE
);

	// adder
	logic			ready_out_add;
	logic			valid_out_add;
	logic	[23:0]	man_y_add;
	logic	[9:0]	exp_y_add;
	logic			sgn_y_add;
	logic			round_bit_add;
	logic			sticky_bit_add;
	logic			IV_add;
	logic			rm_add;
	logic			skip_round_add;

	// multiplier
	logic			ready_out_mul;
	logic			valid_out_mul;
	logic	[23:0]	man_y_mul;
	logic	[9:0]	exp_y_mul;
	logic			sgn_y_mul;
	logic			round_bit_mul;
	logic			sticky_bit_mul;
	logic			IV_mul;
	logic			rm_mul;
	logic			skip_round_mul;

	// divider
	logic			ready_out_div;
	logic			valid_out_div;
	logic	[23:0]	man_y_div;
	logic	[9:0]	exp_y_div;
	logic			sgn_y_div;
	logic			round_bit_div;
	logic			sticky_bit_div;
	logic			IV_div;
	logic			DZ_div;
	logic			rm_div;
	logic			skip_round_div;

	// square root
	logic			ready_out_sqrt;
	logic			valid_out_sqrt;
	logic	[23:0]	man_y_sqrt;
	logic	[9:0]	exp_y_sqrt;
	logic			sgn_y_sqrt;
	logic			round_bit_sqrt;
	logic			sticky_bit_sqrt;
	logic			IV_sqrt;
	logic			rm_sqrt;
	logic			skip_round_sqrt;
	
	// post processor
	logic			valid_in_pp;
	logic			ready_out_pp;
	logic	[23:0]	man_y_pp;
	logic	[9:0]	exp_y_pp;
	logic			sgn_y_pp;
	logic			round_bit_pp;
	logic			sticky_bit_pp;
	logic			IV_pp;
	logic			DZ_pp;
	logic	[2:0]	rm_pp;
	logic			skip_round_pp;
	
	assign			ready_out	= ready_out_add || ready_out_mul || ready_out_div || ready_out_sqrt;

	// output selector
	always_comb begin
		valid_in_pp		= valid_out_add;
		man_y_pp		= man_y_add;
		exp_y_pp		= exp_y_add;
		sgn_y_pp		= sgn_y_add;
		round_bit_pp	= round_bit_add;
		sticky_bit_pp	= sticky_bit_add;
		IV_pp			= IV_add;
		DZ_pp			= 1'b0;
		rm_pp			= rm_add;
		skip_round_pp	= skip_round_add;

		if (valid_out_mul) begin
			valid_in_pp		= valid_out_mul;
			man_y_pp		= man_y_mul;
			exp_y_pp		= exp_y_mul;
			sgn_y_pp		= sgn_y_mul;
			round_bit_pp	= round_bit_mul;
			sticky_bit_pp	= sticky_bit_mul;
			IV_pp			= IV_mul;
			DZ_pp			= 1'b0;
			rm_pp			= rm_mul;
			skip_round_pp	= skip_round_mul;
		end

		else if (valid_out_div) begin
			valid_in_pp		= valid_out_div;
			man_y_pp		= man_y_div;
			exp_y_pp		= exp_y_div;
			sgn_y_pp		= sgn_y_div;
			round_bit_pp	= round_bit_div;
			sticky_bit_pp	= sticky_bit_div;
			IV_pp			= IV_div;
			DZ_pp			= DZ_div;
			rm_pp			= rm_div;
			skip_round_pp	= skip_round_div;
		end

		else if (valid_out_sqrt) begin
			valid_in_pp		= valid_out_sqrt;
			man_y_pp		= man_y_sqrt;
			exp_y_pp		= exp_y_sqrt;
			sgn_y_pp		= sgn_y_sqrt;
			round_bit_pp	= round_bit_sqrt;
			sticky_bit_pp	= sticky_bit_sqrt;
			IV_pp			= IV_sqrt;
			DZ_pp			= 1'b0;
			rm_pp			= rm_sqrt;
			skip_round_pp	= skip_round_sqrt;
		end
	end

	float_adder float_adder_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_out(ready_out_add),
		.valid_out(valid_out_add),
		.ready_in(ready_out_pp),

		.op(op),
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
		
		.rm_out(rm_add),
		.skip_round(skip_round_add)
	);

	float_multiplier float_multiplier_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_out(ready_out_mul),
		.valid_out(valid_out_mul),
		.ready_in(ready_out_pp),

		.op(op),
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

		.man_y(man_y_mul),
		.exp_y(exp_y_mul),
		.sgn_y(sgn_y_mul),

		.round_bit(round_bit_mul),
		.sticky_bit(sticky_bit_mul),

		.IV(IV_mul),
		
		.rm_out(rm_mul),
		.skip_round(skip_round_mul)
	);

	float_divider float_divider_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_out(ready_out_div),
		.valid_out(valid_out_div),
		.ready_in(ready_out_pp),

		.op(op),
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

		.man_y(man_y_div),
		.exp_y(exp_y_div),
		.sgn_y(sgn_y_div),

		.round_bit(round_bit_div),
		.sticky_bit(sticky_bit_div),

		.IV(IV_div),
		.DZ(DZ_div),
		
		.rm_out(rm_div),
		.skip_round(skip_round_div)
	);

	float_sqrt float_sqrt_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_out(ready_out_sqrt),
		.valid_out(valid_out_sqrt),
		.ready_in(ready_out_pp),

		.op(op),
		.rm(rm),

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
		
		.rm_out(rm_out_sqrt),
		.skip_round(skip_round_sqrt)
	);

	post_processor post_processor_inst
	(
		.clk(clk),
		.reset(reset),
		
		valid_in(valid_in_pp),
		ready_out(ready_out_pp),
		valid_out(valid_out),
		ready_in(ready_in),

		.rm(reg_rm),

		.man(man_y),
		.Exp(exp_y),
		.sgn(sgn_y),

		.round_bit(round_bit),
		.sticky_bit(sticky_bit),

		.IV_in(IV_int),
		.DZ_in(DZ_int),

		.skip_round(skip_round),

		.float_out(float_out),

		.IV(IV),
		.DZ(DZ),
		.OF(OF),
		.UF(UF),
		.IE(IE),

		.ready(ready)
	);

endmodule