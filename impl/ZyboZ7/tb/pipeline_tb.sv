//`define USE_BRAM_IP

module pipeline_tb();

	parameter		USE_BRAM_IP = 0;

	logic			clk;
	logic			reset;
	
// imem port
	// write address channel
	logic	[31:0]	imem_axi_awaddr;
	logic	[2:0]	imem_axi_awprot;
	logic			imem_axi_awvalid;
	logic			imem_axi_awready;
	// write data channel
	logic	[31:0]	imem_axi_wdata;
	logic	[3:0]	imem_axi_wstrb;
	logic			imem_axi_wvalid;
	logic			imem_axi_wready;
	// write response channel
	logic	[1:0]	imem_axi_bresp;
	logic			imem_axi_bvalid;
	logic			imem_axi_bready;
	// read address channel
	logic	[31:0]	imem_axi_araddr;
	logic	[2:0]	imem_axi_arprot;
	logic			imem_axi_arvalid;
	logic			imem_axi_arready;
	// read data channel
	logic	[31:0]	imem_axi_rdata;
	logic	[1:0]	imem_axi_rresp;
	logic			imem_axi_rvalid;
	logic			imem_axi_rready;
	
	logic			bram_clk_a;
	logic			bram_en_a;
	logic	[3:0]	bram_we_a;
	logic	[15:0]	bram_addr_a;
	logic	[31:0]	bram_wrdata_a;
	logic	[31:0]	bram_rddata_a;

