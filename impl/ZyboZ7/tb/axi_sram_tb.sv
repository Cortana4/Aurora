
module axi_sram_tb();

	logic			clk;
	logic			reset;
	
	logic	[31:0]	rdata_;
	
	logic	[14:0]	s_axi_awaddr;
	logic	[2:0]	s_axi_awprot;
	logic			s_axi_awvalid;
	logic			s_axi_awready;
	
	logic	[31:0]	s_axi_wdata;
	logic	[3:0]	s_axi_wstrb;
	logic			s_axi_wvalid;
	logic			s_axi_wready;
	
	logic	[1:0]	s_axi_bresp;
	logic			s_axi_bvalid;
	logic			s_axi_bready;
	
	logic	[14:0]	s_axi_araddr;
	logic	[2:0]	s_axi_arprot;
	logic			s_axi_arvalid;
	logic			s_axi_arready;
	
	logic	[31:0]	s_axi_rdata;
	logic	[1:0]	s_axi_rresp;
	logic			s_axi_rvalid;
	logic			s_axi_rready;
	
	logic			bram_rst_a;
	logic			bram_clk_a;
	logic			bram_en_a;
	logic	[3:0]	bram_we_a;
	logic	[14:0]	bram_addr_a;
	logic	[31:0]	bram_wrdata_a;
	logic	[31:0]	bram_rddata_a;
	
	task axi_write;
		input	[14:0]	waddr;
		input	[31:0]	wdata;
	
		begin
			@(posedge clk)
			s_axi_awaddr	<= waddr;
			s_axi_awprot	<= 3'b010;
			s_axi_awvalid	<= 1'b1;
			
			s_axi_wdata		<= wdata;
			s_axi_wstrb		<= 4'b1111;
			s_axi_wvalid	<= 1'b1;
			
			wait (s_axi_awready && s_axi_wready);
			@(posedge clk)
			s_axi_awvalid	<= 1'b0;
			s_axi_wvalid	<= 1'b0;
		end
	endtask
	
	task axi_read;
		input	[14:0]	raddr;
		
		begin
			@(posedge clk)
			s_axi_araddr	<= raddr;
			s_axi_arprot	<= 3'b010;
			s_axi_arvalid	<= 1'b1;
			s_axi_rready	<= 1'b1;
			
			wait (s_axi_arready)
			wait (s_axi_rvalid)
			@(posedge clk)
			s_axi_arvalid	<= 1'b0;
			s_axi_rready	<= 1'b0;
		end
	endtask
	
	task axi_read_burst;
		input	[14:0]	raddr;
		
		begin
			@(posedge clk)
			s_axi_araddr	<= raddr;
			s_axi_arprot	<= 3'b010;
			s_axi_arvalid	<= 1'b1;
			s_axi_rready	<= 1'b1;
			
			@(posedge clk)
			s_axi_araddr	<= raddr + 4;
			s_axi_arprot	<= 3'b010;
			s_axi_arvalid	<= 1'b1;
			s_axi_rready	<= 1'b1;
		end
	endtask
	
	
	initial begin
		clk				= 0;
		reset			= 1;
		
		s_axi_awaddr	= 0;
		s_axi_awprot	= 0;
		s_axi_awvalid	= 0;
		
		s_axi_wdata		= 0;
		s_axi_wstrb		= 0;
		s_axi_wvalid	= 0;
		
		s_axi_bready	= 1;
		
		s_axi_araddr	= 0;
		s_axi_arprot	= 0;
		s_axi_arvalid	= 0;
		
		s_axi_rready	= 0;
		
		@(negedge clk)
		reset			= 0;
		
		axi_write(15'd4, 32'h1);
		axi_write(15'd8, 32'h2);
		axi_write(15'd12, 32'h3);
		axi_read_burst(15'd4);
	end
	
	always #10 clk = !clk;


	AXI_BRAM_Controller AXI_BRAM_Controller_inst
	(
		.s_axi_aclk(clk),
		.s_axi_aresetn(!reset),
		
		.s_axi_awaddr(s_axi_awaddr),
		.s_axi_awprot(s_axi_awprot),
		.s_axi_awvalid(s_axi_awvalid),
		.s_axi_awready(s_axi_awready),
		
		.s_axi_wdata(s_axi_wdata),
		.s_axi_wstrb(s_axi_wstrb),
		.s_axi_wvalid(s_axi_wvalid),
		.s_axi_wready(s_axi_wready),
		
		.s_axi_bresp(s_axi_bresp),
		.s_axi_bvalid(s_axi_bvalid),
		.s_axi_bready(s_axi_bready),
		
		.s_axi_araddr(s_axi_araddr),
		.s_axi_arprot(s_axi_arprot),
		.s_axi_arvalid(s_axi_arvalid),
		.s_axi_arready(s_axi_arready),
		
		.s_axi_rdata(s_axi_rdata),
		.s_axi_rresp(s_axi_rresp),
		.s_axi_rvalid(s_axi_rvalid),
		.s_axi_rready(s_axi_rready),
		
		.bram_rst_a(bram_rst_a),
		.bram_clk_a(bram_clk_a),
		.bram_en_a(bram_en_a),
		.bram_we_a(bram_we_a),
		.bram_addr_a(bram_addr_a),
		.bram_wrdata_a(bram_wrdata_a),
		.bram_rddata_a(bram_rddata_a)
	);

	RAM RAM_inst
	(
		.clka(bram_clk_a),
		.addra(bram_addr_a),
		.dina(bram_wrdata_a),
		.douta(bram_rddata_a),
		.ena(bram_en_a),
		.wea(bram_we_a),
		
		.clkb(clk),
		.addrb(15'd0),
		.dinb(32'h00000000),
		.doutb(),
		.enb(1'b0),
		.web(4'b0000)
	);


endmodule
