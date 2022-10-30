module float_divider
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_div,

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

	output	logic			IV,
	output	logic			DZ,

	output	logic			final_res,
	output	logic			ready
);

	logic	[23:0]	reg_man_b;
	logic	[25:0]	reg_res;
	logic	[26:0]	reg_rem;
	logic	[9:0]	reg_exp_y;
	logic			reg_sgn_y;
	logic	[3:0]	counter;

	logic			IV_int;

	logic	[26:0]	acc [2:0];
	logic	[1:0]	q;

	enum	logic	{IDLE, CALC} state;

	assign			IV_int	= sNaN_a || sNaN_b || (zero_a && zero_b) || (inf_a && inf_b);

	always_comb begin
		if (reg_res[25] || final_res) begin
			sgn_y		= reg_sgn_y;
			exp_y		= reg_exp_y;
			man_y		= reg_res[25:2];
			round_bit	= reg_res[1];
			sticky_bit	= |reg_rem || reg_res[0];
		end

		else begin
			sgn_y		= reg_sgn_y;
			exp_y		= reg_exp_y - 10'd1;
			man_y		= reg_res[24:1];
			round_bit	= reg_res[0];
			sticky_bit	= |reg_rem;
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !op_div)) begin
			reg_man_b	<= 24'h000000;
			reg_res		<= {24'hc00000, 2'b00};
			reg_rem		<= 27'h0000000;
			reg_exp_y	<= 10'h000;
			reg_sgn_y	<= 1'b0;
			IV			<= 1'b0;
			DZ			<= 1'b0;
			counter		<= 4'd0;
			final_res	<= 1'b0;
			state		<= IDLE;
			ready		<= 1'b0;
		end

		else if (load) begin
			IV			<= IV_int;
			DZ			<= zero_b;
			counter		<= 4'd0;
			// NaN
			if (IV_int || qNaN_a || qNaN_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'hc00000, 2'b00};
				reg_rem		<= 27'h0000000;
				reg_exp_y	<= 10'h0ff;
				reg_sgn_y	<= 1'b0;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end
			// inf
			else if (inf_a || zero_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'h800000, 2'b00};
				reg_rem		<= 27'h0000000;
				reg_exp_y	<= 10'h0ff;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end
			// zero
			else if (zero_a || inf_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'h000000, 2'b00};
				reg_rem		<= 27'h0000000;
				reg_exp_y	<= 10'h000;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end

			else begin
				reg_man_b	<= man_b;
				reg_res		<= 26'd0;
				reg_rem		<= {1'b0, man_a, 2'b00};
				reg_exp_y	<= exp_a - exp_b;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b0;
				state		<= CALC;
				ready		<= 1'b0;
			end
		end

		else case (state)
			IDLE:	ready	<= 1'b0;

			CALC:	begin
						reg_res		<= (reg_res << 2) | q;
						reg_rem		<= acc[2];

						if (counter == 4'd12) begin
							state	<= IDLE;
							ready	<= 1'b1;
						end

						else
							counter	<= counter + 4'd1;
					end
		endcase
	end

	always_comb begin
		acc[0]	= reg_rem;

		for (integer i = 1; i <= 2; i = i+1) begin
			acc[i]	= acc[i-1] - {1'b0, reg_man_b, 2'b00};
			q[2-i]	= !acc[i][26];
			acc[i]	= (acc[i][26] ? acc[i-1] : acc[i]) << 1;
		end
	end

endmodule