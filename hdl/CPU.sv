import CPU_pkg::*;

module CPU
(
	input	logic			clk,
	input	logic			reset,
	
// interrupt request signals
	input	logic	[15:0]	int_req_ext,
	input	logic			int_req_ictrl,
	input	logic			int_req_timer,
	input	logic			int_req_soft,

// imem port
	// write address channel
	output	logic	[31:0]	imem_axi_awaddr,
	output	logic	[2:0]	imem_axi_awprot,
	output	logic			imem_axi_awvalid,
	input	logic			imem_axi_awready,
	// write data channel
	output	logic	[31:0]	imem_axi_wdata,
	output	logic	[3:0]	imem_axi_wstrb,
	output	logic			imem_axi_wvalid,
	input	logic			imem_axi_wready,
	// write response channel
	input	logic	[1:0]	imem_axi_bresp,
	input	logic			imem_axi_bvalid,
	output	logic			imem_axi_bready,
	// read address channel
	output	logic	[31:0]	imem_axi_araddr,
	output	logic	[2:0]	imem_axi_arprot,
	output	logic			imem_axi_arvalid,
	input	logic			imem_axi_arready,
	// read data channel
	input	logic	[31:0]	imem_axi_rdata,
	input	logic	[1:0]	imem_axi_rresp,
	input	logic			imem_axi_rvalid,
	output	logic			imem_axi_rready,

// dmem port
	// write address channel
	output	logic	[31:0]	dmem_axi_awaddr,
	output	logic	[2:0]	dmem_axi_awprot,
	output	logic			dmem_axi_awvalid,
	input	logic			dmem_axi_awready,
	// write data channel
	output	logic	[31:0]	dmem_axi_wdata,
	output	logic	[3:0]	dmem_axi_wstrb,
	output	logic			dmem_axi_wvalid,
	input	logic			dmem_axi_wready,
	// write response channel
	input	logic	[1:0]	dmem_axi_bresp,
	input	logic			dmem_axi_bvalid,
	output	logic			dmem_axi_bready,
	// read address channel
	output	logic	[31:0]	dmem_axi_araddr,
	output	logic	[2:0]	dmem_axi_arprot,
	output	logic			dmem_axi_arvalid,
	input	logic			dmem_axi_arready,
	// read data channel
	input	logic	[31:0]	dmem_axi_rdata,
	input	logic	[1:0]	dmem_axi_rresp,
	input	logic			dmem_axi_rvalid,
	output	logic			dmem_axi_rready,

// uart
	output	logic			tx,
	input	logic			rx,
	input	logic			cts,
	output	logic			rts
);

// axi interconnect
	// write address channel
	logic	[31:0]	m_axi_awaddr;
	logic	[2:0]	m_axi_awprot;
	logic			m_axi_awvalid;
	logic			m_axi_awready;
	// write data channel
	logic	[31:0]	m_axi_wdata;
	logic	[3:0]	m_axi_wstrb;
	logic			m_axi_wvalid;
	logic			m_axi_wready;
	// write response channel
	logic	[1:0]	m_axi_bresp;
	logic			m_axi_bvalid;
	logic			m_axi_bready;
	// read address channel
	logic	[31:0]	m_axi_araddr;
	logic	[2:0]	m_axi_arprot;
	logic			m_axi_arvalid;
	logic			m_axi_arready;
	// read data channel
	logic	[31:0]	m_axi_rdata;
	logic	[1:0]	m_axi_rresp;
	logic			m_axi_rvalid;
	logic			m_axi_rready;