// dmem port
	// write address channel
	logic	[31:0]	dmem_axi_awaddr;
	logic	[2:0]	dmem_axi_awprot;
	logic			dmem_axi_awvalid;
	logic			dmem_axi_awready;
	// write data channel
	logic	[31:0]	dmem_axi_wdata;
	logic	[3:0]	dmem_axi_wstrb;
	logic			dmem_axi_wvalid;
	logic			dmem_axi_wready;
	// write response channel
	logic	[1:0]	dmem_axi_bresp;
	logic			dmem_axi_bvalid;
	logic			dmem_axi_bready;
	// read address channel
	logic	[31:0]	dmem_axi_araddr;
	logic	[2:0]	dmem_axi_arprot;
	logic			dmem_axi_arvalid;
	logic			dmem_axi_arready;
	// read data channel
	logic	[31:0]	dmem_axi_rdata;
	logic	[1:0]	dmem_axi_rresp;
	logic			dmem_axi_rvalid;
	logic			dmem_axi_rready;
	
	logic			bram_clk_b;
	logic			bram_en_b;
	logic	[3:0]	bram_we_b;
	logic	[15:0]	bram_addr_b;
	logic	[31:0]	bram_wrdata_b;
	logic	[31:0]	bram_rddata_b;

	initial begin
		clk		= 1'b0;
		reset	= 1'b1;
		
		@(negedge clk)
		reset	= 1'b0;
		
	end
	
	always #10 clk = !clk;

	BRAM_Controller_IP imem_controller
	(
		.s_axi_aclk(clk),
		.s_axi_aresetn(!reset),
		
		.s_axi_awaddr(imem_axi_awaddr[15:0]),
		.s_axi_awprot(imem_axi_awprot),
		.s_axi_awvalid(imem_axi_awvalid),
		.s_axi_awready(imem_axi_awready),
		.s_axi_wdata(imem_axi_wdata),
		.s_axi_wstrb(imem_axi_wstrb),
		.s_axi_wvalid(imem_axi_wvalid),
		.s_axi_wready(imem_axi_wready),
		.s_axi_bresp(imem_axi_bresp),
		.s_axi_bvalid(imem_axi_bvalid),
		.s_axi_bready(imem_axi_bready),
		.s_axi_araddr(imem_axi_araddr[15:0]),
		.s_axi_arprot(imem_axi_arprot),
		.s_axi_arvalid(imem_axi_arvalid),
		.s_axi_arready(imem_axi_arready),
		.s_axi_rdata(imem_axi_rdata),
		.s_axi_rresp(imem_axi_rresp),
		.s_axi_rvalid(imem_axi_rvalid),
		.s_axi_rready(imem_axi_rready),
		
		.bram_rst_a(),
		.bram_clk_a(bram_clk_a),
		.bram_en_a(bram_en_a),
		.bram_we_a(bram_we_a),
		.bram_addr_a(bram_addr_a),
		.bram_wrdata_a(bram_wrdata_a),
		.bram_rddata_a(bram_rddata_a)
	);
	
	BRAM_Controller_IP dmem_controller
	(
		.s_axi_aclk(clk),
		.s_axi_aresetn(!reset),
		
		.s_axi_awaddr(dmem_axi_awaddr[15:0]),
		.s_axi_awprot(dmem_axi_awprot),
		.s_axi_awvalid(dmem_axi_awvalid),
		.s_axi_awready(dmem_axi_awready),
		.s_axi_wdata(dmem_axi_wdata),
		.s_axi_wstrb(dmem_axi_wstrb),
		.s_axi_wvalid(dmem_axi_wvalid),
		.s_axi_wready(dmem_axi_wready),
		.s_axi_bresp(dmem_axi_bresp),
		.s_axi_bvalid(dmem_axi_bvalid),
		.s_axi_bready(dmem_axi_bready),
		.s_axi_araddr(dmem_axi_araddr[15:0]),
		.s_axi_arprot(dmem_axi_arprot),
		.s_axi_arvalid(dmem_axi_arvalid),
		.s_axi_arready(dmem_axi_arready),
		.s_axi_rdata(dmem_axi_rdata),
		.s_axi_rresp(dmem_axi_rresp),
		.s_axi_rvalid(dmem_axi_rvalid),
		.s_axi_rready(dmem_axi_rready),
		
		.bram_rst_a(),
		.bram_clk_a(bram_clk_b),
		.bram_en_a(bram_en_b),
		.bram_we_a(bram_we_b),
		.bram_addr_a(bram_addr_b),
		.bram_wrdata_a(bram_wrdata_b),
		.bram_rddata_a(bram_rddata_b)
	);

	generate
		if (USE_BRAM_IP) begin
			RAM_IP RAM_IP_inst
			(
				.clka(bram_clk_a),
				.addra(bram_addr_a[15:2]),
				.dina(bram_wrdata_a),
				.douta(bram_rddata_a),
				.ena(bram_en_a),
				.wea(bram_we_a),
				
				.clkb(bram_clk_b),
				.addrb(bram_addr_b[15:2]),
				.dinb(bram_wrdata_b),
				.doutb(bram_rddata_b),
				.enb(bram_en_b),
				.web(bram_we_b)
			);
		end
		
		else begin
			RAM
			#(
				.RAM_DEPTH(2**14),
				.COL_WIDTH(8),
				.COL_NUM(4)
			) RAM_inst
			(
				.clk(clk),

				.addra(bram_addr_a[15:2]),
				.dina(bram_wrdata_a),
				.douta(bram_rddata_a),
				.ena(bram_en_a),
				.wea(bram_we_a),

				.addrb(bram_addr_b[15:2]),
				.dinb(bram_wrdata_b),
				.doutb(bram_rddata_b),
				.enb(bram_en_b),
				.web(bram_we_b)
			);
			
			initial $readmemh("sb.mem", RAM_inst.ram);
		end
	endgenerate
	
	pipeline aurora
	(
		.clk(clk),
		.reset(reset),
		
		.int_req_ext(16'h0000),
		.int_req_ictrl(1'b0),
		.int_req_timer(1'b0),
		.int_req_soft(1'b0),
		
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

		.dmem_axi_awaddr(dmem_axi_awaddr),
		.dmem_axi_awprot(dmem_axi_awprot),
		.dmem_axi_awvalid(dmem_axi_awvalid),
		.dmem_axi_awready(dmem_axi_awready),
		.dmem_axi_wdata(dmem_axi_wdata),
		.dmem_axi_wstrb(dmem_axi_wstrb),
		.dmem_axi_wvalid(dmem_axi_wvalid),
		.dmem_axi_wready(dmem_axi_wready),
		.dmem_axi_bresp(dmem_axi_bresp),
		.dmem_axi_bvalid(dmem_axi_bvalid),
		.dmem_axi_bready(dmem_axi_bready),
		.dmem_axi_araddr(dmem_axi_araddr),
		.dmem_axi_arprot(dmem_axi_arprot),
		.dmem_axi_arvalid(dmem_axi_arvalid),
		.dmem_axi_arready(dmem_axi_arready),
		.dmem_axi_rdata(dmem_axi_rdata),
		.dmem_axi_rresp(dmem_axi_rresp),
		.dmem_axi_rvalid(dmem_axi_rvalid),
		.dmem_axi_rready(dmem_axi_rready)
	);

endmodule