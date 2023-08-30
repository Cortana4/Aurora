module addr_buf
#(
	parameter		ADDR_WIDTH	= 4,
	parameter		DATA_WIDTH	= 8
)
(
	input	logic						clk,
	input	logic						reset,
	input	logic						flush,
	
	input	logic						wena,
	input	logic	[DATA_WIDTH-1:0]	wdata,

	input	logic						rena,
	output	logic	[DATA_WIDTH-1:0]	rdata,
	output	logic						valid,

	output	logic						empty,
	output	logic						full
);

	logic	[DATA_WIDTH-1:0]	data_buf	[2**ADDR_WIDTH-1:0];
	logic						valid_buf	[2**ADDR_WIDTH-1:0];

	logic	[ADDR_WIDTH-1:0]	rPtr;
	logic	[ADDR_WIDTH-1:0]	rPtr_next;
	logic	[ADDR_WIDTH-1:0]	wPtr;
	logic	[ADDR_WIDTH-1:0]	wPtr_next;

	assign						rPtr_next	= rPtr + 1;
	assign						wPtr_next	= wPtr + 1;

	assign						rdata		= data_buf[rPtr];
	assign						valid		= valid_buf[rPtr];

	always_ff @(posedge clk) begin
		if (reset) begin
			rPtr			<= 0;
			wPtr			<= 0;
			empty			<= 1'b1;
			full			<= 1'b0;
		end

		else if (wena && rena && !empty) begin
			wPtr			<= wPtr_next;
			rPtr			<= rPtr_next;
		end

		else if (wena && !full) begin
			wPtr			<= wPtr_next;
			empty			<= 1'b0;
			full			<= wPtr_next == rPtr;
		end

		else if (rena && !empty) begin
			rPtr			<= rPtr_next;
			empty			<= rPtr_next == wPtr;
			full			<= 1'b0;
		end
	end
	
	always_ff @(posedge clk) begin
		if (wena && (!full || (rena && !empty)))
			data_buf[wPtr]	<= wdata;
	end
	
	always_ff @(posedge clk) begin
		if (reset || flush) begin
			for (integer i = 0; i < 2**ADDR_WIDTH; i = i+1)
				valid_buf[i]	<= 1'b0;
		end
		
		else if (wena && rena && !empty) begin
			valid_buf[rPtr]	<= 1'b0;
			valid_buf[wPtr]	<= 1'b1;
		end
		
		else if (wena && !full)
			valid_buf[wPtr]	<= 1'b1;
		
		else if (rena && !empty)
			valid_buf[rPtr]	<= 1'b0;
	end

endmodule