`include "AmberFive_constants.svh"
`include "FPU/FPU_constants.svh"

module inst_decoder
(
	input	logic	[31:0]	IR_IF,

	output	logic	[31:0]	immediate,
	output	logic	[5:0]	rs1_addr,
	output	logic			rs1_access,
	output	logic	[5:0]	rs2_addr,
	output	logic			rs2_access,
	output	logic	[5:0]	rs3_addr,
	output	logic			rs3_access,
	output	logic	[5:0]	rd_addr,
	output	logic			rd_access,
	output	logic			sel_PC,
	output	logic			sel_IM,
	output	logic			sel_MUL,
	output	logic			sel_DIV,
	output	logic			sel_FPU,
	output	logic	[2:0]	MEM_op,
	output	logic	[3:0]	ALU_op,
	output	logic	[1:0]	MUL_op,
	output	logic	[1:0]	DIV_op,
	output	logic	[4:0]	FPU_op,
	output	logic	[2:0]	FPU_rm,
	output	logic			dmem_access,
	output	logic			jump_ena,
	output	logic			jump_ind,
	output	logic			illegal_inst
);

	logic	[31:0]	inst;
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
	assign			FPU_rm			= inst[14:12];
	assign			immediate_I		= {{21{inst[31]}}, inst[30:20]};
	assign			immediate_S		= {{21{inst[31]}}, inst[30:25], inst[11:7]};
	assign			immediate_B		= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
	assign			immediate_U		= {inst[31:12], 12'b000000000000};
	assign			immediate_J		= {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
	
	
	always_comb begin
		immediate		= 32'h00000000;
		rs1_addr[5]		= 1'b0;
		rs1_access		= 1'b0;
		rs2_addr[5]		= 1'b0;
		rs2_access		= 1'b0;
		rs3_addr[5]		= 1'b0;
		rs3_access		= 1'b0;
		rd_addr[5]		= 1'b0;
		rd_access		= 1'b0;
		sel_PC			= 1'b0;
		sel_IM			= 1'b0;
		sel_MUL			= 1'b0;
		sel_DIV			= 1'b0;
		sel_FPU			= 1'b0;
		MEM_op			= 3'd0;
		ALU_op			= 4'd0;
		MUL_op			= 2'd0;
		DIV_op			= 2'd0;
		FPU_op			= 5'd0;
		dmem_access		= 1'b0;
		jump_ena		= 1'b0;
		jump_ind		= 1'b0;
		illegal_inst	= 1'b0;
	
		casez (inst)
		// RV32I instructions
		`RV32I_LUI:			begin
								immediate	= immediate_U;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		`RV32I_AUIPC:		begin
								immediate	= immediate_U;
								rd_access	= 1'b1;
								sel_PC		= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		`RV32I_JAL:			begin
								immediate	= immediate_J;
								rd_access	= 1'b1;
								sel_PC		= 1'b1;
								ALU_op		= `ALU_INC;
								jump_ena	= 1'b1;
							end
		`RV32I_JALR:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_PC		= 1'b1;
								ALU_op		= `ALU_INC;
								jump_ena	= 1'b1;
								jump_ind	= 1'b1;
							end
		`RV32I_BEQ:			begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SEQ;
								jump_ena	= 1'b1;
							end
		`RV32I_BNE:			begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SNE;
								jump_ena	= 1'b1;
							end
		`RV32I_BLT:			begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SLT;
								jump_ena	= 1'b1;
							end
		`RV32I_BGE:			begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SGE;
								jump_ena	= 1'b1;
							end
		`RV32I_BLTU:		begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SLTU;
								jump_ena	= 1'b1;
							end
		`RV32I_BGEU:		begin
								immediate	= immediate_B;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								ALU_op		= `ALU_SGEU;
								jump_ena	= 1'b1;
							end
		`RV32I_LB:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LB;
								dmem_access	= 1'b1;
							end
		`RV32I_LH:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LH;
								dmem_access	= 1'b1;
							end
		`RV32I_LW:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LW;
								dmem_access	= 1'b1;
							end
		`RV32I_LBU:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LBU;
								dmem_access	= 1'b1;
							end
		`RV32I_LHU:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LHU;
								dmem_access	= 1'b1;
							end
		`RV32I_SB:			begin
								immediate	= immediate_S;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_SB;
								dmem_access	= 1'b1;
							end
		`RV32I_SH:			begin
								immediate	= immediate_S;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_SH;
								dmem_access	= 1'b1;
							end
		`RV32I_SW:			begin
								immediate	= immediate_S;
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_SW;
								dmem_access	= 1'b1;
							end
		`RV32I_ADDI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		`RV32I_SLTI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_SLT;
							end
		`RV32I_SLTIU:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_SLTU;
							end
		`RV32I_XORI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_XOR;
							end
		`RV32I_ORI:			begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_OR;
							end
		`RV32I_ANDI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_AND;
							end
		`RV32I_SLLI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_SLL;
							end
		`RV32I_SRLI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_SRL;
							end
		`RV32I_SRAI:		begin
								immediate	= immediate_I;
								rs1_access	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_SRA;
							end
		`RV32I_ADD:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		`RV32I_SUB:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SUB;
							end
		`RV32I_SLL:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SLL;
							end
		`RV32I_SLT:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SLT;
							end
		`RV32I_SLTU:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SLTU;
							end
		`RV32I_XOR:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_XOR;
							end
		`RV32I_SRL:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SRL;
							end
		`RV32I_SRA:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_SRA;
							end
		`RV32I_OR:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_OR;
							end
		`RV32I_AND:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_AND;
							end
		`RV32I_FENCE:		;
		`RV32I_ECALL:		;
		`RV32I_EBREAK:		;
		// RV32M instructions
		`RV32M_MUL:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_MUL		= 1'b1;
								MUL_op		= `UMULL;
							end
		`RV32M_MULH:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_MUL		= 1'b1;
								MUL_op		= `SMULH;
							end
		`RV32M_MULHSU:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_MUL		= 1'b1;
								MUL_op		= `SUMULH;
							end
		`RV32M_MULHU:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_MUL		= 1'b1;
								MUL_op		= `UMULH;
							end
		`RV32M_DIV:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_DIV		= 1'b1;
								DIV_op		= `SDIV;
							end
		`RV32M_DIVU:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_DIV		= 1'b1;
								DIV_op		= `UDIV;
							end
		`RV32M_REM:			begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_DIV		= 1'b1;
								DIV_op		= `SREM;
							end
		`RV32M_REMU:		begin
								rs1_access	= 1'b1;
								rs2_access	= 1'b1;
								rd_access	= 1'b1;
								sel_DIV		= 1'b1;
								DIV_op		= `UREM;
							end
		// RV32F instructions
		`RV32F_FLW:			begin
								immediate	= immediate_I;
								rs1_addr[5]	= 1'b0;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_LW;
								dmem_access	= 1'b1;
							end
		`RV32F_FSW:			begin
								immediate	= immediate_S;
								rs1_addr[5]	= 1'b0;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								sel_IM		= 1'b1;
								ALU_op		= `ALU_ADD;
								MEM_op		= `MEM_SW;
								dmem_access	= 1'b1;
							end
		`RV32F_FMADD:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rs3_addr[5]	= 1'b1;
								rs3_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_MADD;
							end
		`RV32F_FMSUB:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rs3_addr[5]	= 1'b1;
								rs3_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_MSUB;
							end
		`RV32F_FNMSUB:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rs3_addr[5]	= 1'b1;
								rs3_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_NMSUB;
							end
		`RV32F_FNMADD:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rs3_addr[5]	= 1'b1;
								rs3_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_NMADD;
							end
		`RV32F_FADD:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_ADD;
							end
		`RV32F_FSUB:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SUB;
							end
		`RV32F_FMUL:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_MUL;
							end
		`RV32F_FDIV:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_DIV;
							end
		`RV32F_FSQRT:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SQRT;
							end
		`RV32F_FSGNJ:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SGNJ;
							end
		`RV32F_FSGNJN:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SGNJN;
							end
		`RV32F_FSGNJX:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SGNJX;
							end
		`RV32F_FMIN:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_MIN;
							end
		`RV32F_FMAX:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_MAX;
							end
		`RV32F_FCVT_W_S:	begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_CVTFI;
							end
		`RV32F_FCVT_WU_S:	begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_CVTFU;
							end
		`RV32F_FMV_X_W:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		`RV32F_FEQ_S:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SEQ;
							end
		`RV32F_FLT_S:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SLT;
							end
		`RV32F_FLE_S:		begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rs2_addr[5]	= 1'b1;
								rs2_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_SLE;
							end
		`RV32F_FCLASS_S:	begin
								rs1_addr[5]	= 1'b1;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b0;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_CLASS;
							end
		`RV32F_FCVT_S_W:	begin
								rs1_addr[5]	= 1'b0;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_CVTIF;
							end
		`RV32F_FCVT_S_WU:	begin
								rs1_addr[5]	= 1'b0;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								sel_FPU		= 1'b1;
								FPU_op		= `FPU_OP_CVTUF;
							end
		`RV32F_FMV_W_X:		begin
								rs1_addr[5]	= 1'b0;
								rs1_access	= 1'b1;
								rd_addr[5]	= 1'b1;
								rd_access	= 1'b1;
								ALU_op		= `ALU_ADD;
							end
		default:			illegal_inst	= 1'b1;
		endcase
	end

endmodule