// uart
	logic			uart_ena;
	logic			uart_wen;
	logic	[31:0]	uart_addr;
	logic	[31:0]	uart_wdata;
	logic	[31:0]	uart_rdata;
	logic			uart_int;

	pipeline pipeline_inst
	(
		.clk(clk),
		.reset(reset),
		
		.int_req_ext(int_req_ext),
		.int_req_ictrl(int_req_ictrl),
		.int_req_timer(int_req_timer),
		.int_req_soft(int_req_soft),

		.imem_axi_awaddr(imem_axi_awaddr),
		.imem_axi_awprot(imem_axi_awprot),
		.imem_axi_awvalid(imem_axi_awvalid),
		.imem_axi_awready(imem_axi_awready),
		.imem_axi_wdata(imem_axi_wdata),
		.imem_axi_wstrb(imem_axi_wstrb),
		.imem_axi_wvalid(imem_axi_wvalid),
		.imem_axi_wready(imem_axi_wready),
		.imem_axi_bresp(imem_axi_bresp),
		.imem_axi_bvalid(imem_axi_bvalid),
		.imem_axi_bready(imem_axi_bready),
		.imem_axi_araddr(imem_axi_araddr),
		.imem_axi_arprot(imem_axi_arprot),
		.imem_axi_arvalid(imem_axi_arvalid),
		.imem_axi_arready(imem_axi_arready),
		.imem_axi_rdata(imem_axi_rdata),
		.imem_axi_rresp(imem_axi_rresp),
		.imem_axi_rvalid(imem_axi_rvalid),
		.imem_axi_rready(imem_axi_rready),
		
		.dmem_axi_awaddr(m_axi_awaddr),
		.dmem_axi_awprot(m_axi_awprot),
		.dmem_axi_awvalid(m_axi_awvalid),
		.dmem_axi_awready(m_axi_awready),
		.dmem_axi_wdata(m_axi_wdata),
		.dmem_axi_wstrb(m_axi_wstrb),
		.dmem_axi_wvalid(m_axi_wvalid),
		.dmem_axi_wready(m_axi_wready),
		.dmem_axi_bresp(m_axi_bresp),
		.dmem_axi_bvalid(m_axi_bvalid),
		.dmem_axi_bready(m_axi_bready),
		.dmem_axi_araddr(m_axi_araddr),
		.dmem_axi_arprot(m_axi_arprot),
		.dmem_axi_arvalid(m_axi_arvalid),
		.dmem_axi_arready(m_axi_arready),
		.dmem_axi_rdata(m_axi_rdata),
		.dmem_axi_rresp(m_axi_rresp),
		.dmem_axi_rvalid(m_axi_rvalid),
		.dmem_axi_rready(m_axi_rready)
	);
	
	bus_interconnect bus_interconnect_inst
	(
		.clk(clk),
		.reset(reset),
		
		.s_axi_awaddr(m_axi_awaddr),
		.s_axi_awprot(m_axi_awprot),
		.s_axi_awvalid(m_axi_awvalid),
		.s_axi_awready(m_axi_awready),
		.s_axi_wdata(m_axi_wdata),
		.s_axi_wstrb(m_axi_wstrb),
		.s_axi_wvalid(m_axi_wvalid),
		.s_axi_wready(m_axi_wready),
		.s_axi_bresp(m_axi_bresp),
		.s_axi_bvalid(m_axi_bvalid),
		.s_axi_bready(m_axi_bready),
		.s_axi_araddr(m_axi_araddr),
		.s_axi_arprot(m_axi_arprot),
		.s_axi_arvalid(m_axi_arvalid),
		.s_axi_arready(m_axi_arready),
		.s_axi_rdata(m_axi_rdata),
		.s_axi_rresp(m_axi_rresp),
		.s_axi_rvalid(m_axi_rvalid),
		.s_axi_rready(m_axi_rready),

		.m_axi_awaddr(dmem_axi_awaddr),
		.m_axi_awprot(dmem_axi_awprot),
		.m_axi_awvalid(dmem_axi_awvalid),
		.m_axi_awready(dmem_axi_awready),
		.m_axi_wdata(dmem_axi_wdata),
		.m_axi_wstrb(dmem_axi_wstrb),
		.m_axi_wvalid(dmem_axi_wvalid),
		.m_axi_wready(dmem_axi_wready),
		.m_axi_bresp(dmem_axi_bresp),
		.m_axi_bvalid(dmem_axi_bvalid),
		.m_axi_bready(dmem_axi_bready),
		.m_axi_araddr(dmem_axi_araddr),
		.m_axi_arprot(dmem_axi_arprot),
		.m_axi_arvalid(dmem_axi_arvalid),
		.m_axi_arready(dmem_axi_arready),
		.m_axi_rdata(dmem_axi_rdata),
		.m_axi_rresp(dmem_axi_rresp),
		.m_axi_rvalid(dmem_axi_rvalid),
		.m_axi_rready(dmem_axi_rready),

		.uart_ena(uart_ena),
		.uart_wen(uart_wen),
		.uart_addr(uart_addr),
		.uart_wdata(uart_wdata),
		.uart_rdata(uart_rdata)
	);
	
	uart
	#(
		.BASE_ADDR(UART_BASE_ADDR),
		.TX_ADDR_WIDTH(5),
		.RX_ADDR_WIDTH(5)
	) uart_inst
	(
		.clk(clk),
		.reset(reset),

		.ena(uart_ena),
		.wen(uart_wen),
		.addr(uart_addr),
		.wdata(uart_wdata),
		.rdata(uart_rdata),

		.tx(tx),
		.rx(rx),
		.cts(cts),
		.rts(rts),

		.Int(uart_int)
	);

endmodule