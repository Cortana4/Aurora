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

	input	logic					wena,
	input	logic	[7:0]			wdata,
	output	logic	[ADDR_WIDTH:0]	size,
	output	logic					empty,
	output	logic					full
);

	logic	[1:0]	cts_stable;

	logic	[24:0]	counter;
	logic	[2:0]	bit_idx;

	logic			rena;
	logic	[7:0]	rdata;

	enum	logic	[2:0]	{IDLE, START, DATA, PARITY, STOP}	state;

	// cross clock domain
	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			cts_stable		<= 2'b11;

		else
			cts_stable		<= {cts_stable[0], cts};
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			tx		<= 1'b1;
			state	<= IDLE;
			counter	<= 25'h0000000;
			bit_idx	<= 3'b000;
			rena	<= 1'b0;
		end

		else case (state)
			IDLE:		begin
							tx		<= 1'b1;
							counter	<= 25'd1;
							bit_idx	<= 3'b000;
							// beginn transmission in IDLE state to compensate delay
							if (!empty && (!flow_ctrl || (flow_ctrl && !cts_stable[1]))) begin
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
								tx		<= rdata[bit_idx];
								counter	<= counter + 25'd1;
							end
						end
			PARITY:		begin
							if (counter == baud_reg - 24'd1) begin
								counter	<= 25'd0;
								state	<= STOP;
							end

							else begin
								tx		<= ^rdata;
								counter	<= counter + 25'd1;
							end
						end
			STOP:		begin
							if (rena) begin
								rena	<= 1'b0;
								state	<= IDLE;
							end

							else begin
								if ((!stop_bits	&& counter == baud_reg - 24'd2) ||
									(stop_bits	&& counter == (baud_reg << 1) - 24'd2))
									rena <= 1'b1;

								tx		<= 1'b1;
								counter	<= counter + 25'd1;
							end
						end
			default:	state <= IDLE;
		endcase
	end

	fifo_buf #(ADDR_WIDTH, 8) tx_fifo_buf
	(
		.clk	(clk),
		.reset	(reset),
		.clear	(clear),

		.wena	(wena),
		.wdata	(wdata),
		
		.rena	(rena),
		.rdata	(rdata),

		.size	(size),
		.empty	(empty),
		.full	(full)
	);

endmodule