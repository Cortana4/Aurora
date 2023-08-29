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

	logic			[23:0]	man_a_buf;
	logic	signed	[9:0]	exp_a_buf;
	logic					sgn_a_buf;
	logic					zero_a_buf;
	logic					inf_a_buf;
	logic					sNaN_a_buf;
	logic					qNaN_a_buf;
	logic			[23:0]	man_b_buf;
	logic	signed	[9:0]	exp_b_buf;
	logic					sgn_b_buf;
	logic					zero_b_buf;
	logic					inf_b_buf;
	logic					sNaN_b_buf;
	logic					qNaN_b_buf;
	logic					sub_buf;

	logic					sgn_b_int;
	logic					sub_int;

	logic			[9:0]	align;
	logic			[25:0]	shifter_in;
	logic			[25:0]	shifter_out;

	logic					guard_bit;
	logic					sticky_bit_int;

	logic			[24:0]	sum;

	logic			[4:0]	leading_zeros;

	logic					valid_in_int;
	logic					stall;

	enum	logic	[2:0]	{IDLE, INIT, ALIGN, ADD, NORM} state;

	assign	sgn_b_int		= sgn_b ^ (op == FPU_OP_SUB);
	assign	sub_int			= sgn_a ^ sgn_b_int;

	assign	align			= exp_a_buf - exp_b_buf;
	assign	shifter_in		= sub_buf ? -{man_b_buf, 2'b00} : {man_b_buf, 2'b00};

	assign	valid_in_int	= valid_in && (op == FPU_OP_ADD || op == FPU_OP_SUB);
	assign	ready_out		= ready_in && !stall;
	assign	stall			= state != IDLE;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			man_a_buf	<= 24'h000000;
			exp_a_buf	<= 10'h000;
			sgn_a_buf	<= 1'b0;
			zero_a_buf	<= 1'b0;
			inf_a_buf	<= 1'b0;
			sNaN_a_buf	<= 1'b0;
			qNaN_a_buf	<= 1'b0;
			man_b_buf	<= 24'h000000;
			exp_b_buf	<= 10'h000;
			sgn_b_buf	<= 1'b0;
			zero_b_buf	<= 1'b0;
			inf_b_buf	<= 1'b0;
			sNaN_b_buf	<= 1'b0;
			qNaN_b_buf	<= 1'b0;
			sub_buf		<= 1'b0;
			man_y		<= 24'h000000;
			exp_y		<= 10'h000;
			sgn_y		<= 1'b0;
			guard_bit	<= 1'b0;
			round_bit	<= 1'b0;
			sticky_bit	<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			sum			<= 25'h0000000;
			rm_out		<= 3'b000;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			man_a_buf	<= man_a;
			exp_a_buf	<= exp_a;
			sgn_a_buf	<= sgn_a;
			zero_a_buf	<= zero_a;
			inf_a_buf	<= inf_a;
			sNaN_a_buf	<= sNaN_a;
			qNaN_a_buf	<= qNaN_a;
			man_b_buf	<= man_b;
			exp_b_buf	<= exp_b;
			sgn_b_buf	<= sgn_b_int;
			zero_b_buf	<= zero_b;
			inf_b_buf	<= inf_b;
			sNaN_b_buf	<= sNaN_b;
			qNaN_b_buf	<= qNaN_b;
			sub_buf		<= sub_int;
			man_y		<= 24'h000000;
			exp_y		<= 10'h000;
			sgn_y		<= 1'b0;
			guard_bit	<= 1'b0;
			round_bit	<= 1'b0;
			sticky_bit	<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			sum			<= 25'h0000000;
			rm_out		<= rm;
			valid_out	<= 1'b0;
			state		<= INIT;
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						man_a_buf	<= 24'h000000;
						exp_a_buf	<= 10'h000;
						sgn_a_buf	<= 1'b0;
						zero_a_buf	<= 1'b0;
						inf_a_buf	<= 1'b0;
						sNaN_a_buf	<= 1'b0;
						qNaN_a_buf	<= 1'b0;
						man_b_buf	<= 24'h000000;
						exp_b_buf	<= 10'h000;
						sgn_b_buf	<= 1'b0;
						zero_b_buf	<= 1'b0;
						inf_b_buf	<= 1'b0;
						sNaN_b_buf	<= 1'b0;
						qNaN_b_buf	<= 1'b0;
						sub_buf		<= 1'b0;
						man_y		<= 24'h000000;
						exp_y		<= 10'h000;
						sgn_y		<= 1'b0;
						guard_bit	<= 1'b0;
						round_bit	<= 1'b0;
						sticky_bit	<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						sum			<= 25'h0000000;
						rm_out		<= 3'b000;
						valid_out	<= 1'b0;
						state		<= IDLE;
					end

			INIT:	begin
						// NaN
						if (sNaN_a_buf || sNaN_b_buf || qNaN_a_buf || qNaN_b_buf ||
							(sub_buf && inf_a_buf && inf_b_buf)) begin
							man_y		<= 24'hc00000;
							exp_y		<= 10'h0ff;
							sgn_y		<= 1'b0;
							skip_round	<= 1'b1;
							IV			<= ~(qNaN_a_buf || qNaN_b_buf);
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// inf
						else if (inf_a_buf || inf_b_buf) begin
							man_y		<= 24'h800000;
							exp_y		<= 10'h0ff;
							sgn_y		<= sgn_a_buf;
							skip_round	<= 1'b1;
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// zero (0 +- 0)
						else if (zero_a_buf && zero_b_buf) begin
							sgn_y		<= sgn_a_buf && sgn_b_buf;
							skip_round	<= 1'b1;
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// zero (x - x)
						else if (exp_a_buf == exp_b_buf &&
								 man_a_buf == man_b_buf && sub_buf) begin
							sgn_y		<= rm_out == FPU_RM_RDN;
							skip_round	<= 1'b1;
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// a
						else if (zero_b_buf) begin
							man_y		<= man_a_buf;
							exp_y		<= exp_a_buf;
							sgn_y		<= sgn_a_buf;
							skip_round	<= 1'b0;
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// b
						else if (zero_a_buf) begin
							man_y		<= man_b_buf;
							exp_y		<= exp_b_buf;
							sgn_y		<= sgn_b_buf;
							skip_round	<= 1'b0;
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						// swap inputs if abs(a) < abs(b)
						else if ((zero_a_buf && !zero_b_buf) || (exp_a_buf < exp_b_buf) ||
								 (exp_a_buf == exp_b_buf && man_a_buf < man_b_buf)) begin
							man_a_buf	<= man_b_buf;
							exp_a_buf	<= exp_b_buf;
							man_b_buf	<= man_a_buf;
							exp_b_buf	<= exp_a_buf;
							sgn_y		<= sgn_b_buf;
							state		<= ALIGN;
						end

						else begin
							sgn_y		<= sgn_a_buf;
							state		<= ALIGN;
						end
					end

			ALIGN:	begin
						man_b_buf	<= shifter_out[25:2];
						guard_bit	<= shifter_out[1];
						round_bit	<= shifter_out[0];
						sticky_bit	<= sticky_bit_int;
						state		<= ADD;
					end

			ADD:	begin
						sum			<= man_a_buf + man_b_buf;
						state		<= NORM;
					end

			NORM:	begin
						// shift right 1 digit (only if there was a carry after addition)
						if (!sub_buf && sum[24]) begin
							man_y		<= sum[24:1];
							exp_y		<= exp_a_buf + 10'd1;
							sticky_bit	<= guard_bit || round_bit || sticky_bit;
							round_bit	<= sum[0];
						end
						// dont shift (because a >= b, the result is always >= 0 after
						// subtraction, so carry is a dont care in this case)
						else if (sum[23]) begin
							man_y		<= sum[23:0];
							exp_y		<= exp_a_buf;
							sticky_bit	<= round_bit || sticky_bit;
							round_bit	<= guard_bit;
						end
						// shift left 1 digit
						else if (!sum[23] && sum[22]) begin
							man_y		<= {sum[22:0], guard_bit};
							exp_y		<= exp_a_buf - leading_zeros;
						end
						// shift left more than 1 digit
						else begin
							man_y		<= {sum[22:0], guard_bit} << (leading_zeros - 5'd1);
							exp_y		<= exp_a_buf - leading_zeros;
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
		.in			(shifter_in),
		.sel		(|align[9:5] ? 5'b11111 : align[4:0]),
		.sgn		(sub_buf),

		.out		(shifter_out),
		.sticky_bit	(sticky_bit_int)
	);

	leading_zero_counter_24 LDZC_24_inst
	(
		.in			(sum[23:0]),
		.y			(leading_zeros),
		.a			()
	);

endmodule
