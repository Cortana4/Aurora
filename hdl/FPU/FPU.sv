import FPU_pkg::*;

module FPU
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

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,
	input	logic	[31:0]	c,

	output	logic	[31:0]	result,

	output	logic			IV,
	output	logic			DZ,
	output	logic			OF,
	output	logic			UF,
	output	logic			IE
);
	
	logic	[4:0]	op_core;
	logic	[2:0]	rm_core;
	logic	[31:0]	a_core;
	logic	[31:0]	b_core;
	logic	[4:0]	reg_op;
	logic	[31:0]	reg_c;
	logic			wb_ena;
	
	logic			valid_in_core;
	logic			ready_out_core;
	logic			valid_out_core;
	
	logic			stall;

	assign			valid_out	= valid_out_core && !wb_ena && !flush;
	assign			ready_out	= ready_in && !stall;
	assign			stall		= reg_op != FPU_OP_NOP && !valid_out;
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_in_core	<= 1'b0;
			op_core			<= 5'd0;
			rm_core			<= 3'b000;
			a_core			<= 32'h00000000;
			b_core			<= 32'h00000000;
			reg_op			<= 5'd0;
			reg_c			<= 32'h00000000;
			wb_ena			<= 1'b0;
		end
		
		else if (valid_in && ready_out) begin
			valid_in_core	<= 1'b1;
			op_core			<= op;
			rm_core			<= rm;
			a_core			<= a;
			b_core			<= b;
			reg_op			<= op;
			reg_c			<= c;
			wb_ena			<= 1'b0;

			case (op)
			FPU_OP_MADD,
			FPU_OP_NMADD,
			FPU_OP_MSUB,
			FPU_OP_NMSUB:	begin
								op_core	<= FPU_OP_MUL;
								wb_ena	<= 1'b0;
							end
			endcase
		end
		
		else if (valid_out && ready_in) begin
			valid_in_core	<= 1'b0;
			op_core			<= 5'd0;
			rm_core			<= 3'b000;
			a_core			<= 32'h00000000;
			b_core			<= 32'h00000000;
			reg_op			<= 5'd0;
			reg_c			<= 32'h00000000;
			wb_ena			<= 1'b0;
		end
		
		else if (valid_in_core && ready_out_core)
			valid_in_core	<= 1'b0;
		
		else if (valid_out_core && wb_ena) begin
			b_core			<= reg_c;
			wb_ena			<= 1'b0;
			
			case (reg_op)
			FPU_OP_MADD,
			FPU_OP_NMSUB:	begin
								op_core	<= FPU_OP_ADD;
								a_core	<= {reg_op == FPU_OP_NMSUB ^ result[31], result[30:0]};
							end
			FPU_OP_MSUB,
			FPU_OP_NMADD:	begin
								op_core	<= FPU_OP_SUB;
								a_core	<= {reg_op == FPU_OP_NMSUB ^ result[31], result[30:0]};
							end
			endcase
		end
	end

	FPU_core FPU_core_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(flush),
		
		.valid_in(valid_in_core),
		.ready_out(ready_out_core),
		.valid_out(valid_out_core),
		.ready_in(ready_in),

		.op(op_core),
		.rm(rm_core),

		.a(a_core),
		.b(b_core),

		.result(result),

		.IV(IV),
		.DZ(DZ),
		.OF(OF),
		.UF(UF),
		.IE(IE)
	);

endmodule