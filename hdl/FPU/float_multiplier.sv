import FPU_pkg::*;

module float_multiplier
#(
	parameter				m = 1	// cycles per multiplication
)
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

	output	logic	[2:0]	rm_out
);

	logic	[23:0]	man_a_buf;
	logic	[23:0]	man_b_buf;
	logic	[47:0]	man_y_buf[m:0];
	logic	[47:0]	man_y_exc;
	logic	[9:0]	exp_y_buf;
	logic			sgn_y_buf;

	logic			valid_in_int;
	logic			stall;
	
	integer			counter;

	enum	logic	{IDLE, CALC} state;

	assign			valid_in_int	= valid_in && (op == FPU_OP_MUL);
	assign			ready_out		= ready_in && !stall;
	assign			stall			= state != IDLE;

	always_comb begin
		if (skip_round) begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf;
			man_y		= man_y_exc[47:24];
			round_bit	= 1'b0;
			sticky_bit	= 1'b0;
		end

		else if (man_y_buf[m][47]) begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf + 10'd1;
			man_y		= man_y_buf[m][47:24];
			round_bit	= man_y_buf[m][23];
			sticky_bit	= |man_y_buf[m][22:0];
		end

		else begin
			sgn_y		= sgn_y_buf;
			exp_y		= exp_y_buf;
			man_y		= man_y_buf[m][46:23];
			round_bit	= man_y_buf[m][22];
			sticky_bit	= |man_y_buf[m][21:0];
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			man_a_buf	<= 24'h000000;
			man_b_buf	<= 24'h000000;
			man_y_exc	<= 48'h000000000000;
			exp_y_buf	<= 10'h000;
			sgn_y_buf	<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= 3'b000;
			counter		<= 0;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			man_a_buf	<= man_a;
			man_b_buf	<= man_b;
			man_y_exc	<= 48'h000000000000;
			exp_y_buf	<= exp_a + exp_b;
			sgn_y_buf	<= sgn_a ^ sgn_b;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= rm;
			counter		<= 0;
			valid_out	<= 1'b0;
			state		<= CALC;

			// NaN
			if (sNaN_a || sNaN_b || qNaN_a || qNaN_b ||
				(zero_a && inf_b) || (inf_a && zero_b)) begin
				man_a_buf	<= 24'h000000;
				man_b_buf	<= 24'h000000;
				man_y_exc	<= {24'hc00000, 24'h000000};
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= ~(qNaN_a || qNaN_b);
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a || inf_b) begin
				man_a_buf	<= 24'h000000;
				man_b_buf	<= 24'h000000;
				man_y_exc	<= {24'h800000, 24'h000000};
				exp_y_buf	<= 10'h0ff;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// zero
			else if (zero_a || zero_b) begin
				man_a_buf	<= 24'h000000;
				man_b_buf	<= 24'h000000;
				man_y_exc	<= 48'h000000000000;
				exp_y_buf	<= 10'h000;
				sgn_y_buf	<= sgn_a ^ sgn_b;
				skip_round	<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						man_a_buf	<= 24'h000000;
						man_b_buf	<= 24'h000000;
						man_y_exc	<= 48'h000000000000;
						exp_y_buf	<= 10'h000;
						sgn_y_buf	<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						rm_out		<= 3'b000;
						counter		<= 0;
						valid_out	<= 1'b0;
					end

			CALC:	begin
						if (counter == m) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end

						else
							counter		<= counter + 1;
					end
		endcase
	end

	always_ff @(posedge clk) begin
		if (reset) for (integer i = 0; i < m; i = i+1)
			man_y_buf[i]	<= 'h0;

		else if (state == CALC) begin
			man_y_buf[0]	<= man_a_buf * man_b_buf;

			for (integer i = 0; i < m; i = i+1)
				man_y_buf[i+1]	<= man_y_buf[i];
		end
	end

endmodule
