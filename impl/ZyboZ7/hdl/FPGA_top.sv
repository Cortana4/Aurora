`include "AmberFive_constants.svh"

module FPGA_top
(
	input	logic			ref_clk,
	input	logic			reset_btn,

	input	logic			mode_btn,
	output	logic			mode_led,

	output	logic			tx,
	input	logic			rx,
	input	logic			cts,
	output	logic			rts,

	output	logic			tx_led,
	output	logic			rx_led
);

	logic			clk;
	logic			reset;
	logic			mode;		// 0: run, 1: prog

	// CPU signals
	logic	[31:0]	imem_addr;
	logic	[31:0]	imem_addr_reg;
	logic	[31:0]	imem_dout;
	logic			imem_ena;

	logic	[31:0]	dmem_addr;
	logic	[31:0]	dmem_addr_reg;
	logic	[31:0]	dmem_din;
	logic	[31:0]	dmem_dout;
	logic			dmem_ena;
	logic	[3:0]	dmem_wen;

	// memory
	logic	[31:0]	ROM_dout_a;
	logic	[31:0]	ROM_dout_b;
	logic	[31:0]	RAM_dout_a;
	logic	[31:0]	RAM_dout_b;
	logic	[31:0]	RAM_din_b;

	// UART
	logic	[31:0]	UART_dout;
	logic			UART_int;

	// enable signals
	logic			read_ROM_a;
	logic			read_ROM_b;
	logic			read_RAM_a;
	logic			read_RAM_b;
	logic			read_UART;

	assign			read_ROM_a	= imem_addr_reg >= `ROM_BEG		&& imem_addr_reg <= `ROM_END;
	assign			read_ROM_b	= dmem_addr_reg >= `ROM_BEG		&& dmem_addr_reg <= `ROM_END;
	assign			read_RAM_a	= imem_addr_reg >= `RAM_BEG		&& imem_addr_reg <= `RAM_END;
	assign			read_RAM_b	= dmem_addr_reg >= `RAM_BEG		&& dmem_addr_reg <= `RAM_END;
	assign			read_UART	= dmem_addr_reg >= `UART_BEG	&& dmem_addr_reg <= `UART_END;

	assign			mode_led	= mode;
	assign			tx_led		= !tx;
	assign			rx_led		= !rx;

	logic	[23:0]	counter;
	logic	[3:0]	reset_btn_samples;
	logic	[3:0]	mode_btn_samples;

	// button debounce and prog/run mode switching logic
	always_ff @(negedge clk) begin
		// take one sample every 3 ms (1s = 16e6 cycles -> 3ms = 48000 cycles)
		if (counter == 24'd47999) begin
			reset_btn_samples	<= {reset_btn_samples[2:0], reset_btn};
			mode_btn_samples	<= {mode_btn_samples[2:0], mode_btn};
			counter				<= 24'h000000;

			// reset = 1 as long as reset button is pressed
			if (reset_btn_samples == 4'b1111) begin
				reset	<= 1'b1;
				mode	<= 1'b0;
			end
			// reset = 0 on falling reset button edge
			else if (reset_btn_samples == 4'b1000)
				reset	<= 1'b0;
			// switch between run and prog mode on rising mode button edge
			else if (mode_btn_samples == 4'b0111) begin
				mode	<= !mode;
				reset	<= 1'b1;
			end
			// reset = 0 on falling prog button edge
			else if (mode_btn_samples == 4'b1000)
				reset	<= 1'b0;
		end

		else
			counter	<= counter + 24'd1;
	end

	// imem_dout multiplexer
	always_comb begin
		if (read_ROM_a)
			imem_dout	= ROM_dout_a;

		else if (read_RAM_a)
			imem_dout	= RAM_dout_a;

		else
			imem_dout	= 32'h00000000;
	end

	// dmem_dout multiplexer
	always_comb begin
		if (read_ROM_b)
			dmem_dout = ROM_dout_b;

		else if (read_RAM_b)
			dmem_dout = RAM_dout_b;

		else if (read_UART)
			dmem_dout = UART_dout;

		else if (dmem_addr_reg == `MODE_SW)
			dmem_dout = {31'h00000000, mode};

		else
			dmem_dout = 32'h00000000;
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			dmem_addr_reg <= 32'h00000000;
			imem_addr_reg <= 32'h00000000;
		end

		else begin
			dmem_addr_reg <= dmem_addr;
			imem_addr_reg <= imem_addr;
		end
	end

	// ip cores
	// clock divider
	MMCM MMCM_inst
	(
		.clk_in1(ref_clk),
		.clk_out1(clk)
	);

	// dual port ROM
	// port a: instructions
	// port b: data
	ROM ROM_inst
	(
		.clka(clk),
		.addra(imem_addr[11:0]),
		.douta(ROM_dout_a),
		.ena(imem_ena),
		
		.clkb(clk),
		.addrb(dmem_addr[11:0]),
		.doutb(ROM_dout_b),
		.enb(dmem_ena)
	);

	// dual port SRAM
	// port a: instructions
	// port b: data
	RAM RAM_inst
	(
		.clka(clk),
		.addra(imem_addr[12:0]),
		.dina(32'h00000000),
		.douta(RAM_dout_a),
		.ena(imem_ena),
		.wea(4'b0000),
		
		.clkb(clk),
		.addrb(dmem_addr[12:0]),
		.dinb(dmem_din),
		.doutb(RAM_dout_b),
		.enb(dmem_ena),
		.web(dmem_addr >= `RAM_BEG && dmem_addr <= `RAM_END ? dmem_wen : 4'b0000)
	);
	
	AmberFive_pipeline AmberFive
	(
		.clk(clk),
		.reset(reset),

		.imem_addr(imem_addr),
		.imem_din(imem_dout),
		.imem_ena(imem_ena),

		.dmem_addr(dmem_addr),
		.dmem_dout(dmem_din),
		.dmem_din(dmem_dout),
		.dmem_ena(dmem_ena),
		.dmem_wen(dmem_wen)
	);

	// UART
	uart
	#(
		.BASE_ADDR(`UART_BEG),
		.TX_ADDR_WIDTH(5),
		.RX_ADDR_WIDTH(5)
	)
	uart_inst
	(
		.clk(clk),
		.reset(reset),

		.tx(tx),
		.rx(rx),
		.cts(cts),
		.rts(rts),

		.Int(),

		.dmem_addr(dmem_addr),
		.dmem_din(dmem_din),
		.dmem_dout(UART_dout),
		.write(|dmem_wen)
	);
endmodule