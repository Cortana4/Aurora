module sign_modifier
(
	input	logic			clk,
	input	logic			reset,
	input	logic			load,
	
	input	logic			op_sgnj,
	input	logic			op_sgnjn,
	input	logic			op_sgnjx,

	input	logic	[31:0]	a,
	input	logic			sgn_b,
	
	output	logic	[31:0]	float_out,
	
	output	logic			ready
);
	
	logic	sgn_a;
	assign	sgn_a = a[31];

	always_ff @(posedge clk, posedge reset) begin
		if (reset || (load && !(op_sgnj || op_sgnjn || op_sgnjx))) begin
			float_out	<= 32'h00000000;
			ready		<= 1'b0;
		end
		
		else if (load) begin
			if (op_sgnj)
				float_out <= {sgn_b, a[30:0]};
			
			else if (op_sgnjn)
				float_out <= {!sgn_b, a[30:0]};
			
			else if (op_sgnjx)
				float_out <= {sgn_a ^ sgn_b, a[30:0]};
				
			ready	<= 1'b1;
		end
		
		else
			ready	<= 1'b0;
	end

endmodule