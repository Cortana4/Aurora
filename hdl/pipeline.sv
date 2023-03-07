module pipeline
(
	input	logic			clk,
	input	logic			reset,

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
	output	logic			dmem_axi_rready
);

	// IF signals / IF/ID pipeline registers
	logic			valid_out_IF;
	logic			ready_in_IF;
	logic	[31:0]	PC_IF;
	logic	[31:0]	IR_IF;
	logic	[1:0]	imem_axi_rresp_IF;

	// ID signals / ID/EX pipeline registers
	logic			valid_out_ID;
	logic			ready_in_ID;
	logic			valid_out_MUL_ID;
	logic			ready_in_MUL_ID;
	logic			valid_out_DIV_ID;
	logic			ready_in_DIV_ID;
	logic			valid_out_FPU_ID;
	logic			ready_in_FPU_ID;
	logic	[31:0]	PC_ID;
	logic	[31:0]	IR_ID;
	logic	[31:0]	IM_ID;
	logic	[5:0]	rs1_addr_ID;
	logic	[31:0]	rs1_data_ID;
	logic			rs1_access_ID;
	logic	[5:0]	rs2_addr_ID;
	logic	[31:0]	rs2_data_ID;
	logic			rs2_access_ID;
	logic	[5:0]	rs3_addr_ID;
	logic	[31:0]	rs3_data_ID;
	logic			rs3_access_ID;
	logic	[5:0]	rd_addr_ID;
	logic			rd_access_ID;
	logic			sel_PC_ID;
	logic			sel_IM_ID;
	logic	[2:0]	wb_src_ID;
	logic	[3:0]	ALU_op_ID;
	logic	[2:0]	MEM_op_ID;
	logic	[1:0]	MUL_op_ID;
	logic	[1:0]	DIV_op_ID;
	logic	[4:0]	FPU_op_ID;
	logic	[2:0]	FPU_rm_ID;
	logic			jump_ena_ID;
	logic			jump_ind_ID;
	logic			jump_alw_ID;
	logic			illegal_inst_ID;
	logic	[1:0]	imem_axi_rresp_ID;

	// EX signals / EX/MEM pipeline registers
	logic			valid_out_EX;
	logic			ready_in_EX;
	logic			jump_taken;
	logic	[31:0]	jump_addr;
	logic	[31:0]	PC_EX;
	logic	[31:0]	IR_EX;
	logic	[31:0]	IM_EX;
	logic	[5:0]	rd_addr_EX;
	logic	[31:0]	rd_data_EX;
	logic			rd_access_EX;
	logic	[2:0]	wb_src_EX;
	logic	[2:0]	MEM_op_EX;
	logic			illegal_inst_EX;
	logic			maligned_data_addr_EX;
	logic			maligned_inst_addr_EX;
	logic	[1:0]	imem_axi_rresp_EX;
	
	// MEM signals / MEM/WB pipeline registers
	logic	[31:0]	PC_MEM;
	logic	[31:0]	IR_MEM;
	logic	[31:0]	IM_MEM;
	logic	[5:0]	rd_addr_MEM;
	logic	[31:0]	rd_data_MEM;
	logic			rd_access_MEM;
	logic			illegal_inst_MEM;
	logic			maligned_data_addr_MEM;
	logic			maligned_inst_addr_MEM;
	logic	[1:0]	imem_axi_rresp_MEM;
	logic	[1:0]	dmem_axi_bresp_MEM;
	logic	[1:0]	dmem_axi_rresp_MEM;

	IF_stage IF_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_out(valid_out_IF),
		.ready_in(ready_in_IF),

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

		.jump_taken(jump_taken),
		.jump_addr(jump_addr),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.imem_axi_rresp_IF(imem_axi_rresp_IF)
	);
	
	ID_stage ID_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_IF),
		.ready_out(ready_in_IF),
		.valid_out(valid_out_ID),
		.ready_in(ready_in_ID),
		
		.valid_out_MUL(valid_out_MUL_ID),
		.ready_in_MUL(ready_in_MUL_ID),
		.valid_out_DIV(valid_out_DIV_ID),
		.ready_in_DIV(ready_in_DIV_ID),
		.valid_out_FPU(valid_out_FPU_ID),
		.ready_in_FPU(ready_in_FPU_ID),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.imem_axi_rresp_IF(imem_axi_rresp_IF),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs1_access_ID(rs1_access_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs2_access_ID(rs2_access_ID),
		.rs3_addr_ID(rs3_addr_ID),
		.rs3_data_ID(rs3_data_ID),
		.rs3_access_ID(rs3_access_ID),
		.rd_addr_ID(rd_addr_ID),
		.rd_access_ID(rd_access_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.wb_src_ID(wb_src_ID),
		.ALU_op_ID(ALU_op_ID),
		.MEM_op_ID(MEM_op_ID),
		.MUL_op_ID(MUL_op_ID),
		.DIV_op_ID(DIV_op_ID),
		.FPU_op_ID(FPU_op_ID),
		.FPU_rm_ID(FPU_rm_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.jump_alw_ID(jump_alw_ID),
		.illegal_inst_ID(illegal_inst_ID),
		.imem_axi_rresp_ID(imem_axi_rresp_ID),

		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM)
	);
	
	EX_stage EX_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_ID),
		.ready_out(ready_in_ID),
		.valid_out(valid_out_EX),
		.ready_in(ready_in_EX),
		
		.valid_in_MUL(valid_out_MUL_ID),
		.ready_out_MUL(ready_in_MUL_ID),
		.valid_in_DIV(valid_out_DIV_ID),
		.ready_out_DIV(ready_in_DIV_ID),
		.valid_in_FPU(valid_out_FPU_ID),
		.ready_out_FPU(ready_in_FPU_ID),
		
		.dmem_axi_awaddr(dmem_axi_awaddr),
		.dmem_axi_awprot(dmem_axi_awprot),
		.dmem_axi_awvalid(dmem_axi_awvalid),
		.dmem_axi_awready(dmem_axi_awready),

		.dmem_axi_wdata(dmem_axi_wdata),
		.dmem_axi_wstrb(dmem_axi_wstrb),
		.dmem_axi_wvalid(dmem_axi_wvalid),
		.dmem_axi_wready(dmem_axi_wready),
		
		.dmem_axi_araddr(dmem_axi_araddr),
		.dmem_axi_arprot(dmem_axi_arprot),
		.dmem_axi_arvalid(dmem_axi_arvalid),
		.dmem_axi_arready(dmem_axi_arready),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs1_access_ID(rs1_access_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs2_access_ID(rs2_access_ID),
		.rs3_addr_ID(rs3_addr_ID),
		.rs3_data_ID(rs3_data_ID),
		.rs3_access_ID(rs3_access_ID),
		.rd_addr_ID(rd_addr_ID),
		.rd_access_ID(rd_access_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.wb_src_ID(wb_src_ID),
		.ALU_op_ID(ALU_op_ID),
		.MEM_op_ID(MEM_op_ID),
		.MUL_op_ID(MUL_op_ID),
		.DIV_op_ID(DIV_op_ID),
		.FPU_op_ID(FPU_op_ID),
		.FPU_rm_ID(FPU_rm_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.jump_alw_ID(jump_alw_ID),
		.illegal_inst_ID(illegal_inst_ID),
		.imem_axi_rresp_ID(imem_axi_rresp_ID),

		.jump_taken(jump_taken),
		.jump_addr(jump_addr),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.rd_access_EX(rd_access_EX),
		.wb_src_EX(wb_src_EX),
		.MEM_op_EX(MEM_op_EX),
		.illegal_inst_EX(illegal_inst_EX),
		.maligned_data_addr_EX(maligned_data_addr_EX),
		.maligned_inst_addr_EX(maligned_inst_addr_EX),
		.imem_axi_rresp_EX(imem_axi_rresp_EX),

		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM)
	);
	
	MEM_stage MEM_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_EX),
		.ready_out(ready_in_EX),
		.valid_out(),
		.ready_in(1'b1),
		
		.dmem_axi_bresp(dmem_axi_bresp),
		.dmem_axi_bvalid(dmem_axi_bvalid),
		.dmem_axi_bready(dmem_axi_bready),
		
		.dmem_axi_araddr(dmem_axi_araddr),

		.dmem_axi_rdata(dmem_axi_rdata),
		.dmem_axi_rresp(dmem_axi_rresp),
		.dmem_axi_rvalid(dmem_axi_rvalid),
		.dmem_axi_rready(dmem_axi_rready),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.rd_access_EX(rd_access_EX),
		.wb_src_EX(wb_src_EX),
		.MEM_op_EX(MEM_op_EX),
		.illegal_inst_EX(illegal_inst_EX),
		.maligned_data_addr_EX(maligned_data_addr_EX),
		.maligned_inst_addr_EX(maligned_inst_addr_EX),
		.imem_axi_rresp_EX(imem_axi_rresp_EX),

		.PC_MEM(PC_MEM),
		.IR_MEM(IR_MEM),
		.IM_MEM(IM_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM),
		.illegal_inst_MEM(illegal_inst_MEM),
		.maligned_data_addr_MEM(maligned_data_addr_MEM),
		.maligned_inst_addr_MEM(maligned_inst_addr_MEM),
		.imem_axi_rresp_MEM(imem_axi_rresp_MEM),
		.dmem_axi_bresp_MEM(dmem_axi_bresp_MEM),
		.dmem_axi_rresp_MEM(dmem_axi_rresp_MEM)
	);

endmodule