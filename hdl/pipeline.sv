module pipeline
(
	input	logic			clk,
	input	logic			reset,
	
// interrupt request signals
	input	logic	[15:0]	irq_ext,
	input	logic			irq_int_controller,
	input	logic			irq_timer,
	input	logic			irq_software,

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
	logic			flush_in_IF;
	logic	[31:0]	PC_IF;
	logic	[31:0]	IR_IF;
	logic			exc_pend_IF;
	logic	[31:0]	exc_cause_IF;
	logic			jump_pred_IF;
	logic	[31:0]	jump_addr_IF;

	// ID signals / ID/EX pipeline registers
	logic			valid_out_ID;
	logic			ready_in_ID;
	logic			flush_in_ID;
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
	logic			trap_ret_ID;
	logic			exc_pend_ID;
	logic	[31:0]	exc_cause_ID;

	// EX signals / EX/mem pipeline registers
	logic			valid_out_EX;
	logic			ready_in_EX;
	logic			flush_in_EX;
	logic	[31:0]	PC_EX;
	logic	[31:0]	IR_EX;
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
	logic			trap_ret_EX;
	logic			exc_pend_EX;
	logic	[31:0]	exc_cause_EX;
	
	// MEM signals / MEM/WB pipeline registers
	logic			valid_out_MEM;
	logic			ready_in_MEM;
	logic			flush_in_MEM;
	logic	[31:0]	PC_MEM;
	logic	[31:0]	IR_MEM;
	logic			rd_wena_MEM;
	logic	[5:0]	rd_addr_MEM;
	logic	[31:0]	rd_data_MEM;
	logic	[11:0]	csr_addr_MEM;
	logic			csr_rena_MEM;
	logic			csr_wena_MEM;
	logic	[31:0]	csr_wdata_MEM;
	logic	[2:0]	wb_src_MEM;	
	logic	[1:0]	csr_op_MEM;
	logic	[4:0]	fpu_flags_MEM;
	logic			trap_ret_MEM;
	logic			exc_pend_MEM;
	logic	[31:0]	exc_cause_MEM;
	
	// WB signals
	logic	[31:0]	PC_WB;
	logic	[31:0]	IR_WB;
	logic			rd_wena_to_WB;
	logic	[5:0]	rd_addr_to_WB;
	logic	[31:0]	rd_data_to_WB;
	
	// csr signals
	logic			M_ena_csr;
	logic			F_ena_csr;
	logic	[2:0]	fpu_rm_csr;
	logic			int_taken_csr;
	logic			exc_taken_csr;
	logic			trap_taken_csr;
	logic	[31:0]	trap_addr_csr;
	logic	[31:0]	trap_raddr_csr;
	
	// control signals

	// imem is read only
	assign			imem_axi_awaddr		= 32'h00000000;
	assign			imem_axi_awprot		= 3'b110;
	assign			imem_axi_awvalid	= 1'b0;

	assign			imem_axi_wdata		= 32'h00000000;
	assign			imem_axi_wstrb		= 4'b0000;
	assign			imem_axi_wvalid		= 1'b0;

	assign			imem_axi_bready		= 1'b0;
	
	
	logic			flush_IF;
	logic			flush_ID;
	logic			flush_EX;
	
	assign			flush_IF			= flush_ID;
	assign			flush_ID			= flush_EX || jump_mpred_EX;
	assign			flush_EX			= trap_taken_csr;
	
	

	IF_stage IF_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_out(valid_out_IF),
		.ready_in(ready_in_IF),
		.flush_in(flush_in_IF),
		
		.imem_axi_araddr(imem_axi_araddr),
		.imem_axi_arprot(imem_axi_arprot),
		.imem_axi_arvalid(imem_axi_arvalid),
		.imem_axi_arready(imem_axi_arready),
		.imem_axi_rdata(imem_axi_rdata),
		.imem_axi_rresp(imem_axi_rresp),
		.imem_axi_rvalid(imem_axi_rvalid),
		.imem_axi_rready(imem_axi_rready),
		
		.trap_taken_csr(trap_taken_csr),
		.trap_addr_csr(trap_addr_csr),
		
		.PC_int(),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.exc_pend_IF(exc_pend_IF),
		.exc_cause_IF(exc_cause_IF),
		
		.jump_pred_IF(jump_pred_IF),
		.jump_addr_IF(jump_addr_IF),
		
		.jump_mpred_EX(jump_mpred_EX),
		.jump_addr_EX(jump_addr_EX)
	);
	
	ID_stage ID_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_IF),
		.ready_out(ready_in_IF),
		.flush_out(flush_in_IF),
		.valid_out(valid_out_ID),
		.ready_in(ready_in_ID),
		.flush_in(flush_in_ID),
		
		.valid_out_mul(valid_out_mul_ID),
		.ready_in_mul(ready_in_mul_ID),
		.valid_out_div(valid_out_div_ID),
		.ready_in_div(ready_in_div_ID),
		.valid_out_fpu(valid_out_fpu_ID),
		.ready_in_fpu(ready_in_fpu_ID),
		
		.M_ena_csr(M_ena_csr),
		.F_ena_csr(F_ena_csr),
		.trap_raddr_csr(trap_raddr_csr),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),
		.exc_pend_IF(exc_pend_IF),
		.exc_cause_IF(exc_cause_IF),
		
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
		.trap_ret_ID(trap_ret_ID),
		.exc_pend_ID(exc_pend_ID),
		.exc_cause_ID(exc_cause_ID),
		
		.PC_EX(PC_EX),
		.jump_ena_EX(jump_ena_EX),
		.jump_alw_EX(jump_alw_EX),
		.jump_taken_EX(jump_taken_EX),
		
		.rd_wena_to_WB(rd_wena_to_WB),
		.rd_addr_to_WB(rd_addr_to_WB),
		.rd_data_to_WB(rd_data_to_WB)
	);
	
	EX_stage EX_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_ID),
		.ready_out(ready_in_ID),
		.flush_out(flush_in_ID),
		.valid_out(valid_out_EX),
		.ready_in(ready_in_EX),
		.flush_in(flush_in_EX),
		
		.valid_in_mul(valid_out_mul_ID),
		.ready_out_mul(ready_in_mul_ID),
		.valid_in_div(valid_out_div_ID),
		.ready_out_div(ready_in_div_ID),
		.valid_in_fpu(valid_out_fpu_ID),
		.ready_out_fpu(ready_in_fpu_ID),
		
		.fpu_rm_csr(fpu_rm_csr),

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
		.trap_ret_ID(trap_ret_ID),
		.exc_pend_ID(exc_pend_ID),
		.exc_cause_ID(exc_cause_ID),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
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
		.trap_ret_EX(trap_ret_EX),
		.exc_pend_EX(exc_pend_EX),
		.exc_cause_EX(exc_cause_EX),
		
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
		
		.valid_in(valid_out_EX),
		.ready_out(ready_in_EX),
		.flush_out(flush_in_EX),
		.valid_out(valid_out_MEM),
		.ready_in(ready_in_MEM),
		.flush_in(flush_in_MEM),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
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
		.trap_ret_EX(trap_ret_EX),
		.exc_pend_EX(exc_pend_EX),
		.exc_cause_EX(exc_cause_EX),
		
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
		.rd_wena_MEM(rd_wena_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.csr_addr_MEM(csr_addr_MEM),
		.csr_rena_MEM(csr_rena_MEM),
		.csr_wena_MEM(csr_wena_MEM),
		.csr_wdata_MEM(csr_wdata_MEM),
		.wb_src_MEM(wb_src_MEM),
		.csr_op_MEM(csr_op_MEM),
		.fpu_flags_MEM(fpu_flags_MEM),
		.trap_ret_MEM(trap_ret_MEM),
		.exc_pend_MEM(exc_pend_MEM),
		.exc_cause_MEM(exc_cause_MEM)
	);
	
	WB_stage WB_stage_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_out_MEM),
		.ready_out(ready_in_MEM),
		.valid_out(),
		.ready_in(1'b1),

		.irq_ext(irq_ext),
		.irq_int_controller(irq_int_controller),
		.irq_timer(irq_timer),
		.irq_software(irq_software),

		.M_ena_csr(M_ena_csr),
		.F_ena_csr(F_ena_csr),
		.fpu_rm_csr(fpu_rm_csr),
		.int_taken_csr(int_taken_csr),
		.exc_taken_csr(exc_taken_csr),
		.trap_taken_csr(trap_taken_csr),
		.trap_addr_csr(trap_addr_csr),
		.trap_raddr_csr(trap_raddr_csr),

		.PC_MEM(PC_MEM),
		.IR_MEM(IR_MEM),
		.rd_wena_MEM(rd_wena_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.csr_addr_MEM(csr_addr_MEM),
		.csr_rena_MEM(csr_rena_MEM),
		.csr_wena_MEM(csr_wena_MEM),
		.csr_wdata_MEM(csr_wdata_MEM),
		.wb_src_MEM(wb_src_MEM),
		.csr_op_MEM(csr_op_MEM),
		.fpu_flags_MEM(fpu_flags_MEM),
		.trap_ret_MEM(trap_ret_MEM),
		.exc_pend_MEM(exc_pend_MEM),
		.exc_cause_MEM(exc_cause_MEM),

		.PC_WB(PC_WB),
		.IR_WB(IR_WB),
		.rd_wena_to_WB(rd_wena_to_WB),
		.rd_addr_to_WB(rd_addr_to_WB),
		.rd_data_to_WB(rd_data_to_WB)
	);
	


endmodule