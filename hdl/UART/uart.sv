module uart
#(
	parameter	BASE_ADDR		= 'h00000000,
	parameter	TX_ADDR_WIDTH	= 5,
	parameter	RX_ADDR_WIDTH	= 5
)
(
	input	logic				clk,
	input	logic				reset,

	output	logic				tx,
	input	logic				rx,
	input	logic				cts,
	output	logic				rts,

	output	logic				Int,

	input	logic	[31:0]		dmem_addr,
	input	logic	[31:0]		dmem_din,
	output	logic	[31:0]		dmem_dout,
	input	logic				write
);

	`define	STACK_ADDR			BASE_ADDR + 0
	`define	CTRL_REG_ADDR		BASE_ADDR + 1
	`define	CTRL_SET_ADDR		BASE_ADDR + 2
	`define	CTRL_CLR_ADDR		BASE_ADDR + 3
	`define	TX_STAT_REG_ADDR	BASE_ADDR + 4
	`define	TX_STAT_SET_ADDR	BASE_ADDR + 5
	`define	TX_STAT_CLR_ADDR	BASE_ADDR + 6
	`define	RX_STAT_REG_ADDR	BASE_ADDR + 7
	`define	RX_STAT_SET_ADDR	BASE_ADDR + 8
	`define	RX_STAT_CLR_ADDR	BASE_ADDR + 9

	logic	[31:0]				dmem_addr_reg;
	logic						write_reg;

	logic						push;
	logic	[7:0]				data_in;
	logic						pop;
	logic	[7:0]				data_out;

	assign						push			= write && dmem_addr == `STACK_ADDR;
	assign						data_in			= dmem_din[7:0];
	assign						pop				= !write_reg && dmem_addr_reg == `STACK_ADDR;

	// control signals
	logic	[31:0]				ctrl_reg;
	logic	[23:0]				baud_reg;		// = c_bit = clock_freq / baud rate (system clock cycles per bit)
	logic						data_bits;		// 7, 8
	logic						stop_bits;		// 1, 2
	logic						parity;			// none, even
	logic						flow_ctrl;		// off, on (RTS/CTS)

	assign						ctrl_reg		=
								{	// signal	// bits		// access
									4'b0000,
									flow_ctrl,	// 27		// rw
									parity,		// 26		// rw
									stop_bits,	// 25		// rw
									data_bits,	// 24		// rw
									baud_reg	// 23-0		// rw
								};

	// tx status signals
	logic	[31:0]				tx_stat_reg;
	logic	[TX_ADDR_WIDTH:0]	tx_size;
	logic	[TX_ADDR_WIDTH:0]	tx_watermark;
	logic						tx_full;
	logic						tx_empty;
	logic						tx_watermark_reached;
	logic						tx_overflow_error;
	logic						tx_empty_IE;
	logic						tx_watermark_reached_IE;
	logic						tx_overflow_error_IE;
	logic						tx_clear;

	assign						tx_stat_reg		=
								{	// signal				// bit		// access
									// byte 3
									tx_clear,				// 31		// rw
									4'b0000,
									tx_overflow_error_IE,	// 26		// rw
									tx_watermark_reached_IE,// 25		// rw
									tx_empty_IE,			// 24		// rw
									// byte 2
									4'b0000,
									tx_overflow_error,		// 19		// rw
									tx_watermark_reached,	// 18		// r
									tx_empty,				// 17		// r
									tx_full,				// 16		// r
									// byte 1
									{(7-TX_ADDR_WIDTH){1'b0}},
									tx_watermark,			// 15-8		// rw
									// byte 0
									{(7-TX_ADDR_WIDTH){1'b0}},
									tx_size					// 7-0		// r
								};

	// rx status signals
	logic	[31:0]				rx_stat_reg;
	logic	[RX_ADDR_WIDTH:0]	rx_size;
	logic	[RX_ADDR_WIDTH:0]	rx_watermark;
	logic						rx_full;
	logic						rx_empty;
	logic						rx_watermark_reached;
	logic						rx_overflow_error;			logic overflow_error_w;
	logic						rx_underflow_error;
	logic						rx_noise_error;				logic noise_error_w;
	logic						rx_parity_error;			logic parity_error_w;
	logic						rx_frame_error;				logic frame_error_w;
	logic						rx_full_IE;
	logic						rx_watermark_reached_IE;
	logic						rx_overflow_error_IE;
	logic						rx_underflow_error_IE;
	logic						rx_noise_error_IE;
	logic						rx_parity_error_IE;
	logic						rx_frame_error_IE;
	logic						rx_clear;

	assign						rx_stat_reg		=
								{	// signal				// bit		// access
									// byte 3
									rx_clear,				// 31		// rw
									rx_frame_error_IE,		// 30		// rw
									rx_parity_error_IE,		// 29		// rw
									rx_noise_error_IE,		// 28		// rw
									rx_underflow_error_IE,	// 27		// rw
									rx_overflow_error_IE,	// 26		// rw
									rx_watermark_reached_IE,// 25		// rw
									rx_full_IE,				// 24		// rw
									// byte 2
									rx_frame_error,			// 23		// rw
									rx_parity_error,		// 22		// rw
									rx_noise_error,			// 21		// rw
									rx_underflow_error,		// 20		// rw
									rx_overflow_error,		// 19		// rw
									rx_watermark_reached,	// 18		// r
									rx_empty,				// 17		// r
									rx_full,				// 16		// r
									// byte 1
									{(7-RX_ADDR_WIDTH){1'b0}},
									rx_watermark,			// 15-8		// rw
									// byte 0
									{(7-RX_ADDR_WIDTH){1'b0}},
									rx_size					// 7-0		// r
								};

	assign						tx_watermark_reached		= tx_size <= tx_watermark;
	assign						rx_watermark_reached		= rx_size >= rx_watermark;

	assign						Int				=
									tx_empty				&& tx_empty_IE				||
									tx_watermark_reached	&& tx_watermark_reached_IE	||
									tx_overflow_error		&& tx_overflow_error_IE		||
									rx_full					&& rx_full_IE				||
									rx_watermark_reached	&& rx_watermark_reached_IE	||
									rx_overflow_error		&& rx_overflow_error_IE		||
									rx_underflow_error		&& rx_underflow_error_IE	||
									rx_noise_error			&& rx_noise_error_IE		||
									rx_parity_error			&& rx_parity_error_IE		||
									rx_frame_error			&& rx_frame_error_IE;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			dmem_addr_reg			<= 32'h00000000;
			write_reg				<= 1'b0;
			// default UART settings
			flow_ctrl				<= 1'b1;
			parity					<= 1'b1;
			data_bits				<= 1'b1;
			stop_bits				<= 1'b0;
			baud_reg				<= 24'd69;	// cycles_per_bit = clock_freq / baud = 16 MHz / 230400
			// default status and interrupt settings
			tx_watermark			<= 0;
			rx_watermark			<= 1;

			tx_clear				<= 1'b0;
			tx_overflow_error_IE	<= 1'b0;
			tx_watermark_reached_IE	<= 1'b0;
			tx_empty_IE				<= 1'b0;

			rx_clear				<= 1'b0;
			rx_frame_error_IE		<= 1'b0;
			rx_parity_error_IE		<= 1'b0;
			rx_noise_error_IE		<= 1'b0;
			rx_underflow_error_IE	<= 1'b0;
			rx_overflow_error_IE	<= 1'b0;
			rx_watermark_reached_IE	<= 1'b0;
			rx_full_IE				<= 1'b0;

			tx_overflow_error		<= 1'b0;
			rx_frame_error			<= 1'b0;
			rx_parity_error			<= 1'b0;
			rx_noise_error			<= 1'b0;
			rx_underflow_error		<= 1'b0;
			rx_overflow_error		<= 1'b0;
		end

		else begin
			dmem_addr_reg			<= dmem_addr;
			write_reg				<= write;
			// refresh status signals
			tx_overflow_error		<= tx_overflow_error	|| push && tx_full;
			rx_frame_error			<= rx_frame_error		|| frame_error_w;
			rx_parity_error			<= rx_parity_error		|| parity_error_w;
			rx_noise_error			<= rx_noise_error		|| noise_error_w;
			rx_underflow_error		<= rx_underflow_error	|| pop && rx_empty;
			rx_overflow_error		<= rx_overflow_error	|| overflow_error_w;
			tx_clear				<= 1'b0;
			rx_clear				<= 1'b0;

			// write access
			if (write) begin
				case (dmem_addr)
				`CTRL_REG_ADDR:		begin
										flow_ctrl				<= dmem_din[28];
										parity					<= dmem_din[26];
										data_bits				<= dmem_din[25];
										stop_bits				<= dmem_din[24];
										baud_reg				<= dmem_din[23:0];
									end
				`CTRL_SET_ADDR:		begin
										flow_ctrl				<= dmem_din[28]   || flow_ctrl;
										parity					<= dmem_din[26]   || parity;
										data_bits				<= dmem_din[25]   || data_bits;
										stop_bits				<= dmem_din[24]   || stop_bits;
										baud_reg				<= dmem_din[23:0] |  baud_reg;
									end
				`CTRL_CLR_ADDR:		begin
										flow_ctrl				<= !dmem_din[28]   && flow_ctrl;
										parity					<= !dmem_din[26]   && parity;
										data_bits				<= !dmem_din[25]   && data_bits;
										stop_bits				<= !dmem_din[24]   && stop_bits;
										baud_reg				<= ~dmem_din[23:0] &  baud_reg;
									end
				`TX_STAT_REG_ADDR:	begin
										tx_clear				<= dmem_din[31];
										tx_overflow_error_IE	<= dmem_din[26];
										tx_watermark_reached_IE	<= dmem_din[25];
										tx_empty_IE				<= dmem_din[24];
										tx_overflow_error		<= dmem_din[19];
										tx_watermark			<= dmem_din[15:8];
									end
				`TX_STAT_SET_ADDR:	begin
										tx_clear				<= dmem_din[31]   || tx_clear;
										tx_overflow_error_IE	<= dmem_din[26]   || tx_overflow_error_IE;
										tx_watermark_reached_IE	<= dmem_din[25]   || tx_watermark_reached_IE;
										tx_empty_IE				<= dmem_din[24]   || tx_empty_IE;
										tx_overflow_error		<= dmem_din[19]   || tx_overflow_error;
										tx_watermark			<= dmem_din[15:8] |  tx_watermark;
									end
				`TX_STAT_CLR_ADDR:	begin
										tx_clear				<= !dmem_din[31]   && tx_clear;
										tx_overflow_error_IE	<= !dmem_din[26]   && tx_overflow_error_IE;
										tx_watermark_reached_IE	<= !dmem_din[25]   && tx_watermark_reached_IE;
										tx_empty_IE				<= !dmem_din[24]   && tx_empty_IE;
										tx_overflow_error		<= !dmem_din[19]   && tx_overflow_error;
										tx_watermark			<= !dmem_din[15:8] &  tx_watermark;
									end
				`RX_STAT_REG_ADDR:	begin
										rx_clear				<= dmem_din[31];
										rx_frame_error_IE		<= dmem_din[30];
										rx_parity_error_IE		<= dmem_din[29];
										rx_noise_error_IE		<= dmem_din[28];
										rx_underflow_error_IE	<= dmem_din[27];
										rx_overflow_error_IE	<= dmem_din[26];
										rx_watermark_reached_IE	<= dmem_din[25];
										rx_full_IE				<= dmem_din[24];
										rx_frame_error			<= dmem_din[23];
										rx_parity_error			<= dmem_din[22];
										rx_noise_error			<= dmem_din[21];
										rx_underflow_error		<= dmem_din[20];
										rx_overflow_error		<= dmem_din[19];
										rx_watermark			<= dmem_din[15:8];
									end
				`RX_STAT_SET_ADDR:	begin
										rx_clear				<= dmem_din[31]   || rx_clear;
										rx_frame_error_IE		<= dmem_din[30]   || rx_parity_error_IE;
										rx_parity_error_IE		<= dmem_din[29]   || rx_parity_error_IE;
										rx_noise_error_IE		<= dmem_din[28]   || rx_noise_error_IE;
										rx_underflow_error_IE	<= dmem_din[27]   || rx_underflow_error_IE;
										rx_overflow_error_IE	<= dmem_din[26]   || rx_overflow_error_IE;
										rx_watermark_reached_IE	<= dmem_din[25]   || rx_watermark_reached_IE;
										rx_full_IE				<= dmem_din[24]   || rx_full_IE;
										rx_frame_error			<= dmem_din[23]   || rx_frame_error;
										rx_parity_error			<= dmem_din[22]   || rx_parity_error;
										rx_noise_error			<= dmem_din[21]   || rx_noise_error;
										rx_underflow_error		<= dmem_din[20]   || rx_underflow_error;
										rx_overflow_error		<= dmem_din[19]   || rx_overflow_error;
										rx_watermark			<= dmem_din[15:8] |  rx_watermark;
									end
				`RX_STAT_CLR_ADDR:	begin
										rx_clear				<= !dmem_din[31]   && rx_clear;
										rx_frame_error_IE		<= !dmem_din[30]   && rx_parity_error_IE;
										rx_parity_error_IE		<= !dmem_din[29]   && rx_parity_error_IE;
										rx_noise_error_IE		<= !dmem_din[28]   && rx_noise_error_IE;
										rx_underflow_error_IE	<= !dmem_din[27]   && rx_underflow_error_IE;
										rx_overflow_error_IE	<= !dmem_din[26]   && rx_overflow_error_IE;
										rx_watermark_reached_IE	<= !dmem_din[25]   && rx_watermark_reached_IE;
										rx_full_IE				<= !dmem_din[24]   && rx_full_IE;
										rx_frame_error			<= !dmem_din[23]   && rx_frame_error;
										rx_parity_error			<= !dmem_din[22]   && rx_parity_error;
										rx_noise_error			<= !dmem_din[21]   && rx_noise_error;
										rx_underflow_error		<= !dmem_din[20]   && rx_underflow_error;
										rx_overflow_error		<= !dmem_din[19]   && rx_overflow_error;
										rx_watermark			<= !dmem_din[15:8] &  rx_watermark;
									end
				endcase
			end
		end
	end

	always_comb begin
		dmem_dout = 32'h00000000;
		// read access
		if (!write_reg) begin
			case (dmem_addr_reg)
			`STACK_ADDR:		dmem_dout = {24'h000000, data_out};
			`CTRL_REG_ADDR:		dmem_dout = ctrl_reg;
			`TX_STAT_REG_ADDR:	dmem_dout = tx_stat_reg;
			`RX_STAT_REG_ADDR:	dmem_dout = rx_stat_reg;
			endcase
		end
	end

	uart_tx #(TX_ADDR_WIDTH) transmitter
	(
		.clk(clk),
		.reset(reset),
		.clear(tx_clear),

		.tx(tx),
		.cts(cts),

		.flow_ctrl(flow_ctrl),
		.parity(parity),
		.stop_bits(stop_bits),
		.data_bits(data_bits),
		.baud_reg(baud_reg),

		.push(push),
		.data_in(data_in),
		.size(tx_size),
		.empty(tx_empty),
		.full(tx_full)
	);

	uart_rx #(RX_ADDR_WIDTH) receiver
	(
		.clk(clk),
		.reset(reset),
		.clear(rx_clear),

		.rx(rx),
		.rts(rts),

		.flow_ctrl(flow_ctrl),
		.parity(parity),
		.stop_bits(stop_bits),
		.data_bits(data_bits),
		.baud_reg(baud_reg),

		.pop(pop),
		.data_out(data_out),
		.size(rx_size),
		.empty(rx_empty),
		.full(rx_full),

		.noise_error(noise_error_w),
		.parity_error(parity_error_w),
		.frame_error(frame_error_w),
		.overflow_error(overflow_error_w)
	);

endmodule