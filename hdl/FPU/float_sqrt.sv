import FPU_pkg::*;

module float_sqrt
(
	input	logic					clk,
	input	logic					reset,

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

	output	logic			[23:0]	man_y,
	output	logic			[9:0]	exp_y,
	output	logic					sgn_y,

	output	logic					round_bit,
	output	logic					sticky_bit,
	output	logic					skip_round,

	output	logic					IV,

	output	logic			[2:0]	rm_out
);

	logic	[25:0]	rad_buf;
	logic	[25:0]	res_buf;
	logic	[27:0]	rem_buf;

	logic	[27:0]	acc [2:0];
	logic	[1:0]	s;

	logic			valid_in_int;
	logic			stall;

	enum	logic	{IDLE, CALC} state;

	assign			man_y			= res_buf[25:2];
	assign			round_bit		= res_buf[1];
	assign			sticky_bit		= |rem_buf || res_buf[0];

	assign			valid_in_int	= valid_in && (op == FPU_OP_SQRT);
	assign			ready_out		= ready_in && !stall;
	assign			stall			= state != IDLE;

	always_ff @(posedge clk) begin
		if (reset) begin
			rad_buf		<= 26'h0000000;
			res_buf		<= 26'h0000000;
			rem_buf		<= 28'h0000000;
			exp_y		<= 10'h000;
			sgn_y		<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= 3'b000;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			rad_buf		<= {1'b0, man_a, 1'b0} << exp_a[0];
			res_buf		<= 26'h0000000;
			rem_buf		<= 28'h0000000;
			exp_y		<= exp_a >>> 1;
			sgn_y		<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= rm;
			valid_out	<= 1'b0;
			state		<= CALC;

			// +0.0 or -0.0
			if (zero_a) begin
				rad_buf		<= 26'h0000000;
				res_buf		<= 26'h0000000;
				exp_y		<= 10'h000;
				sgn_y		<= sgn_a;
				skip_round	<= 1'b1;
				IV			<= 1'b0;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// NaN (negative numbers, except -0.0)
			else if (sgn_a || sNaN_a || qNaN_a) begin
				rad_buf		<= 26'h0000000;
				res_buf		<= {24'hc00000, 2'b00};
				exp_y		<= 10'h0ff;
				sgn_y		<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a) begin
				rad_buf		<= 26'h0000000;
				res_buf		<= {24'h800000, 2'b00};
				exp_y		<= 10'h0ff;
				sgn_y		<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= 1'b1;
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						rad_buf		<= 26'h0000000;
						res_buf		<= 26'h0000000;
						rem_buf		<= 28'h0000000;
						exp_y		<= 10'h000;
						sgn_y		<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						rm_out		<= 3'b000;
						valid_out	<= 1'b0;
					end

			CALC:	begin
						rad_buf	<= rad_buf << 4;
						res_buf	<= (res_buf << 2) | s;
						rem_buf	<= acc[2]; //[27:0];

						// when the calculation is finished,
						// the MSB of the result is always 1
						if (res_buf[23]) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
					end
		endcase
	end

	always_comb begin
		acc[0]	= rem_buf;

		acc[1]	= ((acc[0] << 2) | rad_buf[25:24]) - {res_buf, 2'b01};
		s[1]	= !acc[1][27];
		acc[1]	= s[1] ? acc[1] : ((acc[0] << 2) | rad_buf[25:24]);

		acc[2]	= ((acc[1] << 2) | rad_buf[23:22]) - {res_buf, s[1], 2'b01};
		s[0]	= !acc[2][27];
		acc[2]	= s[0] ? acc[2] : ((acc[1] << 2) | rad_buf[23:22]);
	end

endmodule
