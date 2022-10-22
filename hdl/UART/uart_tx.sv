module uart_tx
#(
	parameter		ADDR_WIDTH = 5
)
(
	input	logic					clk,
	input	logic					reset,
	input	logic					clear,

	output	logic					tx,
	input	logic					cts,

	input	logic					flow_ctrl,
	input	logic					parity,
	input	logic					stop_bits,
	input	logic					data_bits,
	input	logic	[23:0]			baud_reg,

	input	logic					push,
	input	logic	[7:0]			data_in,
	output	logic	[ADDR_WIDTH:0]	size,
	output	logic					empty,
	output	logic					full
);

	logic			cts_metastable;
	logic			cts_stable;

	logic	[24:0]	counter;
	logic	[2:0]	bit_idx;

	logic			pop;
	logic	[7:0]	data;

	enum	logic	[2:0]	{IDLE, START, DATA, PARITY, STOP}	state;

	// remove metastability
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			cts_metastable	<= 1'b1;
			cts_stable		<= 1'b1;
		end

		else begin
			cts_metastable	<= cts;
			cts_stable		<= cts_metastable;
		end
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			tx		<= 1'b1;
			state	<= IDLE;
			counter	<= 25'h0000000;
			bit_idx	<= 3'b000;
			pop		<= 1'b0;
		end

		else case (state)
			IDLE:		begin
							tx		<= 1'b1;
							counter	<= 25'd1;
							bit_idx	<= 3'b000;
							// beginn transmission in IDLE state to compensate delay
							if (!empty && (!flow_ctrl || (flow_ctrl && !cts_stable))) begin
								tx		<= 1'b0;
								state	<= START;
							end
						end
			START:		begin
							// wait until start bit is finished
							if (counter == baud_reg - 24'd1) begin
								counter	<= 25'd0;
								state	<= DATA;
							end

							else
								counter <= counter + 25'd1;
						end
			DATA:		begin
							if (counter == baud_reg - 24'd1) begin
								counter <= 25'd0;

								if (bit_idx == data_bits + 3'd6)
									state <= parity ? PARITY : STOP;

								else
									bit_idx <= bit_idx + 3'd1;
							end

							else begin
								tx		<= data[bit_idx];
								counter	<= counter + 25'd1;
							end
						end
			PARITY:		begin
							if (counter == baud_reg - 24'd1) begin
								counter	<= 25'd0;
								state	<= STOP;
							end

							else begin
								tx		<= ^data;
								counter	<= counter + 25'd1;
							end
						end
			STOP:		begin
							if (pop) begin
								pop		<= 1'b0;
								state	<= IDLE;
							end

							else begin
								if ((!stop_bits	&& counter == baud_reg - 24'd2) ||
									(stop_bits	&& counter == (baud_reg << 1) - 24'd2))
									pop <= 1'b1;

								tx		<= 1'b1;
								counter	<= counter + 25'd1;
							end
						end
			default:	state <= IDLE;
		endcase
	end

	fifo_stack #(ADDR_WIDTH, 8) tx_fifo_stack
	(
		.reset(reset),
		.clear(clear),
		.clk(clk),

		// write port
		.push(push),
		.data_in(data_in),

		// read port
		.pop(pop),
		.data_out(data),

		.size(size),
		.empty(empty),
		.full(full)
	);

endmodule