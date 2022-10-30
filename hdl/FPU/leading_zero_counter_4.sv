// leading zero counter sub modul
module leading_zero_counter_4
(
	input	logic	[3:0]	in,
	output	logic	[1:0]	y,
	output	logic			a
);

	assign	a		= ~|in;
	assign	y[0]	= !((in[1] && !in[2]) || in[3]);
	assign	y[1]	= ~|in[3:2];

endmodule