module fifo_buf
#(
	parameter		ADDR_WIDTH	= 4,
	parameter		DATA_WIDTH	= 8
)
(
	input	logic						clk,
	input	logic						reset,
	input	logic						clear,

	input	logic						wena,
	input	logic	[DATA_WIDTH-1:0]	wdata,

	input	logic						rena,
	output	logic	[DATA_WIDTH-1:0]	rdata,

	output	logic	[ADDR_WIDTH:0]		size,
	output	logic						empty,
	output	logic						full
);

	logic	[DATA_WIDTH-1:0]	buffer		[2**ADDR_WIDTH-1:0];

	logic	[ADDR_WIDTH-1:0]	rPtr;
	logic	[ADDR_WIDTH-1:0]	rPtr_next;
	logic	[ADDR_WIDTH-1:0]	wPtr;
	logic	[ADDR_WIDTH-1:0]	wPtr_next;

	assign						rPtr_next	= rPtr + 1;
	assign						wPtr_next	= wPtr + 1;

	assign						rdata		= buffer[rPtr];
	assign						size		= {full, wPtr - rPtr};

	always_ff @(posedge clk, posedge reset) begin
		if (reset || clear) begin
			rPtr	<= 0;
			wPtr	<= 0;
			empty	<= 1'b1;
			full	<= 1'b0;
		end

		else if (wena && rena && !empty) begin
			wPtr	<= wPtr_next;
			rPtr	<= rPtr_next;
		end

		else if (wena && !full) begin
			wPtr	<= wPtr_next;
			empty	<= 1'b0;
			full	<= wPtr_next == rPtr;
		end

		else if (rena && !empty) begin
			rPtr	<= rPtr_next;
			empty	<= rPtr_next == wPtr;
			full	<= 1'b0;
		end
	end
	
	always_ff @(posedge clk) begin
		if (wena && (!full || (rena && !empty)))
			buffer[wPtr]	<= wdata;
	end

endmodule