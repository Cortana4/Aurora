`include "AmberFive_constants.svh"

module int_multiplier
#(
	parameter		n = 32,
	parameter		m = 8
)
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,

	input	logic	[1:0]	op,

	input	logic	[n-1:0]	a,
	input	logic	[n-1:0]	b,

	output	logic	[n-1:0]	y,

	output	logic			busy,
	output	logic			ready
);

	logic	[1:0]		prev_op;
	logic	[n-1:0]		prev_a;
	logic	[n-1:0]		prev_b;
	
	logic	[1:0]		reg_op;
	logic	[n-1:0]		reg_b;
	logic	[2*n-1:0]	reg_res;
	logic				reg_sgn;

	logic	[n+m:0]		acc;

	integer				counter;

	enum	logic		{IDLE, CALC} state;

	assign				prev_op	= reg_op;

	always_comb begin
		case (reg_op)
		`UMULL:		y	= reg_res[n-1:0];
		`UMULH:		y	= reg_res[2*n-1:n];
		`SMULH,
		`SUMULH:	y	= reg_sgn ? -reg_res[2*n-1:n] : reg_res[2*n-1:n];
		endcase
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			prev_a	<= 0;
			prev_b	<= 0;
			reg_op	<= 2'd0;
			reg_b	<= 0;
			reg_res	<= 0;
			reg_sgn	<= 1'b0;
			counter	<= 0;
			state	<= IDLE;
			busy	<= 1'b0;
			ready	<= 1'b0;
		end

		else if (load) begin
			prev_a	<= a;
			prev_b	<= b;
			reg_op	<= op;
			
			if ((prev_op != `UMULL && op == `UMULL  ||
				 prev_op == `UMULL && op == `UMULH) &&
				 prev_a == a && prev_b == b) begin
				state	<= IDLE;
				busy	<= 1'b0;
				ready	<= 1'b1;
			end
			
			else begin
				counter	<= 0;
				state	<= CALC;
				busy	<= 1'b1;
				ready	<= 1'b0;

				case (op)
				`UMULL,
				`UMULH:		begin
								reg_b	<= b;
								reg_res	<= {{n{1'b0}}, a};
								reg_sgn	<= 1'b0;
							end
				`SMULH:		begin
								reg_b	<= b[n-1] ? -b : b;
								reg_res	<= {{n{1'b0}}, a[n-1] ? -a : a};
								reg_sgn	<= a[n-1] ^ b[n-1];
							end
				`SUMULH:	begin
								reg_b	<= b;
								reg_res	<= {{n{1'b0}}, a[n-1] ? -a : a};
								reg_sgn	<= a[n-1];
							end
				endcase
			end
		end

		else case (state)
			IDLE:	begin
						ready	<= 1'b0;
						busy	<= 1'b0;
					end
			CALC:	begin
						reg_res	<= {acc, reg_res[n-1:m]};

						if (counter == n/m-1) begin
							state	<= IDLE;
							busy	<= 1'b0;
							ready	<= 1'b1;
						end

						else
							counter	<= counter + 1;
					end
		endcase
	end

	always_comb begin
		acc	= {{m{1'b0}}, reg_res[2*n-1:n]};

		for (integer i = 0; i < m; i = i+1) begin
			if (reg_res[i])
				acc = acc + ({{m{1'b0}}, reg_b} << i);
		end
	end

endmodule