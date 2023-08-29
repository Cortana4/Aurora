import CPU_pkg::*;

module int_multiplier_dsp
#(
	parameter		n = 32,
	parameter		m = 0
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

	logic	signed	[n:0]			a_buf, a_int;
	logic	signed	[n:0]			b_buf, b_int;
	logic	signed	[2*(n+1)-1:0]	y_buf[m:0];
	logic			[1:0]			op_buf;
	
	logic							stall;
	
	integer							counter;

	enum	logic	{IDLE, CALC}	state;
	
	assign							ready_out	= ready_in && !stall;
	assign							stall		= state != IDLE;
	
	always_comb begin
		a_int[n-1:0]	= a;
		b_int[n-1:0]	= b;
		
		// sign extend
		case (op)
		SMULH:		begin
						a_int[n]	= a[n-1];
						b_int[n]	= b[n-1];
					end
		SUMULH:		begin
						a_int[n]	= a[n-1];
						b_int[n]	= 1'b0;
					end
		default:	begin
						a_int[n]	= 1'b0;
						b_int[n]	= 1'b0;
					end
		endcase
	end
	
	always_comb begin
		case (op_buf)
		UMULL:		y = y_buf[m][0*n+:n];
		default:	y = y_buf[m][1*n+:n];
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			a_buf		<= 'h0;
			b_buf		<= 'h0;
			y_buf		<= {'h0};
			op_buf		<= 'h0;
			counter		<= 0;
			valid_out	<= 1'b0;
			state		<= IDLE;
		end
		
		else if (valid_in && ready_out) begin
			a_buf		<= a_int;
			b_buf		<= b_int;
			op_buf		<= op;
			counter		<= 0;
			
			if (a_int == a_buf && b_int == b_buf) begin
				valid_out	<= 1'b1;
				state		<= IDLE;
			end
			
			else begin
				valid_out	<= 1'b0;
				state		<= CALC;
			end
		end
		
		else case (state)
			IDLE:	if (valid_out && ready_in) begin
						valid_out	<= 1'b0;
					end
			CALC:	begin
						y_buf[0]	<= a_buf * b_buf;
			
						for (integer i = 0; i < m; i = i+1)
							y_buf[i+1]	<= y_buf[i];
				
						if (counter == m) begin
							valid_out	<= 1'b1;
							state		<= IDLE;
						end
						
						else
							counter		<= counter + 1;
					end
		endcase
	end
	
	/*
	always_ff @(posedge clk) begin
		if (reset) begin
			a_buf			<= 'h0;
			b_buf			<= 'h0;
			y_buf			<= 'h0;
		end
		
		else begin
			a_buf[n-1:0]	<= a;
			b_buf[n-1:0]	<= b;
			
			case (op)
			SMULH:		begin
							a_buf[n]	<= a[n-1];
							b_buf[n]	<= b[n-1];
						end
			SUMULH:		begin
							a_buf[n]	<= a[n-1];
							b_buf[n]	<= 1'b0;
						end
			default:	begin
							a_buf[n]	<= 1'b0;
							b_buf[n]	<= 1'b0;
						end
			endcase
			
			y_buf[0]	<= a_buf * b_buf;
			
			for (integer i = 0; i < m; i = i+1)
				y_buf[i+1]	<= y_buf[i];
		end
	end*/
	
endmodule