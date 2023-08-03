module RAM
#(
	parameter		RAM_DEPTH	= 16384,
	parameter		COL_WIDTH	= 8,
	parameter		COL_NUM		= 4	
)
(
	input	logic							clk,

	input	logic	[$clog2(RAM_DEPTH)-1:0]	addra,
	input	logic	[COL_NUM*COL_WIDTH-1:0]	dina,
	output	logic	[COL_NUM*COL_WIDTH-1:0]	douta,
	input	logic							ena,
	input	logic	[COL_NUM-1:0]			wea,

	input	logic	[$clog2(RAM_DEPTH)-1:0]	addrb,
	input	logic	[COL_NUM*COL_WIDTH-1:0]	dinb,
	output	logic	[COL_NUM*COL_WIDTH-1:0]	doutb,
	input	logic							enb,
	input	logic	[COL_NUM-1:0]			web
);

	generate
		for (genvar i = 0; i < COL_NUM; i = i+1) begin
			logic	[COL_WIDTH-1:0]	ram	[RAM_DEPTH];
			
			always_ff @(posedge clk) begin
				if (ena) begin
					if (wea[i]) begin
						ram[addra]						<= dina[i*COL_WIDTH+:COL_WIDTH];
						douta[i*COL_WIDTH+:COL_WIDTH]	<= dina[i*COL_WIDTH+:COL_WIDTH];
					end
					
					else
						douta[i*COL_WIDTH+:COL_WIDTH]	<= ram[addra];
				end
			end
			
			always_ff @(posedge clk) begin
				if (enb) begin
					if (web[i]) begin
						ram[addrb]						<= dinb[i*COL_WIDTH+:COL_WIDTH];
						doutb[i*COL_WIDTH+:COL_WIDTH]	<= dinb[i*COL_WIDTH+:COL_WIDTH];
					end
					
					else
						doutb[i*COL_WIDTH+:COL_WIDTH]	<= ram[addrb];
				end
			end
		end
	endgenerate

endmodule