import FPU_pkg::*;

module sign_modifier
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic	[4:0]	op,

	input	logic	[31:0]	a,
	input	logic			sgn_b,
	
	output	logic	[31:0]	float_out
);
	
	logic	sgn_a;
	assign	sgn_a		= a[31];
	
	assign	ready_out	= ready_in && (op == FPU_OP_SGNJ || op == FPU_OP_SGNJN || op == FPU_OP_SGNJX);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out	<= 1'b0;
			float_out	<= 32'h00000000;
		end
		
		else if (valid_in && ready_out) begin
			valid_out	<= 1'b1;
			float_out	<= 32'h00000000;
			
			case (op)
			FPU_OP_SGNJ:	float_out <= {sgn_b, a[30:0]};
			FPU_OP_SGNJN:	float_out <= {!sgn_b, a[30:0]};
			FPU_OP_SGNJX:	float_out <= {sgn_a ^ sgn_b, a[30:0]};
			endcase
		end
		
		else if (valid_out && ready_in) begin
			alid_out	<= 1'b0;
			float_out	<= 32'h00000000;
		end
	end

endmodule