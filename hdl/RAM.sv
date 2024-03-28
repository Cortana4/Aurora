module RAM
#(
	parameter		RAM_DEPTH	= 16384,
	parameter		COL_WIDTH	= 8,
	parameter		COL_NUM		= 4,
	parameter		LATENCY		= 1
)
(
	input	logic							clk,
	input	logic							rst,

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

	logic	[COL_NUM*COL_WIDTH-1:0]	ram	[RAM_DEPTH];
	logic	[COL_NUM*COL_WIDTH-1:0]	douta_buf;
	logic	[COL_NUM*COL_WIDTH-1:0]	doutb_buf;

	generate
		for (genvar i = 0; i < COL_NUM; i = i+1) begin
			always_ff @(posedge clk) begin
				if (ena) begin
					if (wea[i])	
						ram[addra][i*COL_WIDTH+:COL_WIDTH]	<= dina[i*COL_WIDTH+:COL_WIDTH];
					douta_buf[i*COL_WIDTH+:COL_WIDTH]		<= ram[addra][i*COL_WIDTH+:COL_WIDTH];
				end
			end
			
			always_ff @(posedge clk) begin
				if (enb) begin
					if (web[i])
						ram[addrb][i*COL_WIDTH+:COL_WIDTH]	<= dinb[i*COL_WIDTH+:COL_WIDTH];
					doutb_buf[i*COL_WIDTH+:COL_WIDTH]		<= ram[addrb][i*COL_WIDTH+:COL_WIDTH];
				end
			end
		end
	endgenerate
	
	generate
		if (LATENCY == 1) begin
			assign	douta	= douta_buf;
			assign	doutb	= doutb_buf;
		end
		
		else begin
			always_ff @(posedge clk) begin
				if (rst) begin
					douta	<= {(COL_NUM*COL_WIDTH-1){1'b0}};
					doutb	<= {(COL_NUM*COL_WIDTH-1){1'b0}};
				end
				
				else begin
					douta	<= douta_buf;
					doutb	<= doutb_buf;
				end
			end
		end
	endgenerate

endmodule