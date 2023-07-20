module RAM
#(
	parameter		n = 8	// data bits
)
(
	input	logic			clk,

	input	logic	[n-1:0]	addra,
	input	logic	[31:0]	dina,
	output	logic	[31:0]	douta,
	input	logic			ena,
	input	logic	[3:0]	wea,

	input	logic	[n-1:0]	addrb,
	input	logic	[31:0]	dinb,
	output	logic	[31:0]	doutb,
	input	logic			enb,
	input	logic	[3:0]	web
);

	logic	[31:0]	mem	[2**n];

	always_ff @(posedge clk) begin
		if (ena) begin
			if (wea[3])	mem[addra][31:24]	<= dina[31:24];
			if (wea[2])	mem[addra][23:16]	<= dina[23:16];
			if (wea[1])	mem[addra][15:8]	<= dina[15:8];
			if (wea[0])	mem[addra][7:0]		<= dina[7:0];

			douta	<= mem[addra];
		end

		if (enb) begin
			if (web[3])	mem[addrb][31:24]	<= dinb[31:24];
			if (web[2])	mem[addrb][23:16]	<= dinb[23:16];
			if (web[1])	mem[addrb][15:8]	<= dinb[15:8];
			if (web[0])	mem[addrb][7:0]		<= dinb[7:0];

			doutb	<= mem[addrb];
		end
	end

endmodule