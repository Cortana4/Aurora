module fifo_stack
#(
	parameter		ADDR_WIDTH	= 4,
	parameter		DATA_WIDTH	= 8
)
(
	input	logic						reset,
	input	logic						clear,
	input	logic						clk,

	// write port
	input	logic						push,
	input	logic	[DATA_WIDTH-1:0]	data_in,

	// read port
	input	logic						pop,
	output	logic	[DATA_WIDTH-1:0]	data_out,

	output	logic	[ADDR_WIDTH:0]		size,
	output	logic						empty,
	output	logic						full
);

	logic	[DATA_WIDTH-1:0]	stack[2**ADDR_WIDTH-1:0];

	logic	[ADDR_WIDTH-1:0]	read_ptr;
	logic	[ADDR_WIDTH-1:0]	read_ptr_next;
	logic	[ADDR_WIDTH-1:0]	write_ptr;
	logic	[ADDR_WIDTH-1:0]	write_ptr_next;

	assign						read_ptr_next	= read_ptr + 1;
	assign						write_ptr_next	= write_ptr + 1;

	assign						data_out		= push && pop && empty ? data_in : stack[read_ptr];
	assign						size			= {full, write_ptr - read_ptr};

	integer i;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			for (i = 0; i < 2**ADDR_WIDTH; i = i+1)
				stack[i]	<= 0;

			read_ptr			<= 0;
			write_ptr			<= 0;
			empty				<= 1'b1;
			full				<= 1'b0;
		end

		else if (clear) begin
			for (i = 0; i < 2**ADDR_WIDTH; i = i+1)
				stack[i]	<= 0;

			read_ptr			<= 0;
			write_ptr			<= 0;
			empty				<= 1'b1;
			full				<= 1'b0;
		end

		else if (push && pop) begin
			stack[write_ptr]	<= data_in;
			stack[read_ptr]		<= 0;
			write_ptr			<= write_ptr_next;
			read_ptr			<= read_ptr_next;
		end

		else if (push && !full) begin
			stack[write_ptr]	<= data_in;
			write_ptr			<= write_ptr_next;
			empty				<= 1'b0;

			if (write_ptr_next == read_ptr)
				full	<= 1'b1;
		end

		else if (pop && !empty) begin
			stack[read_ptr]		<= 0;
			read_ptr			<= read_ptr_next;
			full				<= 1'b0;

			if (read_ptr_next == write_ptr)
				empty	<= 1'b1;
		end
	end

endmodule