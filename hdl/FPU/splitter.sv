module splitter
(
	input	logic	[31:0]	float_in,

	output	logic	[23:0]	man,
	output	logic	[7:0]	Exp,
	output	logic			sgn,

	output	logic			zero,
	output	logic			inf,
	output	logic			sNaN,
	output	logic			qNaN,
	output	logic			denormal
);
	logic	hidden_bit;
	logic	max_exp;
	logic	man_NZ;
	logic	NaN;

	assign	sgn			= float_in[31];
	assign	Exp			= float_in[30:23];
	assign	man[22:0]	= float_in[22:0];

	assign	hidden_bit	= |Exp;
	// 1 if exponent is the highes possible (unbiased: 255, biased: 128 or inf)
	assign	max_exp		= &Exp;
	// 1 if the mantissa is unequal to zero
	assign	man_NZ		= |man[22:0];
	// 1 if the input is either sNaN or qNaN
	assign	NaN			= max_exp && man_NZ;

	assign	man[23]		= hidden_bit;
	assign	denormal	= !hidden_bit;
	assign	zero		= !hidden_bit && !man_NZ;
	assign	inf			= !man_NZ && max_exp;
	assign	sNaN		= !float_in[22] && NaN;
	assign	qNaN		= float_in[22] && NaN;

endmodule