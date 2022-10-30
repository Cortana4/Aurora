// super fast leading zero counter
module leading_zero_counter_24
(
	input	logic	[23:0]	in,
	output	logic	[4:0]	y,
	output	logic			a
);

	logic	[5:0]	a_int;
	logic	[1:0]	y_int [5:0];

	logic			a5_nand_a4;
	logic			a3_nand_a2;
	logic			a1_nand_a0;

	assign			a5_nand_a4	= !(a_int[5] && a_int[4]);
	assign			a3_nand_a2	= !(a_int[3] && a_int[2]);
	assign			a1_nand_a0	= !(a_int[1] && a_int[0]);
	assign			a			= !a1_nand_a0 && y[4];

	always_comb begin
		y[4] = !(a5_nand_a4 || a3_nand_a2);
		y[3] = !(a5_nand_a4 || (!a3_nand_a2 && a1_nand_a0));
		y[2] =
			(!a_int[0] && a_int[1] && a_int[5] && a_int[3]) ||
			(!(a_int[2] && a_int[4]) && !(a_int[4] && !a_int[3]) && a_int[5]);

		case (y[4:2])
		3'b000:		y[1:0] = y_int[5];
		3'b001:		y[1:0] = y_int[4];
		3'b010:		y[1:0] = y_int[3];
		3'b011:		y[1:0] = y_int[2];
		3'b100:		y[1:0] = y_int[1];
		3'b101:		y[1:0] = y_int[0];
		default:	y[1:0] = 2'b00;
		endcase
	end

	generate
		for (genvar i = 0; i < 6; i = i + 1) begin: gen_LZC_4
			leading_zero_counter_4 LZC_4_inst
			(
				.in(in[i*4+3:i*4]),
				.y(y_int[i]),
				.a(a_int[i])
			);
		end
	endgenerate

endmodule