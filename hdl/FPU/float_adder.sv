import FPU_pkg::*;

module float_adder
(
	input	logic					clk,
	input	logic					reset,
	input	logic					load,
	
	input	logic					valid_in,
	output	logic					ready_out,
	output	logic					valid_out,
	input	logic					ready_in,

	input	logic			[4:0]	op,
	input	logic			[2:0]	rm,

	input	logic			[23:0]	man_a,
	input	logic	signed	[9:0]	exp_a,
	input	logic					sgn_a,
	input	logic					zero_a,
	input	logic					inf_a,
	input	logic					sNaN_a,
	input	logic					qNaN_a,

	input	logic			[23:0]	man_b,
	input	logic	signed	[9:0]	exp_b,
	input	logic					sgn_b,
	input	logic					zero_b,
	input	logic					inf_b,
	input	logic					sNaN_b,
	input	logic					qNaN_b,

	output	logic			[23:0]	man_y,
	output	logic			[9:0]	exp_y,
	output	logic					sgn_y,

	output	logic					round_bit,
	output	logic					sticky_bit,

	output	logic					IV,
	
	output	logic					rm_out,
	output	logic					skip_round
);

	logic			sgn_b_int;
	logic			sub_int;
	logic			reg_sub_int;
	logic			swapInputs;
	logic			zero_y;
	logic			sgn_y_int;
	logic			IV_int;

	logic	[23:0]	reg_man_a;
	logic	[9:0]	reg_exp_a;
	logic	[23:0]	reg_man_b;
	logic	[9:0]	reg_exp_b;

	logic	[9:0]	align;
	logic	[25:0]	shifter_in;
	logic	[25:0]	shifter_out;

	logic			guard_bit;
	logic			sticky_bit_int;

	logic	[24:0]	sum;

	logic	[4:0]	leading_zeros;
	
	logic			stall;

	enum	logic	[1:0]	{IDLE, ALIGN, ADD, NORM} state;

	assign			sgn_b_int		= sgn_b ^ (op == FPU_OP_SUB);
	assign			sub_int			= sgn_a ^ sgn_b_int;
	assign			swapInputs		= (zero_a && !zero_b) || (exp_a < exp_b) || ((exp_a == exp_b) && (man_a < man_b));
	assign			zero_y			= ({exp_a, man_a} == {exp_b, man_b}) && sub_int;
	assign			IV_int			= sNaN_a || sNaN_b || (sub_int && inf_a && inf_b);
	assign			align			= reg_exp_a - reg_exp_b;
	assign			shifter_in		= reg_sub_int ? -{reg_man_b, 2'b00} : {reg_man_b, 2'b00};
	
	assign			ready_out		= ready_in && !stall && (op == FPU_OP_ADD || op == FPU_OP_SUB);
	assign			stall			= state != IDLE;

	// sign logic
	always_comb begin
		if (zero_a && zero_b)
			sgn_y_int	= sgn_a && sgn_b_int;

		else if (zero_y)
			sgn_y_int	= rm == FPU_RM_RDN;

		else if (swapInputs)
			sgn_y_int	= sgn_b_int;

		else
			sgn_y_int	= sgn_a;
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out	<= 1'b0;
			reg_sub_int	<= 1'b0;
			reg_man_a	<= 24'h000000;
			reg_exp_a	<= 10'h000;
			reg_man_b	<= 24'h000000;
			reg_exp_b	<= 10'h000;
			man_y		<= 24'h000000;
			exp_y		<= 10'h000;
			sgn_y		<= 1'b0;
			guard_bit	<= 1'b0;
			round_bit	<= 1'b0;
			sticky_bit	<= 1'b0;
			IV			<= 1'b0;
			sum			<= 25'h0000000;
			rm_out		<= 3'b000;
			skip_round	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in && ready_out) begin
			valid_out	<= 1'b0;
			reg_sub_int	<= sub_int;
			reg_man_a	<= 24'h000000;
			reg_exp_a	<= 10'h000;
			reg_man_b	<= 24'h000000;
			reg_exp_b	<= 10'h000;
			man_y		<= 24'h000000;
			exp_y		<= 10'h000;
			sgn_y		<= sgn_y_int;
			guard_bit	<= 1'b0;
			round_bit	<= 1'b0;
			sticky_bit	<= 1'b0;
			IV			<= IV_int;
			sum			<= 25'h0000000;
			rm_out		<= rm;
			skip_round	<= 1'b0;
			state		<= IDLE;
			// NaN
			if (IV_int || qNaN_a || qNaN_b) begin
				valid_out	<= 1'b1;
				man_y		<= 24'hc00000;
				exp_y		<= 10'h0ff;
				sgn_y		<= 1'b0;
				skip_round	<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a || inf_b) begin
				valid_out	<= 1'b1;
				man_y		<= 24'h800000;
				exp_y		<= 10'h0ff;
				sgn_y		<= sgn_y_int;
				skip_round	<= 1'b1;
				state		<= IDLE;
			end
			// zero
			else if (zero_y) begin
				valid_out	<= 1'b1;
				man_y		<= 24'h000000;
				exp_y		<= 10'h000;
				sgn_y		<= sgn_y_int;
				skip_round	<= 1'b1;
				state		<= IDLE;
			end
			// a
			else if (zero_b) begin
				valid_out	<= 1'b1;
				man_y		<= man_a;
				exp_y		<= exp_a;
				sgn_y		<= sgn_y_int;
				skip_round	<= 1'b0;
				state		<= IDLE;
			end
			// b
			else if (zero_a) begin
				valid_out	<= 1'b1;
				man_y		<= man_b;
				exp_y		<= exp_b;
				sgn_y		<= sgn_y_int;
				skip_round	<= 1'b0;
				state		<= IDLE;
				ready		<= 1'b1;
			end
			// swap inputs if abs(a) < abs(b)
			else if (swapInputs) begin
				reg_man_a	<= man_b;
				reg_exp_a	<= exp_b;
				reg_man_b	<= man_a;
				reg_exp_b	<= exp_a;
			end
			
			else begin
				reg_man_a	<= man_a;
				reg_exp_a	<= exp_a;
				reg_man_b	<= man_b;
				reg_exp_b	<= exp_b;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						valid_out	<= 1'b0;
						reg_sub_int	<= 1'b0;
						reg_man_a	<= 24'h000000;
						reg_exp_a	<= 10'h000;
						reg_man_b	<= 24'h000000;
						reg_exp_b	<= 10'h000;
						man_y		<= 24'h000000;
						exp_y		<= 10'h000;
						sgn_y		<= 1'b0;
						guard_bit	<= 1'b0;
						round_bit	<= 1'b0;
						sticky_bit	<= 1'b0;
						IV			<= 1'b0;
						sum			<= 25'h0000000;
						rm_out		<= 3'b000;
						skip_round	<= 1'b0;
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
						if (!reg_sub_int && sum[24]) begin
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

						valid_out	<= 1'b1;
						state		<= IDLE;
					end
		endcase
	end

	rshifter #(26, 5) rshifter_inst
	(
		.in(shifter_in),
		.sel(|align[9:5] ? 5'b11111 : align[4:0]),
		.sgn(reg_sub_int),

		.out(shifter_out),
		.sticky_bit(sticky_bit_int)
	);

	leading_zero_counter_24 LZC_24_inst
	(
		.in(sum[23:0]),
		.y(leading_zeros),
		.a()
	);

endmodule
