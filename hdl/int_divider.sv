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
	
	logic	[1:0]	prev_op;
	logic	[n-1:0]	prev_a;
	logic	[n-1:0]	prev_b;
	
	logic	[1:0]	reg_op;
	logic	[n-1:0]	reg_b;
	logic	[n-1:0]	reg_res;
	logic	[n:0]	reg_rem;
	logic			reg_sgn;

	logic	[n:0]	acc [m:0];
	logic	[m-1:0]	q;
	
	logic			stall;

	integer			counter;

	enum	logic	{IDLE, CALC} state;

	assign			prev_op		= reg_op;
	
	assign			ready_out	= ready_in && !stall;
	assign			stall		= state != IDLE;

	always_comb begin
		case (reg_op)
		UDIV:	y	= reg_res;
		SDIV:	y	= reg_sgn ? -reg_res : reg_res;
		UREM:	y	= reg_rem;
		SREM:	y	= reg_sgn ? -reg_rem : reg_rem;
		endcase
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out	<= 1'b0;
			prev_a		<= 0;
			prev_b		<= 0;
			reg_op		<= 2'b00;
			reg_b		<= 0;
			reg_res		<= 0;
			reg_rem		<= 0;
			reg_sgn		<= 1'b0;
			counter		<= 0;
			state		<= IDLE;
		end

		else if (valid_in && ready_out) begin
			prev_a	<= a;
			prev_b	<= b;
			reg_op	<= op;
			
			if ((prev_op == UDIV && op == UREM  ||
				 prev_op == UREM && op == UDIV  ||
				 prev_op == SDIV && op == SREM  ||
				 prev_op == SREM && op == SDIV) &&
				 prev_a == a && prev_b == b) begin
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			
			else begin
				valid_out	<= 1'b0;
				reg_rem		<= 0;
				counter		<= 0;
				state		<= CALC;

				case (op)
				UDIV,
				UREM:	begin
							reg_b	<= b;
							reg_res	<= a;
							reg_sgn	<= 1'b0;
						end
				SDIV:	begin
							reg_b	<= b[n-1] ? -b : b;
							reg_res	<= a[n-1] ? -a : a;
							reg_sgn	<= a[n-1] ^ b[n-1];
						end
				SREM:	begin
							reg_b	<= b[n-1] ? -b : b;
							reg_res	<= a[n-1] ? -a : a;
							reg_sgn	<= a[n-1];
						end
				endcase
			end
		end

		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						valid_out	<= 1'b0;
					end
			CALC:	begin
						reg_res	<= (reg_res << m) | q;
						reg_rem	<= acc[m];

						if (counter == n/m-1) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end

						else
							counter	<= counter + 1;
					end
		endcase
	end

	always_comb begin
		acc[0]	= reg_rem;

		for (integer i = 1; i <= m; i = i+1) begin
			acc[i]	= ((acc[i-1] << 1) | reg_res[n-i]) - reg_b;
			q[m-i]	= !acc[i][n];
			acc[i]	= q[m-i] ? acc[i] : ((acc[i-1] << 1) | reg_res[n-i]);
		end
	end

endmodule
