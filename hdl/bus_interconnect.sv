module bus_interconnect
(
	input	logic			clk,
	input	logic			reset,
	
// slave port
	// write address channel
	input	logic	[31:0]	s_axi_awaddr,
	input	logic	[2:0]	s_axi_awprot,
	input	logic			s_axi_awvalid,
	output	logic			s_axi_awready,
	// write data channel
	input	logic	[31:0]	s_axi_wdata,
	input	logic	[3:0]	s_axi_wstrb,
	input	logic			s_axi_wvalid,
	output	logic			s_axi_wready,
	// write response channel
	output	logic	[1:0]	s_axi_bresp,
	output	logic			s_axi_bvalid,
	input	logic			s_axi_bready,
	// read address channel
	input	logic	[31:0]	s_axi_araddr,
	input	logic	[2:0]	s_axi_arprot,
	input	logic			s_axi_arvalid,
	output	logic			s_axi_arready,
	// read data channel
	output	logic	[31:0]	s_axi_rdata,
	output	logic	[1:0]	s_axi_rresp,
	output	logic			s_axi_rvalid,
	input	logic			s_axi_rready,
	
// master port
	// write address channel
	output	logic	[31:0]	m_axi_awaddr,
	output	logic	[2:0]	m_axi_awprot,
	output	logic			m_axi_awvalid,
	input	logic			m_axi_awready,
	// write data channel
	output	logic	[31:0]	m_axi_wdata,
	output	logic	[3:0]	m_axi_wstrb,
	output	logic			m_axi_wvalid,
	input	logic			m_axi_wready,
	// write response channel
	input	logic	[1:0]	m_axi_bresp,
	input	logic			m_axi_bvalid,
	output	logic			m_axi_bready,
	// read address channel
	output	logic	[31:0]	m_axi_araddr,
	output	logic	[2:0]	m_axi_arprot,
	output	logic			m_axi_arvalid,
	input	logic			m_axi_arready,
	// read data channel
	input	logic	[31:0]	m_axi_rdata,
	input	logic	[1:0]	m_axi_rresp,
	input	logic			m_axi_rvalid,
	output	logic			m_axi_rready,

// uart port
	output	logic			uart_ena,
	output	logic			uart_wen,
	output	logic	[31:0]	uart_addr,
	output	logic	[31:0]	uart_wdata,
	input	logic	[31:0]	uart_rdata
);

	logic			bypass_rdata;
	logic	[31:0]	rdata_reg;
	
	logic			uart_rvalid;
	logic			uart_rvalid_set;
	
	always_comb begin
		// write address channel
		m_axi_awaddr	= s_axi_awaddr;
		m_axi_awprot	= s_axi_awprot;
		m_axi_awvalid	= s_axi_awvalid;
		s_axi_awready	= m_axi_awready;
		// write data channel
		m_axi_wdata		= s_axi_wdata;
		m_axi_wstrb		= s_axi_wstrb;
		m_axi_wvalid	= s_axi_wvalid;
		s_axi_wready	= m_axi_wready;
		// write response channel
		s_axi_bresp		= m_axi_bresp;
		s_axi_bvalid	= m_axi_bvalid;
		m_axi_bready	= s_axi_bready;
		// read address channel
		m_axi_araddr	= s_axi_araddr;
		m_axi_arprot	= s_axi_arprot;
		m_axi_arvalid	= s_axi_arvalid;
		s_axi_arready	= m_axi_arready;
		
		uart_ena		= 1'b0;
		uart_wen		= 1'b0;
		uart_addr		= s_axi_awaddr;
		uart_wdata		= s_axi_wdata;
		uart_rvalid_set	= 1'b0;

		// write access (store)
		if (s_axi_awvalid && s_axi_wvalid) begin
			if ((s_axi_awaddr >= UART_BASE_ADDR) &&
				(s_axi_awaddr <  UART_BASE_ADDR + UART_LEN)) begin
				m_axi_awvalid	= 1'b0;
				s_axi_awready	= 1'b1;
				m_axi_wvalid	= 1'b0;
				s_axi_wready	= 1'b1;
				s_axi_bresp		= 2'b00;
				s_axi_bvalid	= 1'b1;
				m_axi_bready	= 1'b0;
				uart_ena		= 1'b1;
				uart_wen		= 1'b1;
			end
		end
		
		// read access (load)
		else if (s_axi_arvalid) begin
			if ((s_axi_araddr >= UART_BASE_ADDR) &&
				(s_axi_araddr <  UART_BASE_ADDR + UART_LEN)) begin
				m_axi_arvalid	= 1'b0;
				s_axi_arready	= 1'b1;
				uart_ena		= 1'b1;
				uart_wen		= 1'b0;
				uart_rvalid_set	= 1'b1;
			end
		end
	end
	
	always_comb begin
		// read data channel
		s_axi_rdata		= m_axi_rdata;
		s_axi_rresp		= m_axi_rresp;
		s_axi_rvalid	= m_axi_rvalid;
		m_axi_rready	= s_axi_rready;
		
		if (uart_rvalid) begin
			s_axi_rdata		= bypass_rdata ? uart_rdata : rdata_reg;
			s_axi_rresp		= 2'b00;
			s_axi_rvalid	= 1'b1;
			m_axi_rready	= 1'b0;
		end
	end
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			rdata_reg		<= 32'h00000000;
			bypass_rdata	<= 1'b1;
			uart_rvalid		<= 1'b0;
		end
		
		else if (uart_rvalid) begin
			if (s_axi_rready) begin
				uart_rvalid		<= 1'b0;
				bypass_rdata	<= 1'b1;
			end
				
			else if (bypass_rdata) begin
				rdata_reg		<= uart_rdata;
				bypass_rdata	<= 1'b0;
			end
		end

		else if (s_axi_arvalid) begin
			uart_rvalid	<= uart_rvalid_set;

		end
	end

endmodule