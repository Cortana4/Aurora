import FPU_pkg::*;

module float_sqrt
(
	input	logic					clk,
	input	logic					reset,
	input	logic					flush,

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

	logic	[25:0]	reg_rad;
	logic	[25:0]	reg_res;
	logic	[27:0]	reg_rem;

	logic	[27:0]	acc [2:0];
	logic	[1:0]	s;

	logic			valid_in_int;
	logic			stall;

	enum	logic	{IDLE, CALC} state;

	assign			man_y			= reg_res[25:2];
	assign			round_bit		= reg_res[1];
	assign			sticky_bit		= |reg_rem || reg_res[0];

	assign			valid_in_int	= valid_in && (op == FPU_OP_SQRT);
	assign			ready_out		= ready_in && !stall;
	assign			stall			= state != IDLE;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_out	<= 1'b0;
			reg_rad		<= 26'h0000000;
			reg_res		<= 26'h0000000;
			reg_rem		<= 28'h0000000;
			exp_y		<= 10'h000;
			sgn_y		<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= 3'b000;
			state		<= IDLE;
		end

		else if (valid_in_int && ready_out) begin
			valid_out	<= 1'b0;
			reg_rad		<= {1'b0, man_a, 1'b0} << exp_a[0];
			reg_res		<= 26'h0000000;
			reg_rem		<= 28'h0000000;
			exp_y		<= exp_a >>> 1;
			sgn_y		<= 1'b0;
			skip_round	<= 1'b0;
			IV			<= 1'b0;
			rm_out		<= rm;
			state		<= CALC;

			// +0.0 or -0.0
			if (zero_a) begin
				valid_out	<= 1'b1;
				reg_rad		<= 26'h0000000;
				reg_res		<= 26'h0000000;
				exp_y		<= 10'h000;
				sgn_y		<= sgn_a;
				skip_round	<= 1'b1;
				IV			<= 1'b0;
				state		<= IDLE;
			end
			// NaN (negative numbers, except -0.0)
			else if (sgn_a || sNaN_a || qNaN_a) begin
				valid_out	<= 1'b1;
				reg_rad		<= 26'h0000000;
				reg_res		<= {24'hc00000, 2'b00};
				exp_y		<= 10'h0ff;
				sgn_y		<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= 1'b1;
				state		<= IDLE;
			end
			// inf
			else if (inf_a) begin
				valid_out	<= 1'b1;
				reg_rad		<= 26'h0000000;
				reg_res		<= {24'h800000, 2'b00};
				exp_y		<= 10'h0ff;
				sgn_y		<= 1'b0;
				skip_round	<= 1'b1;
				IV			<= 1'b1;
				state		<= IDLE;
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						valid_out	<= 1'b0;
						reg_rad		<= 26'h0000000;
						reg_res		<= 26'h0000000;
						reg_rem		<= 28'h0000000;
						exp_y		<= 10'h000;
						sgn_y		<= 1'b0;
						skip_round	<= 1'b0;
						IV			<= 1'b0;
						rm_out		<= 3'b000;
					end

			CALC:	begin
						reg_rad	<= reg_rad << 4;
						reg_res	<= (reg_res << 2) | s;
						reg_rem	<= acc[2]; //[27:0];

						// when the calculation is finished,
						// the MSB of the result is always 1
						if (reg_res[23]) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
					end
		endcase
	end

	always_comb begin
		acc[0]	= reg_rem;

		acc[1]	= ((acc[0] << 2) | reg_rad[25:24]) - {reg_res, 2'b01};
		s[1]	= !acc[1][27];
		acc[1]	= s[1] ? acc[1] : ((acc[0] << 2) | reg_rad[25:24]);

		acc[2]	= ((acc[1] << 2) | reg_rad[23:22]) - {reg_res, s[1], 2'b01};
		s[0]	= !acc[2][27];
		acc[2]	= s[0] ? acc[2] : ((acc[1] << 2) | reg_rad[23:22]);
	end

endmodule
