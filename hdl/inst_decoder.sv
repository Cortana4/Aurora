import CPU_pkg::*;
import FPU_pkg::*;

module inst_decoder
(
	input	logic	[31:0]	IR_IF,
	
	input	logic			M_ena,
	input	logic			F_ena,

	output	logic	[31:0]	immediate,
	output	logic			rs1_rena,
	output	logic	[5:0]	rs1_addr,
	output	logic			rs2_rena,
	output	logic	[5:0]	rs2_addr,
	output	logic			rs3_rena,
	output	logic	[5:0]	rs3_addr,
	output	logic			rd_wena,
	output	logic	[5:0]	rd_addr,
	output	logic	[11:0]	csr_addr,
	output	logic			csr_rena,
	output	logic			csr_wena,
	output	logic			sel_PC,
	output	logic			sel_IM,
	output	logic	[2:0]	wb_src,
	output	logic	[3:0]	alu_op,
	output	logic	[2:0]	mem_op,
	output	logic	[1:0]	csr_op,
	output	logic	[1:0]	mul_op,
	output	logic	[1:0]	div_op,
	output	logic	[4:0]	fpu_op,
	output	logic	[2:0]	fpu_rm,
	output	logic			jump_ena,
	output	logic			jump_ind,
	output	logic			jump_alw,
	output	logic			env_call,
	output	logic			trap_ret,
	output	logic			illegal_inst
);

	logic	[31:0]	inst;
	logic	[31:0]	uimm;
	logic	[31:0]	immediate_I;
	logic	[31:0]	immediate_S;
	logic	[31:0]	immediate_B;
	logic	[31:0]	immediate_U;
	logic	[31:0]	immediate_J;

	assign			inst			= IR_IF;
	assign			rs1_addr[4:0]	= inst[19:15];
	assign			rs2_addr[4:0]	= inst[24:20];
	assign			rs3_addr[4:0]	= inst[31:27];
	assign			rd_addr[4:0]	= inst[11:7];
	assign			csr_addr		= inst[31:20];
	assign			fpu_rm			= inst[14:12];
	assign			uimm			= {27'h0000000, inst[19:15]};
	assign			immediate_I		= {{21{inst[31]}}, inst[30:20]};
	assign			immediate_S		= {{21{inst[31]}}, inst[30:25], inst[11:7]};
	assign			immediate_B		= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
	assign			immediate_U		= {inst[31:12], 12'b000000000000};
	assign			immediate_J		= {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

	always_comb begin
		immediate		= 32'h00000000;
		rs1_rena		= 1'b0;
		rs1_addr[5]		= 1'b0;
		rs2_rena		= 1'b0;
		rs2_addr[5]		= 1'b0;
		rs3_rena		= 1'b0;
		rs3_addr[5]		= 1'b0;
		rd_wena			= 1'b0;
		rd_addr[5]		= 1'b0;
		csr_rena		= 1'b0;
		csr_wena		= 1'b0;
		sel_PC			= 1'b0;
		sel_IM			= 1'b0;
		wb_src			= 3'd0;
		alu_op			= 4'd0;
		mem_op			= 3'd0;
		csr_op			= 2'd0;
		mul_op			= 2'd0;
		div_op			= 2'd0;
		fpu_op			= 5'd0;
		jump_ena		= 1'b0;
		jump_ind		= 1'b0;
		jump_alw		= 1'b0;
		env_call		= 1'b0;
		trap_ret		= 1'b0;
		illegal_inst	= 1'b1;
	
		casez (inst)
		// RV32I instructions
		RV32I_LUI:			begin
								immediate		= immediate_U;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		RV32I_AUIPC:		begin
								immediate		= immediate_U;
								rd_wena			= 1'b1;
								sel_PC			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		RV32I_JAL:			begin
								immediate		= immediate_J;
								rd_wena			= 1'b1;
								sel_PC			= 1'b1;
								alu_op			= ALU_INC;
								jump_ena		= 1'b1;
								jump_alw		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_JALR:		begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_PC			= 1'b1;
								alu_op			= ALU_INC;
								jump_ena		= 1'b1;
								jump_ind		= 1'b1;
								jump_alw		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BEQ:			begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SEQ;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BNE:			begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SNE;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BLT:			begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SLT;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BGE:			begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SGE;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BLTU:		begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SLTU;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_BGEU:		begin
								immediate		= immediate_B;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								alu_op			= ALU_SGEU;
								jump_ena		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_LB:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LB;
								illegal_inst	= 1'b0;
							end
		RV32I_LH:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LH;
								illegal_inst	= 1'b0;
							end
		RV32I_LW:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LW;
								illegal_inst	= 1'b0;
							end
		RV32I_LBU:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LBU;
								illegal_inst	= 1'b0;
							end
		RV32I_LHU:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LHU;
								illegal_inst	= 1'b0;
							end
		RV32I_SB:			begin
								immediate		= immediate_S;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_SB;
								illegal_inst	= 1'b0;
							end
		RV32I_SH:			begin
								immediate		= immediate_S;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_SH;
								illegal_inst	= 1'b0;
							end
		RV32I_SW:			begin
								immediate		= immediate_S;
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_SW;
								illegal_inst	= 1'b0;
							end
		RV32I_ADDI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		RV32I_SLTI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_SLT;
								illegal_inst	= 1'b0;
							end
		RV32I_SLTIU:		begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_SLTU;
								illegal_inst	= 1'b0;
							end
		RV32I_XORI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_XOR;
								illegal_inst	= 1'b0;
							end
		RV32I_ORI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_OR;
								illegal_inst	= 1'b0;
							end
		RV32I_ANDI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_AND;
								illegal_inst	= 1'b0;
							end
		RV32I_SLLI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_SLL;
								illegal_inst	= 1'b0;
							end
		RV32I_SRLI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_SRL;
								illegal_inst	= 1'b0;
							end
		RV32I_SRAI:			begin
								immediate		= immediate_I;
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								alu_op			= ALU_SRA;
								illegal_inst	= 1'b0;
							end
		RV32I_ADD:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		RV32I_SUB:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SUB;
								illegal_inst	= 1'b0;
							end
		RV32I_SLL:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SLL;
								illegal_inst	= 1'b0;
							end
		RV32I_SLT:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SLT;
								illegal_inst	= 1'b0;
							end
		RV32I_SLTU:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SLTU;
								illegal_inst	= 1'b0;
							end
		RV32I_XOR:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_XOR;
								illegal_inst	= 1'b0;
							end
		RV32I_SRL:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SRL;
								illegal_inst	= 1'b0;
							end
		RV32I_SRA:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_SRA;
								illegal_inst	= 1'b0;
							end
		RV32I_OR:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_OR;
								illegal_inst	= 1'b0;
							end
		RV32I_AND:			begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_AND;
								illegal_inst	= 1'b0;
							end
		RV32I_FENCE:		begin
								illegal_inst	= 1'b0;
							end
		RV32I_ECALL:		begin
								env_call		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_EBREAK:		;
		// priveleged instructions
		RV32I_MRET:			begin
								jump_ena		= 1'b1;
								jump_alw		= 1'b1;
								trap_ret		= 1'b1;
								illegal_inst	= 1'b0;
							end
		RV32I_WFI:			begin
								illegal_inst	= 1'b0;
							end
		// RV32Zicsr instructions
		RV32Zicsr_CSRRW:	begin
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								csr_rena		= |rd_addr;
								csr_wena		= 1'b1;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RW;
								illegal_inst	= 1'b0;
							end
		RV32Zicsr_CSRRS:	begin
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								csr_rena		= 1'b1;
								csr_wena		= |rs1_addr;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RS;
								illegal_inst	= 1'b0;
							end
		RV32Zicsr_CSRRC:	begin
								rs1_rena		= 1'b1;
								rd_wena			= 1'b1;
								csr_rena		= 1'b1;
								csr_wena		= |rs1_addr;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RC;
								illegal_inst	= 1'b0;
							end
		RV32Zicsr_CSRRWI:	begin
								immediate		= uimm;
								rd_wena			= 1'b1;
								csr_rena		= |rd_addr;
								csr_wena		= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RW;
								illegal_inst	= 1'b0;
							end
		RV32Zicsr_CSRRSI:	begin
								immediate		= uimm;
								rd_wena			= 1'b1;
								csr_rena		= 1'b1;
								csr_wena		= |uimm;
								sel_IM			= 1'b1;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RS;
								illegal_inst	= 1'b0;
							end
		RV32Zicsr_CSRRCI:	begin
								immediate		= uimm;
								rd_wena			= 1'b1;
								csr_rena		= 1'b1;
								csr_wena		= |uimm;
								sel_IM			= 1'b1;
								wb_src			= SEL_CSR;
								csr_op			= CSR_RC;
								illegal_inst	= 1'b0;
							end
		// RV32M instructions
		RV32M_MUL:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_MUL;
								mul_op			= UMULL;
								illegal_inst	= 1'b0;
							end
		RV32M_MULH:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_MUL;
								mul_op			= SMULH;
								illegal_inst	= 1'b0;
							end
		RV32M_MULHSU:		if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_MUL;
								mul_op			= SUMULH;
								illegal_inst	= 1'b0;
							end
		RV32M_MULHU:		if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_MUL;
								mul_op			= UMULH;
								illegal_inst	= 1'b0;
							end
		RV32M_DIV:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_DIV;
								div_op			= SDIV;
								illegal_inst	= 1'b0;
							end
		RV32M_DIVU:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_DIV;
								div_op			= UDIV;
								illegal_inst	= 1'b0;
							end
		RV32M_REM:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_DIV;
								div_op			= SREM;
								illegal_inst	= 1'b0;
							end
		RV32M_REMU:			if (M_ena) begin
								rs1_rena		= 1'b1;
								rs2_rena		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_DIV;
								div_op			= UREM;
								illegal_inst	= 1'b0;
							end
		// RV32F instructions
		RV32F_FLW:			if (F_ena) begin
								immediate		= immediate_I;
								rs1_addr[5]		= 1'b0;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_LW;
								illegal_inst	= 1'b0;
							end
		RV32F_FSW:			if (F_ena) begin
								immediate		= immediate_S;
								rs1_addr[5]		= 1'b0;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								sel_IM			= 1'b1;
								wb_src			= SEL_MEM;
								alu_op			= ALU_ADD;
								mem_op			= MEM_SW;
								illegal_inst	= 1'b0;
							end
		RV32F_FMADD:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rs3_addr[5]		= 1'b1;
								rs3_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_MADD;
								illegal_inst	= 1'b0;
							end
		RV32F_FMSUB:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rs3_addr[5]		= 1'b1;
								rs3_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_MSUB;
								illegal_inst	= 1'b0;
							end
		RV32F_FNMSUB:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rs3_addr[5]		= 1'b1;
								rs3_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_NMSUB;
								illegal_inst	= 1'b0;
							end
		RV32F_FNMADD:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rs3_addr[5]		= 1'b1;
								rs3_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_NMADD;
								illegal_inst	= 1'b0;
							end
		RV32F_FADD:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_ADD;
								illegal_inst	= 1'b0;
							end
		RV32F_FSUB:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SUB;
								illegal_inst	= 1'b0;
							end
		RV32F_FMUL:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_MUL;
								illegal_inst	= 1'b0;
							end
		RV32F_FDIV:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_DIV;
								illegal_inst	= 1'b0;
							end
		RV32F_FSQRT:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SQRT;
								illegal_inst	= 1'b0;
							end
		RV32F_FSGNJ:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SGNJ;
								illegal_inst	= 1'b0;
							end
		RV32F_FSGNJN:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SGNJN;
								illegal_inst	= 1'b0;
							end
		RV32F_FSGNJX:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SGNJX;
								illegal_inst	= 1'b0;
							end
		RV32F_FMIN:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_MIN;
								illegal_inst	= 1'b0;
							end
		RV32F_FMAX:			if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_MAX;
								illegal_inst	= 1'b0;
							end
		RV32F_FCVT_W_S:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_CVTFI;
								illegal_inst	= 1'b0;
							end
		RV32F_FCVT_WU_S:	if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_CVTFU;
								illegal_inst	= 1'b0;
							end
		RV32F_FMV_X_W:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		RV32F_FEQ_S:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SEQ;
								illegal_inst	= 1'b0;
							end
		RV32F_FLT_S:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SLT;
								illegal_inst	= 1'b0;
							end
		RV32F_FLE_S:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rs2_addr[5]		= 1'b1;
								rs2_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_SLE;
								illegal_inst	= 1'b0;
							end
		RV32F_FCLASS_S:		if (F_ena) begin
								rs1_addr[5]		= 1'b1;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b0;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_CLASS;
								illegal_inst	= 1'b0;
							end
		RV32F_FCVT_S_W:		if (F_ena) begin
								rs1_addr[5]		= 1'b0;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_CVTIF;
								illegal_inst	= 1'b0;
							end
		RV32F_FCVT_S_WU:	if (F_ena) begin
								rs1_addr[5]		= 1'b0;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								wb_src			= SEL_FPU;
								fpu_op			= FPU_OP_CVTUF;
								illegal_inst	= 1'b0;
							end
		RV32F_FMV_W_X:		if (F_ena) begin
								rs1_addr[5]		= 1'b0;
								rs1_rena		= 1'b1;
								rd_addr[5]		= 1'b1;
								rd_wena			= 1'b1;
								alu_op			= ALU_ADD;
								illegal_inst	= 1'b0;
							end
		endcase
	end

endmodule