module bus_multiplexer
#(
	parameter					N		= 2,
	parameter					BASE	= {32'h10000000, 32'h20000000},
	parameter					LEN		= {32'h10000000, 32'h10000000}
)
(
	input	logic				clk,
	input	logic				reset,
	
// axi slave port (from cpu)
	// write address channel
	input	logic	[31:0]		s_axi_awaddr,
	input	logic	[2:0]		s_axi_awprot,
	input	logic				s_axi_awvalid,
	output	logic				s_axi_awready,
	// write data channel
	input	logic	[31:0]		s_axi_wdata,
	input	logic	[3:0]		s_axi_wstrb,
	input	logic				s_axi_wvalid,
	output	logic				s_axi_wready,
	// write response channel
	output	logic	[1:0]		s_axi_bresp,
	output	logic				s_axi_bvalid,
	input	logic				s_axi_bready,
	// read address channel
	input	logic	[31:0]		s_axi_araddr,
	input	logic	[2:0]		s_axi_arprot,
	input	logic				s_axi_arvalid,
	output	logic				s_axi_arready,
	// read data channel
	output	logic	[31:0]		s_axi_rdata,
	output	logic	[1:0]		s_axi_rresp,
	output	logic				s_axi_rvalid,
	input	logic				s_axi_rready,
	
// axi master port (to memory)
	// write address channel
	output	logic	[31:0]		m_axi_awaddr,
	output	logic	[2:0]		m_axi_awprot,
	output	logic				m_axi_awvalid,
	input	logic				m_axi_awready,
	// write data channel
	output	logic	[31:0]		m_axi_wdata,
	output	logic	[3:0]		m_axi_wstrb,
	output	logic				m_axi_wvalid,
	input	logic				m_axi_wready,
	// write response channel
	input	logic	[1:0]		m_axi_bresp,
	input	logic				m_axi_bvalid,
	output	logic				m_axi_bready,
	// read address channel
	output	logic	[31:0]		m_axi_araddr,
	output	logic	[2:0]		m_axi_arprot,
	output	logic				m_axi_arvalid,
	input	logic				m_axi_arready,
	// read data channel
	input	logic	[31:0]		m_axi_rdata,
	input	logic	[1:0]		m_axi_rresp,
	input	logic				m_axi_rvalid,
	output	logic				m_axi_rready,

// native master port (to peripherals)
	output	logic	[N-1:0]		ena,
	output	logic	[N*4-1:0]	wen,
	output	logic	[N*32-1:0]	addr,
	output	logic	[N*32-1:0]	wdata,
	input	logic	[N*32-1:0]	rdata
);

	logic	[31:0]	raddr_buf;
	logic	[31:0]	rdata_buf;
	logic	[N-1:0]	rvalid;
	logic	[N-1:0]	rvalid_set;
	logic			bypass_rdata;
	
	generate
		for (genvar i = 0; i < N; i = i+1)
			assign	wdata	[i*32+:32]	= s_axi_wdata;
	endgenerate

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
		
		rvalid_set		= {N{1'b0}};
		ena				= {N{1'b0}};
		wen				= {N{4'h0}};
		addr			= {N{32'h00000000}};
		
		for (integer i = 0; i < N; i = i+1) begin
			// write access (store)
			if (s_axi_awvalid && s_axi_wvalid) begin
				if ((s_axi_awaddr >= BASE[i*32+:32]) &&
					(s_axi_awaddr <  BASE[i*32+:32] + LEN[i*32+:32])) begin
					m_axi_awvalid	= 1'b0;
					s_axi_awready	= 1'b1;
					m_axi_wvalid	= 1'b0;
					s_axi_wready	= 1'b1;
					s_axi_bresp		= 2'b00;
					s_axi_bvalid	= 1'b1;
					m_axi_bready	= 1'b0;
					ena[i]			= 1'b1;
					wen[i*4+:4]		= s_axi_wstrb;
					addr[i*32+:32]	= s_axi_awaddr;
				end
			end
			// read access (load)
			else if (s_axi_arvalid) begin
				if ((s_axi_araddr >= BASE[i*32+:32]) &&
					(s_axi_araddr <  BASE[i*32+:32] + LEN[i*32+:32])) begin
					m_axi_arvalid	= 1'b0;
					s_axi_arready	= 1'b1;
					rvalid_set[i]	= 1'b1;
					ena[i]			= 1'b1;
					wen[i*4+:4]		= 4'h0;
					addr[i*32+:32]	= s_axi_araddr;
				end
			end
		end
	end
	
	always_comb begin
		// read data channel
		s_axi_rdata		= m_axi_rdata;
		s_axi_rresp		= m_axi_rresp;
		s_axi_rvalid	= m_axi_rvalid;
		m_axi_rready	= s_axi_rready;
		
		for (integer i = 0; i < N; i = i+1) begin
			if (rvalid[i]) begin
				s_axi_rdata		= bypass_rdata ? rdata[i*32+:32] : rdata_buf;
				s_axi_rresp		= 2'b00;
				s_axi_rvalid	= 1'b1;
				m_axi_rready	= 1'b0;
			end
		end
	end
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			rdata_buf		<= 32'h00000000;
			bypass_rdata	<= 1'b1;
			rvalid			<= 1'b0;
		end
		
		else if (s_axi_arvalid) begin
			bypass_rdata	<= 1'b1;
			rvalid			<= rvalid_set;
		end
		
		else for (integer i = 0; i < N; i = i+1) begin
			if (rvalid[i]) begin
				if (s_axi_rready) begin
					rvalid[i]		<= 1'b0;
					bypass_rdata	<= 1'b1;
				end
					
				else if (bypass_rdata) begin
					rdata_buf		<= rdata[i*32+:32];
					bypass_rdata	<= 1'b0;
				end
			end
		end
	end

endmodule