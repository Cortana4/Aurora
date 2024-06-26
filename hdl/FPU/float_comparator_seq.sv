import FPU_pkg::*;

module float_comparator_seq
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic	[4:0]	op,

	input	logic	[31:0]	a,
	input	logic	[31:0]	b,

	output	logic	[31:0]	int_out,
	output	logic			IV
);

	logic	y;

	logic	sNaN_a;
	logic	qNaN_a;
	logic	sNaN_b;
	logic	qNaN_b;

	logic	equal;
	logic	less;

	logic	valid_in_int;

	assign	int_out			= {31'h00000000, y};

	assign	valid_in_int	= valid_in && (op == FPU_OP_SEQ || op == FPU_OP_SLE || op == FPU_OP_SLT);
	assign	ready_out		= ready_in;

	always_ff @(posedge clk) begin
		if (reset) begin
			y			<= 1'b0;
			IV			<= 1'b0;
			valid_out	<= 1'b0;
		end

		else if (valid_in_int && ready_out) begin
			y			<= 1'b0;
			IV			<= 1'b0;
			valid_out	<= 1'b1;

			case (op)
			FPU_OP_SEQ:	begin
							y	<= equal;
							IV	<= sNaN_a || sNaN_b;
						end
			FPU_OP_SLT:	begin
							y	<= less;
							IV	<= sNaN_a || qNaN_a || sNaN_b || qNaN_b;
						end
			FPU_OP_SLE:	begin
							y	<= less || equal;
							IV	<= sNaN_a || qNaN_a || sNaN_b || qNaN_b;
						end
			endcase
		end

		else if (valid_out && ready_in) begin
			y			<= 1'b0;
			IV			<= 1'b0;
			valid_out	<= 1'b0;
		end
	end

	float_comparator_comb float_comparator_inst
	(
		.a			(a),
		.b			(b),

		.sNaN_a		(sNaN_a),
		.qNaN_a		(qNaN_a),
		.sNaN_b		(sNaN_b),
		.qNaN_b		(qNaN_b),

		.greater	(),
		.equal		(equal),
		.less		(less),
		.unordered	()
	);

endmodule
