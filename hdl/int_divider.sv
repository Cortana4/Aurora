import CPU_pkg::*;

module int_divider
#(
	parameter		n = 32,	// data width
	parameter		m = 8	// bits calculated per cycle
)
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[1:0]	op,

	input	logic	[n-1:0]	a,
	input	logic	[n-1:0]	b,

	output	logic	[n-1:0]	y
);

	logic	[n-1:0]	a_buf;
	logic	[n-1:0]	b_buf;

	logic	[1:0]	op_buf;
	logic	[n-1:0]	div_buf;	// divisor
	logic	[n-1:0]	res_buf;
	logic	[n:0]	rem_buf;
	logic			sgn_buf;

	logic	[n:0]	acc [m:0];
	logic	[m-1:0]	q;

	logic			stall;

	integer			counter;

	enum	logic	{IDLE, CALC} state;

	assign			ready_out	= ready_in && !stall;
	assign			stall		= state != IDLE;

	always_comb begin
		case (op_buf)
		UDIV:	y	= res_buf;
		SDIV:	y	= sgn_buf ? -res_buf : res_buf;
		UREM:	y	= rem_buf;
		SREM:	y	= sgn_buf ? -rem_buf : rem_buf;
		endcase
	end

	always_ff @(posedge clk) begin
		if (reset) begin
			a_buf		<= 'h0;
			b_buf		<= 'h0;
			op_buf		<= 2'b00;
			div_buf		<= 'h0;
			res_buf		<= 'h0;
			rem_buf		<= 'h0;
			sgn_buf		<= 1'b0;
			counter		<= 'h0;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end

		else if (valid_in && ready_out) begin
			a_buf	<= a;
			b_buf	<= b;
			op_buf	<= op;

			if ((op_buf == UDIV && op == UREM  ||
				 op_buf == UREM && op == UDIV  ||
				 op_buf == SDIV && op == SREM  ||
				 op_buf == SREM && op == SDIV) &&
				 a_buf == a && b_buf == b) begin
				valid_out	<= 1'b1;
				state		<= IDLE;
			end

			else begin
				rem_buf		<= 'h0;
				counter		<= 0;
				valid_out	<= 1'b0;
				state		<= CALC;

				case (op)
				SDIV:		begin
								div_buf	<= b[n-1] ? -b : b;
								res_buf	<= a[n-1] ? -a : a;
								sgn_buf	<= a[n-1] ^ b[n-1];
							end
				SREM:		begin
								div_buf	<= b[n-1] ? -b : b;
								res_buf	<= a[n-1] ? -a : a;
								sgn_buf	<= a[n-1];
							end
				default:	begin
								div_buf	<= b;
								res_buf	<= a;
								sgn_buf	<= 1'b0;
							end
				endcase
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						valid_out	<= 1'b0;
					end
			CALC:	begin
						res_buf	<= (res_buf << m) | q;
						rem_buf	<= acc[m];

						if (counter == n/m-1) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end

						else
							counter		<= counter + 1;
					end
		endcase
	end

	always_comb begin
		acc[0]	= rem_buf;

		for (integer i = 1; i <= m; i = i+1) begin
			acc[i]	= ((acc[i-1] << 1) | res_buf[n-i]) - div_buf;
			q[m-i]	= !acc[i][n];
			acc[i]	= q[m-i] ? acc[i] : ((acc[i-1] << 1) | res_buf[n-i]);
		end
	end

endmodule
