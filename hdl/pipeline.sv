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
	logic			trap_taken_IF;
	logic	[31:0]	trap_cause_IF;
	logic			jump_pred_IF;
	logic	[31:0]	jump_addr_IF;

	// ID signals / ID/EX pipeline registers
	logic			valid_out_ID;
	logic			ready_in_ID;
	logic			valid_out_mul_ID;
	logic			ready_in_mul_ID;
	logic			valid_out_div_ID;
	logic			ready_in_div_ID;
	logic			valid_out_fpu_ID;
	logic			ready_in_fpu_ID;
	logic	[31:0]	PC_ID;
	logic	[31:0]	IR_ID;
	logic	[31:0]	IM_ID;
	logic			rs1_rena_ID;
	logic	[5:0]	rs1_addr_ID;
	logic	[31:0]	rs1_data_ID;
	logic			rs2_rena_ID;
	logic	[5:0]	rs2_addr_ID;
	logic	[31:0]	rs2_data_ID;
	logic			rs3_rena_ID;
	logic	[5:0]	rs3_addr_ID;
	logic	[31:0]	rs3_data_ID;
	logic			rd_wena_ID;
	logic	[5:0]	rd_addr_ID;
	logic	[11:0]	csr_addr_ID;
	logic			csr_rena_ID;
	logic			csr_wena_ID;
	logic			sel_PC_ID;
	logic			sel_IM_ID;
	logic	[2:0]	wb_src_ID;
	logic	[3:0]	alu_op_ID;
	logic	[2:0]	mem_op_ID;
	logic	[1:0]	csr_op_ID;
	logic	[1:0]	mul_op_ID;
	logic	[1:0]	div_op_ID;
	logic	[4:0]	fpu_op_ID;
	logic	[2:0]	fpu_rm_ID;
	logic			jump_ena_ID;
	logic			jump_ind_ID;
	logic			jump_alw_ID;
	logic			jump_pred_ID;
	logic			trap_taken_ID;
	logic	[31:0]	trap_cause_ID;

	// EX signals / EX/mem pipeline registers
	logic			valid_out_EX;
	logic			ready_in_EX;
	logic	[31:0]	PC_EX;
	logic	[31:0]	IR_EX;
	logic	[31:0]	IM_EX;
	logic			rd_wena_EX;
	logic	[5:0]	rd_addr_EX;
	logic	[31:0]	rd_data_EX;
	logic	[11:0]	csr_addr_EX;
	logic			csr_rena_EX;
	logic			csr_wena_EX;
	logic	[31:0]	csr_wdata_EX;
	logic	[2:0]	wb_src_EX;
	logic	[2:0]	mem_op_EX;
	logic	[1:0]	csr_op_EX;
	logic	[4:0]	fpu_flags_EX;
	logic			jump_ena_EX;
	logic			jump_alw_EX;
	logic			jump_taken_EX;
	logic			jump_mpred_EX;
	logic	[31:0]	jump_addr_EX;
	logic			trap_taken_EX;
	logic	[31:0]	trap_cause_EX;
	
	// MEM signals / MEM/WB pipeline registers
	logic	[31:0]	PC_MEM;
	logic	[31:0]	IR_MEM;
	logic	[31:0]	IM_MEM;
	logic			rd_wena_MEM;
	logic	[5:0]	rd_addr_MEM;
	logic	[31:0]	rd_data_MEM;
	logic	[11:0]	csr_addr_MEM;
	logic			csr_rena_MEM;
	logic			csr_wena_MEM;
	logic	[31:0]	csr_wdata_MEM;
	logic	[1:0]	csr_op_MEM;
	logic	[4:0]	fpu_flags_MEM;
	logic			trap_taken_MEM;
	logic	[31:0]	trap_cause_MEM;
	
	// imem is read only
	assign			imem_axi_awaddr		= 32'h00000000;
	assign			imem_axi_awprot		= 3'b110;
	assign			imem_axi_awvalid	= 1'b0;

	assign			imem_axi_wdata		= 32'h00000000;
	assign			imem_axi_wstrb		= 4'b0000;
	assign			imem_axi_wvalid		= 1'b0;

	assign			imem_axi_bready		= 1'b0;

	IF_stage IF_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(jump_mpred_EX),

		.valid_out(valid_out_IF),
		.ready_in(ready_in_IF),
		
		.imem_axi_araddr(imem_axi_araddr),
		.imem_axi_arprot(imem_axi_arprot),
		.imem_axi_arvalid(imem_axi_arvalid),
		.imem_axi_arready(imem_axi_arready),
		.imem_axi_rdata(imem_axi_rdata),
		.imem_axi_rresp(imem_axi_rresp),
		.imem_axi_rvalid(imem_axi_rvalid),
		.imem_axi_rready(imem_axi_rready),
		
		.jump_taken(jump_mpred_EX || jump_pred_IF),
		.jump_addr(jump_mpred_EX ? jump_addr_EX : jump_addr_IF),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.imem_axi_rresp_IF(imem_axi_rresp_IF)
	);
	
	ID_stage ID_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(jump_mpred_EX),

		.valid_in(valid_out_IF),
		.ready_out(ready_in_IF),
		.valid_out(valid_out_ID),
		.ready_in(ready_in_ID),
		
		.valid_out_mul(valid_out_mul_ID),
		.ready_in_mul(ready_in_mul_ID),
		.valid_out_div(valid_out_div_ID),
		.ready_in_div(ready_in_div_ID),
		.valid_out_fpu(valid_out_fpu_ID),
		.ready_in_fpu(ready_in_fpu_ID),
		
		.M_ena(),
		.F_ena(),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.trap_taken_IF(trap_taken_IF),
		.trap_cause_IF(trap_cause_IF),
		
		.jump_pred_IF(jump_pred_IF),
		.jump_addr_IF(jump_addr_IF),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_rena_ID(rs1_rena_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs2_rena_ID(rs2_rena_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs3_rena_ID(rs3_rena_ID),
		.rs3_addr_ID(rs3_addr_ID),
		.rs3_data_ID(rs3_data_ID),
		.rd_wena_ID(rd_wena_ID),
		.rd_addr_ID(rd_addr_ID),
		.csr_addr_ID(csr_addr_ID),
		.csr_rena_ID(csr_rena_ID),
		.csr_wena_ID(csr_wena_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.wb_src_ID(wb_src_ID),
		.alu_op_ID(alu_op_ID),
		.mem_op_ID(mem_op_ID),
		.csr_op_ID(csr_op_ID),
		.mul_op_ID(mul_op_ID),
		.div_op_ID(div_op_ID),
		.fpu_op_ID(fpu_op_ID),
		.fpu_rm_ID(fpu_rm_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.jump_alw_ID(jump_alw_ID),
		.jump_pred_ID(jump_pred_ID),
		.trap_taken_ID(trap_taken_ID),
		.trap_cause_ID(trap_cause_ID),
		
		.PC_EX(PC_EX),
		.jump_ena_EX(jump_ena_EX),
		.jump_alw_EX(jump_alw_EX),
		.jump_taken_EX(jump_taken_EX),
		
		.rd_wena_MEM(rd_wena_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM)
	);
	
	EX_stage EX_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(),

		.valid_in(valid_out_ID),
		.ready_out(ready_in_ID),
		.valid_out(valid_out_EX),
		.ready_in(ready_in_EX),
		
		.valid_in_mul(valid_out_mul_ID),
		.ready_out_mul(ready_in_mul_ID),
		.valid_in_div(valid_out_div_ID),
		.ready_out_div(ready_in_div_ID),
		.valid_in_fpu(valid_out_fpu_ID),
		.ready_out_fpu(ready_in_fpu_ID),
		
		.frm(),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_rena_ID(rs1_rena_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs2_rena_ID(rs2_rena_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs3_rena_ID(rs3_rena_ID),
		.rs3_addr_ID(rs3_addr_ID),
		.rs3_data_ID(rs3_data_ID),
		.rd_wena_ID(rd_wena_ID),
		.rd_addr_ID(rd_addr_ID),
		.csr_addr_ID(csr_addr_ID),
		.csr_rena_ID(csr_rena_ID),
		.csr_wena_ID(csr_wena_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.wb_src_ID(wb_src_ID),
		.alu_op_ID(alu_op_ID),
		.mem_op_ID(mem_op_ID),
		.csr_op_ID(csr_op_ID),
		.mul_op_ID(mul_op_ID),
		.div_op_ID(div_op_ID),
		.fpu_op_ID(fpu_op_ID),
		.fpu_rm_ID(fpu_rm_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.jump_alw_ID(jump_alw_ID),
		.jump_pred_ID(jump_pred_ID),
		.trap_taken_ID(trap_taken_ID),
		.trap_cause_ID(trap_cause_ID),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_wena_EX(rd_wena_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.csr_addr_EX(csr_addr_EX),
		.csr_rena_EX(csr_rena_EX),
		.csr_wena_EX(csr_wena_EX),
		.csr_wdata_EX(csr_wdata_EX),
		.wb_src_EX(wb_src_EX),
		.mem_op_EX(mem_op_EX),
		.csr_op_EX(csr_op_EX),
		.fpu_flags_EX(fpu_flags_EX),
		.jump_ena_EX(jump_ena_EX),
		.jump_alw_EX(jump_alw_EX),
		.jump_taken_EX(jump_taken_EX),
		.jump_mpred_EX(jump_mpred_EX),
		.jump_addr_EX(jump_addr_EX),
		.trap_taken_EX(trap_taken_EX),
		.trap_cause_EX(trap_cause_EX),
		
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

		.rd_wena_MEM(rd_wena_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM)
	);
	
	MEM_stage MEM_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(1'b0),
		
		.valid_in(valid_out_EX),
		.ready_out(ready_in_EX),
		.valid_out(),
		.ready_in(1'b1),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_wena_EX(rd_wena_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.csr_addr_EX(csr_addr_EX),
		.csr_rena_EX(csr_rena_EX),
		.csr_wena_EX(csr_wena_EX),
		.csr_wdata_EX(csr_wdata_EX),
		.wb_src_EX(wb_src_EX),
		.mem_op_EX(mem_op_EX),
		.csr_op_EX(csr_op_EX),
		.fpu_flags_EX(fpu_flags_EX),
		.trap_taken_EX(trap_taken_EX),
		.trap_cause_EX(trap_cause_EX),
		
		.dmem_axi_bresp(dmem_axi_bresp),
		.dmem_axi_bvalid(dmem_axi_bvalid),
		.dmem_axi_bready(dmem_axi_bready),
		.dmem_axi_araddr(dmem_axi_araddr),
		.dmem_axi_rdata(dmem_axi_rdata),
		.dmem_axi_rresp(dmem_axi_rresp),
		.dmem_axi_rvalid(dmem_axi_rvalid),
		.dmem_axi_rready(dmem_axi_rready),

		.PC_MEM(PC_MEM),
		.IR_MEM(IR_MEM),
		.IM_MEM(IM_MEM),
		.rd_wena_MEM(rd_wena_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.csr_addr_MEM(csr_addr_MEM),
		.csr_rena_MEM(csr_rena_MEM),
		.csr_wena_MEM(csr_wena_MEM),
		.csr_wdata_MEM(csr_wdata_MEM),
		.csr_op_MEM(csr_op_MEM),
		.fpu_flags_MEM(fpu_flags_MEM),
		.trap_taken_MEM(trap_taken_MEM),
		.trap_cause_MEM(trap_cause_MEM)
	);
	


endmodule