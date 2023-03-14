module FPU_core
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,
	input	logic	[2:0]	rm,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic	[31:0]	result,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE
);

	// input a
	logic	[23:0]	man_a;
	logic	[7:0]	exp_a;
	logic			sgn_a;
	logic			zero_a;
	logic			inf_a;
	logic			sNaN_a;
	logic			qNaN_a;
	logic			denormal_a;
	logic	[23:0]	man_a_norm;
	logic	[9:0]	exp_a_norm;

	// input b
	logic	[23:0]	man_b;
	logic	[7:0]	exp_b;
	logic			sgn_b;
	logic			zero_b;
	logic			inf_b;
	logic			sNaN_b;
	logic			qNaN_b;
	logic			denormal_b;
	logic 	[23:0]	man_b_norm;
	logic 	[9:0]	exp_b_norm;

	// arithmetic
	logic			ready_out_arith;
	logic			valid_out_arith;
	logic 	[31:0]	result_arith;
	logic			IV_arith;
	logic			DZ_arith;
	logic			OF_arith;
	logic			UF_arith;
	logic			IE_arith;

	// sign modifier
	logic			ready_out_sgn_mod;
	logic			valid_out_sgn_mod;
	logic	[31:0]	result_sgn_mod;

	// ftoi converter
	logic			ready_out_ftoi;
	logic			valid_out_ftoi;
	logic	[31:0]	result_ftoi;
	logic			IV_ftoi;
	logic			IE_ftoi;

	// itof converter
	logic			ready_out_itof;
	logic			valid_out_itof;
	logic	[31:0]	result_itof;
	logic			IE_itof;

	// comparator
	logic			ready_out_cmp;
	logic			valid_out_cmp;
	logic	[31:0]	result_cmp;
	logic			IV_cmp;

	// selector
	logic			ready_out_sel;
	logic			valid_out_sel;
	logic	[31:0]	result_sel;
	logic			IV_sel;

	// classifier
	logic			ready_out_class;
	logic			valid_out_class;
	logic	[31:0]	result_class;
	
	assign			ready_out	= ready_out_arith	|| ready_out_sgn_mod	||
								  ready_out_ftoi	|| ready_out_itof		||
								  ready_out_cmp 	|| ready_out_sel 		||
								  ready_out_class;

	always_comb begin
		valid_out	= valid_out_arith;
		result		= result_arith;
		IV			= IV_arith;
		DZ			= DZ_arith;
		OF			= OF_arith;
		UF			= UF_arith;
		IE			= IE_arith;

		if (valid_out_sgn_mod) begin
			valid_out	= valid_out_sgn_mod;
			result		= result_sgn_mod;
			IV			= 1'b0;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= 1'b0;
		end

		else if (valid_out_ftoi) begin
			valid_out	= valid_out_ftoi;
			result		= result_ftoi;
			IV			= IV_ftoi;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= IE_ftoi;
		end

		else if (valid_out_itof) begin
			valid_out	= valid_out_itof;
			result		= result_itof;
			IV			= 1'b0;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= IE_itof;
		end

		else if (valid_out_cmp) begin
			valid_out	= valid_out_cmp;
			result		= result_cmp;
			IV			= IV_cmp;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= 1'b0;
		end

		else if (valid_out_sel) begin
			valid_out	= valid_out_sel;
			result		= result_sel;
			IV			= IV_sel;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= 1'b0;
		end

		else if (valid_out_class) begin
			valid_out	= valid_out_class;
			result		= result_class;
			IV			= 1'b0;
			DZ			= 1'b0;
			OF			= 1'b0;
			UF			= 1'b0;
			IE			= 1'b0;
		end
	end

	splitter splitter_a
	(
		.float_in(a),

		.man(man_a),
		.Exp(exp_a),
		.sgn(sgn_a),

		.zero(zero_a),
		.inf(inf_a),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),
		.denormal(denormal_a)
	);

	pre_normalizer pre_normalizer_a
	(
		.zero(zero_a),
		.denormal(denormal_a),

		.man_in(man_a),
		.exp_in(exp_a),

		.man_out(man_a_norm),
		.exp_out(exp_a_norm)
	);

	splitter splitter_b
	(
		.float_in(b),

		.man(man_b),
		.Exp(exp_b),
		.sgn(sgn_b),

		.zero(zero_b),
		.inf(inf_b),
		.sNaN(sNaN_b),
		.qNaN(qNaN_b),
		.denormal(denormal_b)
	);

	pre_normalizer pre_normalizer_b
	(
		.zero(zero_b),
		.denormal(denormal_b),

		.man_in(man_b),
		.exp_in(exp_b),

		.man_out(man_b_norm),
		.exp_out(exp_b_norm)
	);

	float_arithmetic float_arithmetic_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_arith),
		.valid_out(valid_out_arith),
		.ready_in(ready_in),
		
		.op(op),
		.rm(rm),

		.man_a(man_a_norm),
		.exp_a(exp_a_norm),
		.sgn_a(sgn_a),
		.zero_a(zero_a),
		.inf_a(inf_a),
		.sNaN_a(sNaN_a),
		.qNaN_a(qNaN_a),

		.man_b(man_b_norm),
		.exp_b(exp_b_norm),
		.sgn_b(sgn_b),
		.zero_b(zero_b),
		.inf_b(inf_b),
		.sNaN_b(sNaN_b),
		.qNaN_b(qNaN_b),

		.float_out(result_arith),

		.IV(IV_arith),
		.DZ(DZ_arith),
		.OF(OF_arith),
		.UF(UF_arith),
		.IE(IE_arith)
	);

	sign_modifier sign_modifier_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_sgn_mod),
		.valid_out(valid_out_sgn_mod),
		.ready_in(ready_in),
		
		.op(op),

		.a(a),
		.sgn_b(b[31]),

		.float_out(result_sgn_mod)
	);

	ftoi_converter ftoi_converter_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_ftoi),
		.valid_out(valid_out_ftoi),
		.ready_in(ready_in),
		
		.op(op),
		.rm(rm),

		.man(man_a),
		.Exp(exp_a),
		.sgn(sgn_a),
		.zero(zero_a),
		.inf(inf_a),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),

		.int_out(result_ftoi),

		.IV(IV_ftoi),
		.IE(IE_ftoi)
	);

	itof_converter itof_converter_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_itof),
		.valid_out(valid_out_itof),
		.ready_in(ready_in),
		
		.op(op),
		.rm(rm),

		.int_in(a),
		.float_out(result_itof),
		.IE(IE_itof)
	);

	float_comparator_seq float_comparator_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_cmp),
		.valid_out(valid_out_cmp),
		.ready_in(ready_in),
		
		.op(op),

		.a(a),
		.b(b),

		.int_out(result_cmp),
		.IV(IV_cmp)
	);

	selector selector_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_sel),
		.valid_out(valid_out_sel),
		.ready_in(ready_in),
		
		.op(op),

		.a(a),
		.b(b),

		.float_out(result_sel),
		.IV(IV_sel)
	);

	classifier classifier_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_out(ready_out_class),
		.valid_out(valid_out_class),
		.ready_in(ready_in),
		
		.op(op),

		.sgn(sgn_a),
		.zero(zero_a),
		.inf(inf_a),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),
		.denormal(denormal_a),

		.int_out(result_class)
	);

endmodule