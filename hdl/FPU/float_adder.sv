import FPU_pkg::*;

module float_adder
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

	output	logic	[23:0]	man_y,
	output	logic	[9:0]	exp_y,
	output	logic			sgn_y,

	output	logic			round_bit,
	output	logic			sticky_bit,
	output	logic			skip_round,

	output	logic			IV,

	output	logic	[2:0]	rm_out
);

	logic			[23:0]	reg_man_a;
	logic	signed	[9:0]	reg_exp_a;
	logic					reg_sgn_a;
	logic					reg_zero_a;
	logic					reg_inf_a;
	logic					reg_sNaN_a;
	logic					reg_qNaN_a;
	logic			[23:0]	reg_man_b;
	logic	signed	[9:0]	reg_exp_b;
	logic					reg_sgn_b;
	logic					reg_zero_b;
	logic					reg_inf_b;
	logic					reg_sNaN_b;
	logic					reg_qNaN_b;
	logic					reg_sub;

	logic					sgn_b_int;
	logic					sub_int;

	logic			[9:0]	align;
	logic			[25:0]	shifter_in;
	logic			[25:0]	shifter_out;

	logic					guard_bit;
	logic					sticky_bit_int;

	logic			[24:0]	sum;

	logic			[4:0]	leading_zeros;
	
	logic					valid_out_int;
	logic					stall;

	enum	logic	[2:0]	{IDLE, INIT, ALIGN, ADD, NORM} state;

	assign	sgn_b_int		= sgn_b ^ (op == FPU_OP_SUB);
	assign	sub_int			= sgn_a ^ sgn_b_int;

	assign	align			= reg_exp_a - reg_exp_b;
	assign	shifter_in		= reg_sub ? -{reg_man_b, 2'b00} : {reg_man_b, 2'b00};

	assign	valid_out		= valid_out_int && !flush;
	assign	ready_out		= ready_in && !stall && (op == FPU_OP_ADD || op == FPU_OP_SUB);
	assign	stall			= state != IDLE;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_out_int	<= 1'b0;
			reg_man_a		<= 24'h000000;
			reg_exp_a		<= 10'h000;
			reg_sgn_a		<= 1'b0;
			reg_zero_a		<= 1'b0;
			reg_inf_a		<= 1'b0;
			reg_sNaN_a		<= 1'b0;
			reg_qNaN_a		<= 1'b0;
			reg_man_b		<= 24'h000000;
			reg_exp_b		<= 10'h000;
			reg_sgn_b		<= 1'b0;
			reg_zero_b		<= 1'b0;
			reg_inf_b		<= 1'b0;
			reg_sNaN_b		<= 1'b0;
			reg_qNaN_b		<= 1'b0;
			reg_sub			<= 1'b0;
			man_y			<= 24'h000000;
			exp_y			<= 10'h000;
			sgn_y			<= 1'b0;
			guard_bit		<= 1'b0;
			round_bit		<= 1'b0;
			sticky_bit		<= 1'b0;
			skip_round		<= 1'b0;
			IV				<= 1'b0;
			sum				<= 25'h0000000;
			rm_out			<= 3'b000;
			state			<= IDLE;
		end

		else if (valid_in && ready_out) begin
			valid_out_int	<= 1'b0;
			reg_man_a		<= man_a;
			reg_exp_a		<= exp_a;
			reg_sgn_a		<= sgn_a;
			reg_zero_a		<= zero_a;
			reg_inf_a		<= inf_a;
			reg_sNaN_a		<= sNaN_a;
			reg_qNaN_a		<= qNaN_a;
			reg_man_b		<= man_b;
			reg_exp_b		<= exp_b;
			reg_sgn_b		<= sgn_b_int;
			reg_zero_b		<= zero_b;
			reg_inf_b		<= inf_b;
			reg_sNaN_b		<= sNaN_b;
			reg_qNaN_b		<= qNaN_b;
			reg_sub			<= sub_int;
			man_y			<= 24'h000000;
			exp_y			<= 10'h000;
			sgn_y			<= 1'b0;
			guard_bit		<= 1'b0;
			round_bit		<= 1'b0;
			sticky_bit		<= 1'b0;
			skip_round		<= 1'b0;
			IV				<= 1'b0;
			sum				<= 25'h0000000;
			rm_out			<= rm;
			state			<= INIT;
		end

		else case (state)
			IDLE:	if (valid_out_int && ready_in) begin
						valid_out_int	<= 1'b0;
						reg_man_a		<= 24'h000000;
						reg_exp_a		<= 10'h000;
						reg_sgn_a		<= 1'b0;
						reg_zero_a		<= 1'b0;
						reg_inf_a		<= 1'b0;
						reg_sNaN_a		<= 1'b0;
						reg_qNaN_a		<= 1'b0;
						reg_man_b		<= 24'h000000;
						reg_exp_b		<= 10'h000;
						reg_sgn_b		<= 1'b0;
						reg_zero_b		<= 1'b0;
						reg_inf_b		<= 1'b0;
						reg_sNaN_b		<= 1'b0;
						reg_qNaN_b		<= 1'b0;
						reg_sub			<= 1'b0;
						man_y			<= 24'h000000;
						exp_y			<= 10'h000;
						sgn_y			<= 1'b0;
						guard_bit		<= 1'b0;
						round_bit		<= 1'b0;
						sticky_bit		<= 1'b0;
						skip_round		<= 1'b0;
						IV				<= 1'b0;
						sum				<= 25'h0000000;
						rm_out			<= 3'b000;
						state			<= IDLE;
					end

			INIT:	begin
						// NaN
						if (reg_sNaN_a || reg_sNaN_b || reg_qNaN_a || reg_qNaN_b ||
							(reg_sub && reg_inf_a && reg_inf_b)) begin
							valid_out_int	<= 1'b1;
							man_y			<= 24'hc00000;
							exp_y			<= 10'h0ff;
							sgn_y			<= 1'b0;
							skip_round		<= 1'b1;
							IV				<= ~(reg_qNaN_a || reg_qNaN_b);
							state			<= IDLE;
						end
						// inf
						else if (reg_inf_a || reg_inf_b) begin
							valid_out_int	<= 1'b1;
							man_y			<= 24'h800000;
							exp_y			<= 10'h0ff;
							sgn_y			<= reg_sgn_a;
							skip_round		<= 1'b1;
							state			<= IDLE;
						end
						// zero (0 +- 0)
						else if (reg_zero_a && reg_zero_b) begin
							valid_out_int	<= 1'b1;
							sgn_y			<= reg_sgn_a && reg_sgn_b;
							skip_round		<= 1'b1;
							state			<= IDLE;
						end
						// zero (x - x)
						else if (reg_exp_a == reg_exp_b &&
								 reg_man_a == reg_man_b && reg_sub) begin
							valid_out_int	<= 1'b1;
							sgn_y			<= rm_out == FPU_RM_RDN;
							skip_round		<= 1'b1;
							state			<= IDLE;
						end
						// a
						else if (reg_zero_b) begin
							valid_out_int	<= 1'b1;
							man_y			<= reg_man_a;
							exp_y			<= reg_exp_a;
							sgn_y			<= reg_sgn_a;
							skip_round		<= 1'b0;
							state			<= IDLE;
						end
						// b
						else if (reg_zero_a) begin
							valid_out_int	<= 1'b1;
							man_y			<= reg_man_b;
							exp_y			<= reg_exp_b;
							sgn_y			<= reg_sgn_b;
							skip_round		<= 1'b0;
							state			<= IDLE;
						end
						// swap inputs if abs(a) < abs(b)
						else if ((reg_zero_a && !reg_zero_b) || (reg_exp_a < reg_exp_b) ||
								 (reg_exp_a == reg_exp_b && reg_man_a < reg_man_b)) begin
							reg_man_a	<= reg_man_b;
							reg_exp_a	<= reg_exp_b;
							reg_man_b	<= reg_man_a;
							reg_exp_b	<= reg_exp_a;
							sgn_y		<= reg_sgn_b;
							state		<= ALIGN;
						end
						
						else begin
							sgn_y		<= reg_sgn_a;
							state		<= ALIGN;
						end
					end

			ALIGN:	begin
						reg_man_b	<= shifter_out[25:2];
						guard_bit	<= shifter_out[1];
						round_bit	<= shifter_out[0];
						sticky_bit	<= sticky_bit_int;
						state		<= ADD;
					end

			ADD:	begin
						sum			<= reg_man_a + reg_man_b;
						state		<= NORM;
					end

			NORM:	begin
						// shift right 1 digit (only if there was a carry after addition)
						if (!reg_sub && sum[24]) begin
							man_y		<= sum[24:1];
							exp_y		<= reg_exp_a + 10'd1;
							sticky_bit	<= guard_bit || round_bit || sticky_bit;
							round_bit	<= sum[0];
						end
						// dont shift (because a >= b, the result is always >= 0 after
						// subtraction, so carry is a dont care in this case)
						else if (sum[23]) begin
							man_y		<= sum[23:0];
							exp_y		<= reg_exp_a;
							sticky_bit	<= round_bit || sticky_bit;
							round_bit	<= guard_bit;
						end
						// shift left 1 digit
						else if (!sum[23] && sum[22]) begin
							man_y		<= {sum[22:0], guard_bit};
							exp_y		<= reg_exp_a - leading_zeros;
						end
						// shift left more than 1 digit
						else begin
							man_y		<= {sum[22:0], guard_bit} << (leading_zeros - 5'd1);
							exp_y		<= reg_exp_a - leading_zeros;
							sticky_bit	<= 1'b0;
							round_bit	<= 1'b0;
						end

						valid_out_int	<= 1'b1;
						state			<= IDLE;
					end
		endcase
	end

	rshifter #(26, 5) rshifter_inst
	(
		.in(shifter_in),
		.sel(|align[9:5] ? 5'b11111 : align[4:0]),
		.sgn(reg_sub),

		.out(shifter_out),
		.sticky_bit(sticky_bit_int)
	);

	leading_zero_counter_24 LDZC_24_inst
	(
		.in(sum[23:0]),
		.y(leading_zeros),
		.a()
	);

endmodule
