module uart_rx
#(
	parameter		ADDR_WIDTH = 5
)
(
	input	logic					clk,
	input	logic					reset,
	input	logic					clear,

	input	logic					rx,
	output	logic					rts,

	input	logic					flow_ctrl,
	input	logic					parity,
	input	logic					stop_bits,
	input	logic					data_bits,
	input	logic	[23:0]			baud_reg,

	input	logic					pop,
	output	logic	[7:0]			data_out,
	output	logic	[ADDR_WIDTH:0]	size,
	output	logic					empty,
	output	logic					full,

	output	logic					noise_error,
	output	logic					parity_error,
	output	logic					frame_error,
	output	logic					overflow_error
);

	logic		[1:0]	rx_stable;

	logic		[24:0]	counter;
	logic		[2:0]	samples;
	logic		[2:0]	bit_idx;
	logic				abort;

	logic				push;
	logic		[7:0]	data;

	logic				noise_e_reg;
	logic				parity_e_reg;

	enum	logic		[2:0]			{IDLE, START, DATA, PARITY, STOP}	state;

	assign				noise_error		= (noise_e_reg || !(samples == 3'b111 || samples == 3'b000)) && (push || abort);
	assign				parity_error	= parity_e_reg && push;
	assign				frame_error		= (!(&samples[2:1] || &samples[1:0] || (samples[2] && samples[0]))) && push;
	assign				overflow_error	= full && !pop && push;
	// to prevent data loss, rts is set some bytes before the rx stack is full
	assign				rts				= flow_ctrl ? size > (2**ADDR_WIDTH - 4) : 1'b0;

	// remove metastability
	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			rx_stable		<= 2'b11;

		else
			rx_stable		<= {rx_stable[0], rx};
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			noise_e_reg		<= 1'b0;
			parity_e_reg	<= 1'b0;
			state			<= IDLE;
			counter			<= 25'h0000000;
			samples			<= 3'b000;
			bit_idx			<= 3'b000;
			abort			<= 1'b0;
			push			<= 1'b0;
			data			<= 8'h00;
		end

		else case (state)
						// start bit detected
			IDLE:		begin
							noise_e_reg		<= 1'b0;
							parity_e_reg	<= 1'b0;
							counter			<= 25'd1;
							samples			<= 3'b000;
							bit_idx			<= 3'b000;
							abort			<= 1'b0;
							data			<= 8'h00;

							if (!rx_stable[1])
								state	<= START;
						end
			START:		begin
							// wait until start bit is finished
							if (counter == baud_reg - 24'd1) begin
								// major value of start bit should be 0
								if (!(&samples[2:1] || &samples[1:0] || (samples[2] && samples[0]))) begin
									noise_e_reg <= |samples;
									counter		<= 25'd0;
									state		<= DATA;
								end
								// abort otherwise
								else begin
									noise_e_reg	<= 1'b1;
									abort		<= 1'b1;
									state		<= IDLE;
								end
							end
							// read 3 samples around the middle of the start Bit
							else begin
								// c_bit / 2 - c_bit / 16
								if (counter == (baud_reg >> 1) - (baud_reg >> 4))
									samples[0]	<= rx_stable[1];
								// c_bit / 2
								if (counter == baud_reg >> 1)
									samples[1]	<= rx_stable[1];
								// c_bit / 2 + c_bit / 16
								if (counter == (baud_reg >> 1) + (baud_reg >> 4))
									samples[2]	<= rx_stable[1];

								counter	<= counter + 25'd1;
							end
						end
			DATA:		begin
							// wait until data bit is finished
							if (counter == baud_reg - 24'd1) begin
								// shift in major value of all samples left (LSB is received first)
								data		<= {&samples[2:1] || &samples[1:0] || (samples[2] && samples[0]), data[7:1]};
								noise_e_reg	<= noise_e_reg || !(samples == 3'b111 || samples == 3'b000);
								counter		<= 25'd0;

								// last data bit received
								if (bit_idx == data_bits + 3'd6)
									state	<= parity ? PARITY : STOP;

								// receive next data bit
								else
									bit_idx	<= bit_idx + 3'd1;
							end
							// read 3 samples around the middle of each data bit
							else begin
								// c_bit / 2 - c_bit / 16
								if (counter == (baud_reg >> 1) - (baud_reg >> 4))
									samples[0]	<= rx_stable[1];
								// c_bit / 2
								if (counter == baud_reg >> 1)
									samples[1]	<= rx_stable[1];
								// c_bit / 2 + c_bit / 16
								if (counter == (baud_reg >> 1) + (baud_reg >> 4))
									samples[2]	<= rx_stable[1];

								counter	<= counter + 25'd1;
							end
						end
			PARITY:		begin
							// wait until parity bit is finished
							if (counter == baud_reg - 24'd1) begin
								noise_e_reg		<= noise_e_reg || !(samples == 3'b111 || samples == 3'b000);
								// error if parity received != parity computed
								parity_e_reg	<= (&samples[2:1] || &samples[1:0] || (samples[2] && samples[0])) != (^data);
								counter			<= 25'd0;
								state			<= STOP;
							end
							// read 3 samples around the middle of the parity bit
							else begin
								// c_bit / 2 - c_bit / 16
								if (counter == (baud_reg >> 1) - (baud_reg >> 4))
									samples[0]	<= rx_stable[1];
								// c_bit / 2
								if (counter == baud_reg >> 1)
									samples[1]	<= rx_stable[1];
								// c_bit / 2 + c_bit / 16
								if (counter == (baud_reg >> 1) + (baud_reg >> 4))
									samples[2]	<= rx_stable[1];

								counter	<= counter + 25'd1;
							end
						end
			STOP:		begin
							if (push) begin
								push	<= 1'b0;
								counter	<= 25'd0;
								state	<= IDLE;
							end

							else begin
								if ((!stop_bits	&& counter == baud_reg - 24'd2) ||
									(stop_bits	&& counter == (baud_reg << 1) - 24'd2)) begin
									// because LSB is received first, data has to be aligned
									push		<= 1'b1;
									data		<= data >> !data_bits;
								end
								// read 3 samples around the middle of the stop bit
								// c_bit / 2 - c_bit / 16
								// 2 * (c_bit / 2 - c_bit / 16) = c_bit - c_bit / 8
								if ((!stop_bits	&& counter == (baud_reg >> 1) - (baud_reg >> 4)) ||
									(stop_bits	&& counter == baud_reg - (baud_reg >> 3)))
									samples[0]	<= rx_stable[1];

								// c_bit / 2
								// 2 * (c_bit / 2) = c_bit
								if ((!stop_bits	&& counter == baud_reg >> 1) ||
									(stop_bits	&& counter == baud_reg))
									samples[1]	<= rx_stable[1];

								// c_bit / 2 + c_bit / 16
								// 2 * (c_bit / 2 + c_bit / 16) = c_bit + c_bit / 8
								if ((!stop_bits	&& counter == (baud_reg >> 1) + (baud_reg >> 4)) ||
									(stop_bits	&& counter == baud_reg + (baud_reg >> 3)))
									samples[2]	<= rx_stable[1];

								counter	<= counter + 25'd1;
							end
						end
			default:	state	<= IDLE;
		endcase
	end

	fifo_stack #(ADDR_WIDTH, 8) rx_fifo_stack
	(
		.reset(reset),
		.clear(clear),
		.clk(clk),

		// write port
		.push(push),
		.data_in(data),

		// read port
		.pop(pop),
		.data_out(data_out),

		.size(size),
		.empty(empty),
		.full(full)
	);

endmodule