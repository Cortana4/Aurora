import FPU_pkg::*;

module float_divider
(
	input	logic			clk,
	input	logic			reset,

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
	output	logic			DZ,

	output	logic	[2:0]	rm_out
);

	logic	[23:0]	div_buf;
	logic	[25:0]	res_buf;
	logic	[26:0]	rem_buf;
	logic	[9:0]	exp_y_buf;
	logic			sgn_y_buf;
	logic	[3:0]	counter;

	logic			IV_int;

	logic			valid_in_int;
	logic			stall;

	logic	[26:0]	acc [2:0];
	logic	[1:0]	q;

	enum	logic	{IDLE, CALC} state;

	assign			IV_int			= sNaN_a || sNaN_b || (zero_a && zero_b) || (inf_a && inf_b);

	assign			valid_in_int	= valid_in && (op == FPU_OP_DIV);
	assign			ready_out		= ready_in && !stall;
	assign			stall			= state != IDLE;

	always_comb begin
		if (res_buf[25] || skip_round) begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf;
			man_y		= res_buf[25:2];
			round_bit	= res_buf[1];
			sticky_bit	= |rem_buf || res_buf[0];
		end

		else begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf - 10'd1;
			man_y		= res_buf[24:1];
			round_bit	= res_buf[0];
			sticky_bit	= |rem_buf;
		end
	end

	always_ff @(posedge clk) begin
		if (reset) begin
			div_buf		<= 24'h000000;
			res_buf		<= {24'hc00000, 2'b00};
			rem_buf		<= 27'h0000000;
			exp_y_buf	<= 10'h000;
			sgn_y_buf	<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			DZ			<= 1'b0;
			rm_out		<= 3'b000;
			counter		<= 4'd0;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			div_buf		<= man_b;
			res_buf		<= 26'd0;
			rem_buf		<= {1'b0, man_a, 2'b00};
			exp_y_buf	<= exp_a - exp_b;
			sgn_y_buf	<= sgn_a ^ sgn_b;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			DZ			<= zero_b;
			rm_out		<= rm;
			counter		<= 4'd0;
			valid_out	<= 1'b0;
			state		<= CALC;

			// NaN
			if (sNaN_a || sNaN_b || qNaN_a || qNaN_b ||
				(zero_a && zero_b) || (inf_a && inf_b)) begin
				div_buf		<= 24'h000000;
				res_buf		<= {24'hc00000, 2'b00};
				rem_buf		<= 27'h0000000;
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= ~(qNaN_a || qNaN_b);
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a || zero_b) begin
				div_buf		<= 24'h000000;
				res_buf		<= {24'h800000, 2'b00};
				rem_buf		<= 27'h0000000;
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// zero
			else if (zero_a || inf_b) begin
				div_buf		<= 24'h000000;
				res_buf		<= {24'h000000, 2'b00};
				rem_buf		<= 27'h0000000;
				exp_y_buf	<= 10'h000;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						div_buf		<= 24'h000000;
						res_buf		<= {24'hc00000, 2'b00};
						rem_buf		<= 27'h0000000;
						exp_y_buf	<= 10'h000;
						sgn_y_buf	<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						DZ			<= 1'b0;
						rm_out		<= 3'b000;
						counter		<= 4'd0;
						valid_out	<= 1'b0;
					end

			CALC:	begin
						res_buf		<= (res_buf << 2) | q;
						rem_buf		<= acc[2];

						if (counter == 4'd12) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end

						else
							counter		<= counter + 4'd1;
					end
		endcase
	end

	always_comb begin
		acc[0]	= rem_buf;

		for (integer i = 1; i <= 2; i = i+1) begin
			acc[i]	= acc[i-1] - (div_buf << 2);
			q[2-i]	= !acc[i][26];
			acc[i]	= (acc[i][26] ? acc[i-1] : acc[i]) << 1;
		end
	end

endmodule