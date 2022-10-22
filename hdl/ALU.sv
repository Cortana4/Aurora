`include "AmberFive_constants.svh"

module ALU
(
	input	logic	[3:0]	op,
	
	input	logic	[31:0]	a,
	input	logic	[31:0]	b,
	
	output	logic	[31:0]	y
);

	always_comb begin
		case (op)
		`ALU_ADD:	y = a + b;
		`ALU_SUB:	y = a - b;
		`ALU_AND:	y = a & b;
		`ALU_OR:	y = a | b;
		`ALU_XOR:	y = a ^ b;
		`ALU_SLL:	y = a << b[4:0];
		`ALU_SRL:	y = a >> b[4:0];
		`ALU_SRA:	y = $signed(a) >>> b[4:0];
		`ALU_SEQ:	y = {31'b0, a == b};
		`ALU_SNE:	y = {31'b0, a != b};
		`ALU_SLT:	y = {31'b0, $signed(a) < $signed(b)};
		`ALU_SLTU:	y = {31'b0, a < b};
		`ALU_SGE:	y = {31'b0, $signed(a) >= $signed(b)};
		`ALU_SGEU:	y = {31'b0, a >= b};
		`ALU_INC:	y = a + 32'd4;
		default:	y = 32'h00000000;
		endcase
	end

endmodule