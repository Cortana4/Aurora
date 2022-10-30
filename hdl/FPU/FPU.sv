`include "FPU_constants.svh"

module FPU
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic	[4:0]	op,
	input	logic	[2:0]	rm,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,
	input	logic	[31:0]	c,

	output	logic	[31:0]	result,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE,

	output	logic			busy,
	output	logic			ready
);

	logic			reg_load;
	logic	[4:0]	reg_op;
	logic	[2:0]	reg_rm;
	logic	[31:0]	reg_a;
	logic	[31:0]	reg_b;
	logic	[31:0]	reg_c;

	logic			reg_op_add;
	logic			reg_op_sub;
	logic			reg_op_mul;
	logic			reg_op_div;
	logic			reg_op_sqrt;
	logic			reg_op_sgnj;
	logic			reg_op_sgnjn;
	logic			reg_op_sgnjx;
	logic			reg_op_cvtfi;
	logic			reg_op_cvtfu;
	logic			reg_op_cvtif;
	logic			reg_op_cvtuf;
	logic			reg_op_seq;
	logic			reg_op_slt;
	logic			reg_op_sle;
	logic			reg_op_class;
	logic			reg_op_min;
	logic			reg_op_max;

	logic			loaded;
	logic			wb_ena;
	logic			wb;
	logic			ready_int;

	assign			busy		= loaded && !ready;
	assign			ready		= !wb_ena && ready_int;
	assign			wb			=  wb_ena && ready_int;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			reg_load		<= 1'b0;
			reg_op			<= 5'd0;
			reg_rm			<= 3'h0;
			reg_a			<= 32'h00000000;
			reg_b			<= 32'h00000000;
			reg_c			<= 32'h00000000;
			reg_op_add		<= 1'b0;
			reg_op_sub		<= 1'b0;
			reg_op_mul		<= 1'b0;
			reg_op_div		<= 1'b0;
			reg_op_sqrt		<= 1'b0;
			reg_op_sgnj		<= 1'b0;
			reg_op_sgnjn	<= 1'b0;
			reg_op_sgnjx	<= 1'b0;
			reg_op_cvtfi	<= 1'b0;
			reg_op_cvtfu	<= 1'b0;
			reg_op_cvtif	<= 1'b0;
			reg_op_cvtuf	<= 1'b0;
			reg_op_seq		<= 1'b0;
			reg_op_slt		<= 1'b0;
			reg_op_sle		<= 1'b0;
			reg_op_class	<= 1'b0;
			reg_op_min		<= 1'b0;
			reg_op_max		<= 1'b0;
		end

		else if (load) begin
			reg_load		<= 1'b1;
			reg_op			<= op;
			reg_rm			<= rm;
			reg_a			<= a;
			reg_b			<= b;
			reg_c			<= c;
			reg_op_add		<= op == `FPU_OP_ADD;
			reg_op_sub		<= op == `FPU_OP_SUB;
			reg_op_mul		<= op == `FPU_OP_MUL  ||
							   op == `FPU_OP_MADD || op == `FPU_OP_NMADD ||
							   op == `FPU_OP_MSUB || op == `FPU_OP_NMSUB;
			reg_op_div		<= op == `FPU_OP_DIV;
			reg_op_sqrt		<= op == `FPU_OP_SQRT;
			reg_op_sgnj		<= op == `FPU_OP_SGNJ;
			reg_op_sgnjn	<= op == `FPU_OP_SGNJN;
			reg_op_sgnjx	<= op == `FPU_OP_SGNJX;
			reg_op_cvtfi	<= op == `FPU_OP_CVTFI;
			reg_op_cvtfu	<= op == `FPU_OP_CVTFU;
			reg_op_cvtif	<= op == `FPU_OP_CVTIF;
			reg_op_cvtuf	<= op == `FPU_OP_CVTUF;
			reg_op_seq		<= op == `FPU_OP_SEQ;
			reg_op_slt		<= op == `FPU_OP_SLT;
			reg_op_sle		<= op == `FPU_OP_SLE;
			reg_op_class	<= op == `FPU_OP_CLASS;
			reg_op_min		<= op == `FPU_OP_MIN;
			reg_op_max		<= op == `FPU_OP_MAX;
		end
		
		else if (wb) begin
			reg_load		<= 1'b1;
			reg_a			<= reg_op == `FPU_OP_NMADD || reg_op == `FPU_OP_NMSUB ?
							   {!result[31], result[30:0]} : result;
			reg_b			<= reg_c;
			reg_op_add		<= reg_op == `FPU_OP_MADD || reg_op == `FPU_OP_NMSUB;
			reg_op_sub		<= reg_op == `FPU_OP_MSUB || reg_op == `FPU_OP_NMADD;
			reg_op_mul		<= 1'b0;
		end

		else
			reg_load	<= 1'b0;
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			loaded		<= 1'b0;
			wb_ena		<= 1'b0;
		end

		else if (load) begin
			loaded		<= 1'b1;
			wb_ena		<= op == `FPU_OP_MADD || op == `FPU_OP_NMSUB ||
						   op == `FPU_OP_MSUB || op == `FPU_OP_NMADD;
		end

		else if (wb)
			wb_ena		<= 1'b0;

		else if (ready)
			loaded		<= 1'b0;
	end

	FPU_core FPU_core_inst
	(
		.clk(clk),
		.reset(reset),
		.load(reg_load),

		.op_add(reg_op_add),
		.op_sub(reg_op_sub),
		.op_mul(reg_op_mul),
		.op_div(reg_op_div),
		.op_sqrt(reg_op_sqrt),
		.op_sgnj(reg_op_sgnj),
		.op_sgnjn(reg_op_sgnjn),
		.op_sgnjx(reg_op_sgnjx),
		.op_cvtfi(reg_op_cvtfi),
		.op_cvtfu(reg_op_cvtfu),
		.op_cvtif(reg_op_cvtif),
		.op_cvtuf(reg_op_cvtuf),
		.op_seq(reg_op_seq),
		.op_slt(reg_op_slt),
		.op_sle(reg_op_sle),
		.op_class(reg_op_class),
		.op_min(reg_op_min),
		.op_max(reg_op_max),

		.rm(reg_rm),

		.a(reg_a),
		.b(reg_b),

		.result(result),

		.IV(IV),
		.DZ(DZ),
		.OF(OF),
		.UF(UF),
		.IE(IE),

		.ready(ready_int)
	);

endmodule