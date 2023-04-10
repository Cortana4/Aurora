module priority_encoder
#(
	parameter	n = 3
)
(
	input	logic	[2**n-1:0]	x,
	output	logic	[n-1:0]		y
);

	logic [2**n-1:0]	part;
	
	always_comb begin
		y		= 0;
		part	= x;

		for (integer i = n-1; i >= 0; i = i-1) begin
			if (|(part >> 2**i)) begin
				y[i]	= 1'b1;
				part	= part >> 2**i;
			end
			
			else begin
				y[i]	= 1'b0;
				part	= part & ((1'b1 << 2**i) - 1'b1);
			end
		end
	end
	
endmodule
