module FPU_core
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_add,
	input	logic			op_sub,
	input	logic			op_mul,
	input	logic			op_div,
	input	logic			op_sqrt,
	input	logic			op_sgnj,
	input	logic			op_sgnjn,
	input	logic			op_sgnjx,
	input	logic			op_cvtfi,
	input	logic			op_cvtfu,
	input	logic			op_cvtif,
	input	logic			op_cvtuf,
	input	logic			op_seq,
	input	logic			op_slt,
	input	logic			op_sle,
	input	logic			op_class,
	input	logic			op_min,
	input	logic			op_max,

	input	logic	[2:0]	rm,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic	[31:0]	result,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE,

	output	logic			ready
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
	logic 	[31:0]	result_arith;
	logic			IV_arith;
	logic			DZ_arith;
	logic			OF_arith;
	logic			UF_arith;
	logic			IE_arith;
	logic			ready_arith;
	logic			sel_arith;

	// sign modifier
	logic	[31:0]	result_sgn_mod;
	logic			ready_sgn_mod;
	logic			sel_sgn_mod;

	// ftoi converter
	logic	[31:0]	result_ftoi;
	logic			IV_ftoi;
	logic			IE_ftoi;
	logic			ready_ftoi;
	logic			sel_ftoi;

	// itof converter
	logic	[31:0]	result_itof;
	logic			IE_itof;
	logic			ready_itof;
	logic			sel_itof;

	// comparator
	logic	[31:0]	result_cmp;
	logic			IV_cmp;
	logic			ready_cmp;
	logic			sel_cmp;

	// selector
	logic	[31:0]	result_sel;
	logic			IV_sel;
	logic			ready_sel;
	logic			sel_sel;

	// classifier
	logic	[31:0]	result_class;
	logic			ready_class;
	logic			sel_class;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			sel_arith	<= 1'b0;
			sel_sgn_mod	<= 1'b0;
			sel_ftoi	<= 1'b0;
			sel_itof	<= 1'b0;
			sel_cmp		<= 1'b0;
			sel_sel		<= 1'b0;
			sel_class	<= 1'b0;
		end

		else if (load) begin
			sel_arith	<= op_add || op_sub || op_mul || op_div || op_sqrt;
			sel_sgn_mod	<= op_sgnj || op_sgnjn || op_sgnjx;
			sel_ftoi	<= op_cvtfi || op_cvtfu;
			sel_itof	<= op_cvtif || op_cvtuf;
			sel_cmp		<= op_seq || op_slt || op_sle;
			sel_sel		<= op_min || op_max;
			sel_class	<= op_class;
		end
	end

	always_comb begin
		result		= 32'h00000000;
		IV			= 1'b0;
		DZ			= 1'b0;
		OF			= 1'b0;
		UF			= 1'b0;
		IE			= 1'b0;
		ready		= 1'b0;

		if (sel_arith) begin
			result	= result_arith;
			IV		= IV_arith;
			DZ		= DZ_arith;
			OF		= OF_arith;
			UF		= UF_arith;
			IE		= IE_arith;
			ready	= ready_arith;
		end

		else if (sel_sgn_mod) begin
			result	= result_sgn_mod;
			ready	= ready_sgn_mod;
		end

		else if (sel_ftoi) begin
			result	= result_ftoi;
			IV		= IV_ftoi;
			IE		= IE_ftoi;
			ready	= ready_ftoi;
		end

		else if (sel_itof) begin
			result	= result_itof;
			IE		= IE_itof;
			ready	= ready_itof;
		end

		else if (sel_cmp) begin
			result	= result_cmp;
			IV		= IV_cmp;
			ready	= ready_cmp;
		end

		else if (sel_sel) begin
			result	= result_sel;
			IV		= IV_sel;
			ready	= ready_sel;
		end

		else if (sel_class) begin
			result	= result_class;
			ready	= ready_class;
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
		.load(load),

		.op_add(op_add),
		.op_sub(op_sub),
		.op_mul(op_mul),
		.op_div(op_div),
		.op_sqrt(op_sqrt),

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
		.IE(IE_arith),

		.ready(ready_arith)
	);

	sign_modifier sign_modifier_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_sgnj(op_sgnj),
		.op_sgnjn(op_sgnjn),
		.op_sgnjx(op_sgnjx),

		.a(a),
		.sgn_b(b[31]),

		.float_out(result_sgn_mod),

		.ready(ready_sgn_mod)
	);

	ftoi_converter ftoi_converter_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_cvtfi(op_cvtfi),
		.op_cvtfu(op_cvtfu),
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
		.IE(IE_ftoi),

		.ready(ready_ftoi)
	);

	itof_converter itof_converter_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_cvtif(op_cvtif),
		.op_cvtuf(op_cvtuf),
		.rm(rm),

		.int_in(a),
		.float_out(result_itof),
		.IE(IE_itof),

		.ready(ready_itof)
	);

	float_comparator_seq float_comparator_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_seq(op_seq),
		.op_slt(op_slt),
		.op_sle(op_sle),

		.a(a),
		.b(b),

		.int_out(result_cmp),
		.IV(IV_cmp),

		.ready(ready_cmp)
	);

	selector selector_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_min(op_min),
		.op_max(op_max),

		.a(a),
		.b(b),

		.float_out(result_sel),
		.IV(IV_sel),

		.ready(ready_sel)
	);

	classifier classifier_inst
	(
		.clk(clk),
		.reset(reset),
		.load(load),

		.op_class(op_class),

		.sgn(sgn_a),
		.zero(zero_a),
		.inf(inf_a),
		.sNaN(sNaN_a),
		.qNaN(qNaN_a),
		.denormal(denormal_a),

		.int_out(result_class),

		.ready(ready_class)
	);

endmodule