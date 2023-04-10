module fifo_buf
#(
	parameter		ADDR_WIDTH	= 4,
	parameter		DATA_WIDTH	= 8
)
(
	input	logic						clk,
	input	logic						reset,
	
	input	logic						wena,
	input	logic	[DATA_WIDTH-1:0]	wdata,

	input	logic						rena,
	output	logic	[DATA_WIDTH-1:0]	rdata,

	output	logic						empty,
	output	logic						full
);

	logic	[DATA_WIDTH-1:0]	buffer [2**ADDR_WIDTH-1:0];

	logic	[ADDR_WIDTH-1:0]	rptr;
	logic	[ADDR_WIDTH-1:0]	rptr_next;
	logic	[ADDR_WIDTH-1:0]	wptr;
	logic	[ADDR_WIDTH-1:0]	wptr_next;

	assign						rptr_next	= rptr + 1;
	assign						wptr_next	= wptr + 1;

	assign						rdata		= wena && rena && empty ? wdata : buffer[rptr];

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			rptr			<= 0;
			wptr			<= 0;
			empty			<= 1'b1;
			full			<= 1'b0;
		end

		else if (wena && rena) begin
			buffer[wptr]	<= wdata;
			write_ptr		<= wptr_next;
			read_ptr		<= rptr_next;
		end

		else if (wena && !full) begin
			buffer[wptr]	<= wdata;
			wptr			<= wptr_next;
			empty			<= 1'b0;
			full			<= wptr_next == rptr;
		end

		else if (rena && !empty) begin
			rptr			<= rptr_next;
			empty			<= rptr_next == wptr;
			full			<= 1'b0;
		end
	end

endmodule