module rshifter
#(
	parameter		n = 8,	// data bits
	parameter		s = 3	// select bits
)
(
	input	logic	[n-1:0]	in,
	input	logic	[s-1:0]	sel,
	input	logic			sgn,

	output	logic	[n-1:0]	out,
	output	logic			sticky_bit
);

	logic	[n-1:0]	out_int [s-1:0];
	logic	[s-1:0]	sticky_bit_int;

	assign			out			= out_int[s-1];
	assign			sticky_bit	= |sticky_bit_int;

	generate
		for (genvar i = 0; i < s; i = i+1) begin
			if (i == 0) begin
				rshifter_static #(n, 2**i) rshifter_static_inst
				(
					.in			(in),
					.sel		(sel[i]),
					.sgn		(sgn),

					.out		(out_int[i]),
					.sticky_bit	(sticky_bit_int[i])
				);
			end

			else begin
				rshifter_static #(n, 2**i) rshifter_static_inst
				(
					.in			(out_int[i-1]),
					.sel		(sel[i]),
					.sgn		(sgn),

					.out		(out_int[i]),
					.sticky_bit	(sticky_bit_int[i])
				);
			end
		end
	endgenerate

endmodule