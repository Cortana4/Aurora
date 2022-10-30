module itof_converter
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_cvtif,
	input	logic			op_cvtuf,
	input	logic	[2:0]	rm,

	input	logic	[31:0]	int_in,
	output	logic	[31:0]	float_out,
	output	logic			IE,

	output	logic			ready
);

	logic	[31:0]	man_denorm;
	logic	[31:0]	man_norm;

	logic	[4:0]	leading_zeros;

	logic	[22:0]	man;
	logic	[7:0]	Exp;
	logic			sgn;

	logic			inc_exp;

	logic	[2:0]	reg_rm;
	logic			reg_sgn;

	assign			sgn			= int_in[31] && op_cvtif;
	assign			man_denorm	= sgn ? -int_in : int_in;
	assign			float_out	= {reg_sgn, Exp + inc_exp, man};

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !(op_cvtif || op_cvtuf))) begin
			reg_rm		<= 3'b000;
			man_norm	<= 32'h00000000;
			Exp			<= 8'h00;
			reg_sgn		<= 1'b0;
			ready		<= 1'b0;
		end

		else if (load) begin
			reg_rm		<= rm;
			reg_sgn		<= sgn;
			ready		<= 1'b1;

			if (|int_in) begin
				man_norm	<= man_denorm << leading_zeros;
				Exp			<= 8'h9e - leading_zeros;
			end

			else begin
				man_norm	<= 32'h00000000;
				Exp			<= 8'h00;
			end
		end

		else
			ready		<= 1'b0;
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
		.sgn(reg_sgn),

		.out(man),
		.carry(inc_exp),

		.inexact(IE)
	);

endmodule