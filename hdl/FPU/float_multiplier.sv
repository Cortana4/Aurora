import FPU_pkg::*;

module float_multiplier
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

	logic	[23:0]	man_b_buf;
	logic	[47:0]	res_buf;
	logic	[9:0]	exp_y_buf;
	logic			sgn_y_buf;
	logic	[1:0]	counter;

	logic	[29:0]	acc;

	logic			valid_in_int;
	logic			stall;

	enum	logic	{IDLE, CALC} state;

	assign			valid_in_int	= valid_in && (op == FPU_OP_MUL);
	assign			ready_out		= ready_in && !stall;
	assign			stall			= state != IDLE;

	always_comb begin
		if (res_buf[47] || skip_round) begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf + !skip_round;
			man_y		= res_buf[47:24];
			round_bit	= res_buf[23];
			sticky_bit	= |res_buf[22:0];
		end

		else begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf;
			man_y		= res_buf[46:23];
			round_bit	= res_buf[22];
			sticky_bit	= |res_buf[21:0];
		end
	end

	always @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			man_b_buf	<= 24'h000000;
			res_buf		<= 48'h000000000000;
			exp_y_buf	<= 10'h000;
			sgn_y_buf	<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= 3'b000;
			counter		<= 2'd0;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			man_b_buf	<= man_b;
			res_buf		<= {24'h000000, man_a};
			exp_y_buf	<= exp_a + exp_b;
			sgn_y_buf	<= sgn_a ^ sgn_b;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= rm;
			counter		<= 2'd0;
			valid_out	<= 1'b0;
			state		<= CALC;

			// NaN
			if (sNaN_a || sNaN_b || qNaN_a || qNaN_b ||
				(zero_a && inf_b) || (inf_a && zero_b)) begin
				man_b_buf	<= 24'h000000;
				res_buf		<= {24'hc00000, 24'h000000};
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= ~(qNaN_a || qNaN_b);
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a || inf_b) begin
				man_b_buf	<= 24'h000000;
				res_buf		<= {24'h800000, 24'h000000};
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// zero
			else if (zero_a || zero_b) begin
				man_b_buf	<= 24'h000000;
				res_buf		<= {24'h000000, 24'h000000};
				exp_y_buf	<= 10'h000;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						man_b_buf	<= 24'h000000;
						res_buf		<= 48'h000000000000;
						exp_y_buf	<= 10'h000;
						sgn_y_buf	<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						rm_out		<= 3'b000;
						counter		<= 2'd0;
						valid_out	<= 1'b0;
					end

			CALC:	begin
						res_buf		<= {acc, res_buf[23:6]};

						if (counter == 2'd3) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end

						else
							counter		<= counter + 2'd1;
					end
		endcase
	end

	always_comb begin
		acc	= {6'b000000, res_buf[47:24]};

		for (integer i = 0; i < 6; i = i+1) begin
			if (res_buf[i])
				acc = acc + (man_b_buf << i);
		end
	end

endmodule
