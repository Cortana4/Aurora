import FPU_pkg::*;

module itof_converter
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,
	input	logic	[2:0]	rm,

	input	logic	[31:0]	int_in,
	output	logic	[31:0]	float_out,
	output	logic			IE
);

	logic	[31:0]	man_denorm;
	logic	[31:0]	man_norm;

	logic	[4:0]	leading_zeros;

	logic	[22:0]	man_y;
	logic	[7:0]	exp_y;
	logic			sgn_y;

	logic			inc_exp;

	logic	[2:0]	reg_rm;
	logic			reg_sgn_y;

	assign			sgn_y		= int_in[31] && op == FPU_OP_CVTIF;
	assign			man_denorm	= sgn_y ? -int_in : int_in;
	assign			float_out	= {reg_sgn_y, exp_y + inc_exp, man_y};
	
	assign			ready_out	= ready_in && (op == FPU_OP_CVTIF || op == FPU_OP_CVTUF);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out	<= 1'b0;
			reg_rm		<= 3'b000;
			man_norm	<= 32'h00000000;
			exp_y		<= 8'h00;
			reg_sgn_y	<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out	<= 1'b1;
			reg_rm		<= rm;
			man_norm	<= 32'h00000000;
			exp_y		<= 8'h00;
			reg_sgn_y	<= sgn_y;

			if (|int_in) begin
				man_norm	<= man_denorm << leading_zeros;
				exp_y		<= 8'h9e - leading_zeros;
			end
		end

		else if (valid_out && ready_in) begin
			valid_out	<= 1'b0;
			reg_rm		<= 3'b000;
			man_norm	<= 32'h00000000;
			exp_y		<= 8'h00;
			reg_sgn_y	<= 1'b0;
		end
	end

	leading_zero_counter_32 LZC_32_inst
	(
		.in(man_denorm),
		.y(leading_zeros),
		.a()
	);

	rounding_logic #(23) rounding_logic_inst
	(
		.rm(reg_rm),

		.sticky_bit(|man_norm[6:0]),
		.round_bit(man_norm[7]),

		.in(man_norm[30:8]),
		.sgn(reg_sgn_y),

		.out(man_y),
		.carry(inc_exp),

		.inexact(IE)
	);

endmodule