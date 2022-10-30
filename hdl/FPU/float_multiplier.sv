module float_multiplier
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic			op_mul,

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

	output	logic			final_res,
	output	logic			ready
);

	logic	[23:0]	reg_man_b;
	logic	[47:0]	reg_res;
	logic	[9:0]	reg_exp_y;
	logic			reg_sgn_y;
	logic	[1:0]	counter;

	logic			IV_int;

	logic	[29:0]	acc;

	enum	logic	{IDLE, CALC} state;

	assign			IV_int	= sNaN_a || sNaN_b || (zero_a && inf_b) || (inf_a && zero_b);

	always_comb begin
		if (reg_res[47] || final_res) begin
			sgn_y		= reg_sgn_y;
			exp_y		= reg_exp_y + !final_res;
			man_y		= reg_res[47:24];
			round_bit	= reg_res[23];
			sticky_bit	= |reg_res[22:0];
		end

		else begin
			sgn_y		= reg_sgn_y;
			exp_y		= reg_exp_y;
			man_y		= reg_res[46:23];
			round_bit	= reg_res[22];
			sticky_bit	= |reg_res[21:0];
		end
	end

	always @(posedge clk, posedge reset) begin
		if (reset || (load && !op_mul)) begin
			reg_man_b	<= 24'h000000;
			reg_res		<= 48'h000000000000;
			reg_exp_y	<= 10'h000;
			reg_sgn_y	<= 1'b0;
			IV			<= 1'b0;
			counter		<= 2'd0;
			final_res	<= 1'b0;
			state		<= IDLE;
			ready		<= 1'b0;
		end

		else if (load) begin
			IV			<= IV_int;
			counter		<= 2'd0;
			// NaN
			if (IV_int || qNaN_a || qNaN_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'hc00000, 24'h000000};
				reg_exp_y	<= 10'h0ff;
				reg_sgn_y	<= 1'b0;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end
			// inf
			else if (inf_a || inf_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'h800000, 24'h000000};
				reg_exp_y	<= 10'h0ff;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end
			// zero
			else if (zero_a || zero_b) begin
				reg_man_b	<= 24'h000000;
				reg_res		<= {24'h000000, 24'h000000};
				reg_exp_y	<= 10'h000;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b1;
				state		<= IDLE;
				ready		<= 1'b1;
			end

			else begin
				reg_man_b	<= man_b;
				reg_res		<= {24'h000000, man_a};
				reg_exp_y	<= exp_a + exp_b;
				reg_sgn_y	<= sgn_a ^ sgn_b;
				final_res	<= 1'b0;
				state		<= CALC;
				ready		<= 1'b0;
			end
		end

		else case (state)
			IDLE:	ready <= 1'b0;

			CALC:	begin
						reg_res	<= {acc, reg_res[23:6]};

						if (counter == 2'd3) begin
							state	<= IDLE;
							ready	<= 1'b1;
						end

						else
							counter <= counter + 2'd1;
					end
		endcase
	end

	always_comb begin
		acc	= {6'b000000, reg_res[47:24]};

		for (integer i = 0; i < 6; i = i+1) begin
			if (reg_res[i])
				acc = acc + ({6'b000000, reg_man_b} << i);
		end
	end

endmodule
