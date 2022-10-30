`include "FPU_constants.svh"

module rounding_logic
#(
	parameter		n = 23
)
(
	input	logic	[2:0]	rm,

	input	logic			sticky_bit,
	input	logic			round_bit,

	input	logic	[n-1:0]	in,
	input	logic			sgn,

	output	logic	[n-1:0]	out,
	output	logic			carry,

	output	logic			inexact
);

	logic	r_and_s;
	logic	r_and_not_s;
	logic	r_or_s;
	logic	inc;

	assign	r_and_s			= round_bit && sticky_bit;
	assign	r_and_not_s		= round_bit && !sticky_bit;
	assign	r_or_s			= round_bit || sticky_bit;
	assign	inexact			= r_or_s;

	always_comb begin
		case (rm)
						// round to nearest, ties to even
		`FPU_RM_RNE:	inc	= r_and_s || (r_and_not_s && in[0]);

						// round to nearest, ties to max magnitude
		`FPU_RM_RMM:	inc	= r_and_s || (r_and_not_s && !in[0]);

						// round towards zero (truncate fraction)
		`FPU_RM_RTZ:	inc	= 1'b0;

						// round down (towards -inf)
		`FPU_RM_RDN:	inc	= r_or_s && sgn;

						// round up (towards +inf)
		`FPU_RM_RUP:	inc	= r_or_s && !sgn;

		default:		inc	= 1'b0;
		endcase
	end

	assign	{carry, out}	= in + inc;

endmodule