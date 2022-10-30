module rshifter_static
#(
	parameter		n		= 8,
	parameter		offset	= 1
)
(
	input	logic	[n-1:0]	in,
	input	logic			sel,
	input	logic			sgn,

	output	logic	[n-1:0]	out,
	output	logic			sticky_bit
);

	always_comb begin
		if (sel) begin
			out			= {{offset{sgn}}, in[n-1:offset]};
			sticky_bit	= |in[offset-1:0];
		end

		else begin
			out			= in;
			sticky_bit	= 1'b0;
		end
	end

endmodule