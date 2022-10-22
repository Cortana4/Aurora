module AmberFive_pipeline
(
	input	logic			clk,
	input	logic			reset,
	
	output	logic	[31:0]	imem_addr,
	input	logic	[31:0]	imem_din,
	output	logic			imem_ena,
	
	output	logic	[31:0]	dmem_addr,
	output	logic	[31:0]	dmem_dout,
	input	logic	[31:0]	dmem_din,
	output	logic			dmem_ena,
	output	logic	[3:0]	dmem_wen
);

	// IF/ID pipeline registers
	logic	[31:0]	PC_IF;
	logic	[31:0]	IR_IF;
	
	// ID/EX pipeline registers
	logic	[31:0]	PC_ID;
	logic	[31:0]	IR_ID;
	logic	[31:0]	IM_ID;
	logic	[4:0]	rs1_addr_ID;
	logic	[31:0]	rs1_data_ID;
	logic			rs1_access_ID;
	logic	[4:0]	rs2_addr_ID;
	logic	[31:0]	rs2_data_ID;
	logic			rs2_access_ID;
	logic	[4:0]	rd_addr_ID;
	logic			rd_access_ID;
	logic			sel_PC_ID;
	logic			sel_IM_ID;
	logic			sel_MUL_ID;
	logic			sel_DIV_ID;
	logic	[2:0]	MEM_op_ID;
	logic	[3:0]	ALU_op_ID;
	logic	[1:0]	MUL_op_ID;
	logic	[1:0]	DIV_op_ID;
	logic			dmem_access_ID;
	logic			jump_ena_ID;
	logic			jump_ind_ID;
	logic			illegal_inst_ID;
	
	// EX/MEM pipeline registers
	logic	[31:0]	PC_EX;
	logic	[31:0]	IR_EX;
	logic	[31:0]	IM_EX;
	logic	[4:0]	rd_addr_EX;
	logic	[31:0]	rd_data_EX;
	logic			rd_access_EX;
	logic	[2:0]	MEM_op_EX;
	logic			dmem_access_EX;
	logic			illegal_inst_EX;
	logic			misaligned_addr_EX;
	
	// MEM/WB pipeline registers
	logic	[31:0]	PC_MEM;
	logic	[31:0]	IR_MEM;
	logic	[31:0]	IM_MEM;
	logic	[4:0]	rd_addr_MEM;
	logic	[31:0]	rd_data_MEM;
	logic			rd_access_MEM;
	
	// pipeline flow control signals
	logic			jump_taken;
	logic	[31:0]	jump_addr;
	
	logic			ready;
	
	logic			rd_after_ld_rs1;
	logic			rd_after_ld_rs2;
	
	logic			stall;
	logic			flush;
	logic			bubble;
	
	assign			rd_after_ld_rs1	= rs1_access_ID && |rs1_addr_ID && rd_access_EX && rs1_addr_ID == rd_addr_EX && dmem_access_EX;
	assign			rd_after_ld_rs2	= rs2_access_ID && |rs2_addr_ID && rd_access_EX && rs2_addr_ID == rd_addr_EX && dmem_access_EX;
	
	assign			stall			= bubble;
	assign			flush			= jump_taken;
	assign			bubble			= rd_after_ld_rs1 || rd_after_ld_rs2 || !ready;

	IF_stage IF_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.stall(stall),

		.imem_addr(imem_addr),
		.imem_din(imem_din),
		.imem_ena(imem_ena),

		.jump_taken(jump_taken),
		.jump_addr(jump_addr),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF)
	);
	
	ID_stage ID_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.stall(stall),
		.clear(flush),

		.PC_IF(PC_IF),
		.IR_IF(IR_IF),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs1_access_ID(rs1_access_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs2_access_ID(rs2_access_ID),
		.rd_addr_ID(rd_addr_ID),
		.rd_access_ID(rd_access_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.sel_MUL_ID(sel_MUL_ID),
		.sel_DIV_ID(sel_DIV_ID),
		.MEM_op_ID(MEM_op_ID),
		.ALU_op_ID(ALU_op_ID),
		.MUL_op_ID(MUL_op_ID),
		.DIV_op_ID(DIV_op_ID),
		.dmem_access_ID(dmem_access_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.illegal_inst_ID(illegal_inst_ID),

		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM)
	);
	
	EX_stage EX_stage_inst
	(
		.clk(clk),
		.reset(reset),
		.clear(bubble),

		.PC_ID(PC_ID),
		.IR_ID(IR_ID),
		.IM_ID(IM_ID),
		.rs1_addr_ID(rs1_addr_ID),
		.rs1_data_ID(rs1_data_ID),
		.rs1_access_ID(rs1_access_ID),
		.rs2_addr_ID(rs2_addr_ID),
		.rs2_data_ID(rs2_data_ID),
		.rs2_access_ID(rs2_access_ID),
		.rd_addr_ID(rd_addr_ID),
		.rd_access_ID(rd_access_ID),
		.sel_PC_ID(sel_PC_ID),
		.sel_IM_ID(sel_IM_ID),
		.sel_MUL_ID(sel_MUL_ID),
		.sel_DIV_ID(sel_DIV_ID),
		.MEM_op_ID(MEM_op_ID),
		.ALU_op_ID(ALU_op_ID),
		.MUL_op_ID(MUL_op_ID),
		.DIV_op_ID(DIV_op_ID),
		.dmem_access_ID(dmem_access_ID),
		.jump_ena_ID(jump_ena_ID),
		.jump_ind_ID(jump_ind_ID),
		.illegal_inst_ID(illegal_inst_ID),

		.jump_taken(jump_taken),
		.jump_addr(jump_addr),

		.dmem_addr(dmem_addr),
		.dmem_dout(dmem_dout),
		.dmem_ena(dmem_ena),
		.dmem_wen(dmem_wen),
		
		.ready(ready),

		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.rd_access_EX(rd_access_EX),
		.MEM_op_EX(MEM_op_EX),
		.dmem_access_EX(dmem_access_EX),
		.illegal_inst_EX(illegal_inst_EX),
		.misaligned_addr_EX(misaligned_addr_EX),

		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM)
	);
	
	MEM_stage MEM_stage_inst
	(
		.clk(clk),
		.reset(reset),
		
		.PC_EX(PC_EX),
		.IR_EX(IR_EX),
		.IM_EX(IM_EX),
		.rd_addr_EX(rd_addr_EX),
		.rd_data_EX(rd_data_EX),
		.rd_access_EX(rd_access_EX),
		.MEM_op_EX(MEM_op_EX),
		.dmem_access_EX(dmem_access_EX),
		.illegal_inst_EX(illegal_inst_EX),
		.misaligned_addr_EX(misaligned_addr_EX),

		.dmem_din(dmem_din),

		.PC_MEM(PC_MEM),
		.IR_MEM(IR_MEM),
		.IM_MEM(IM_MEM),
		.rd_addr_MEM(rd_addr_MEM),
		.rd_data_MEM(rd_data_MEM),
		.rd_access_MEM(rd_access_MEM)
	);

endmodule