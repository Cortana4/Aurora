package CPU_pkg;

	//*************************************************************************
	// RV32I instructions
	localparam RV32I_NOP				= 32'b00000000000000000000000000010011;
	localparam RV32I_LUI				= 32'b?????????????????????????0110111;
	localparam RV32I_AUIPC				= 32'b?????????????????????????0010111;
	localparam RV32I_JAL				= 32'b?????????????????????????1101111;
	localparam RV32I_JALR				= 32'b?????????????????000?????1100111;
	localparam RV32I_BEQ				= 32'b?????????????????000?????1100011;
	localparam RV32I_BNE				= 32'b?????????????????001?????1100011;
	localparam RV32I_BLT				= 32'b?????????????????100?????1100011;
	localparam RV32I_BGE				= 32'b?????????????????101?????1100011;
	localparam RV32I_BLTU				= 32'b?????????????????110?????1100011;
	localparam RV32I_BGEU				= 32'b?????????????????111?????1100011;
	localparam RV32I_LB					= 32'b?????????????????000?????0000011;
	localparam RV32I_LH					= 32'b?????????????????001?????0000011;
	localparam RV32I_LW					= 32'b?????????????????010?????0000011;
	localparam RV32I_LBU				= 32'b?????????????????100?????0000011;
	localparam RV32I_LHU				= 32'b?????????????????101?????0000011;
	localparam RV32I_SB					= 32'b?????????????????000?????0100011;
	localparam RV32I_SH					= 32'b?????????????????001?????0100011;
	localparam RV32I_SW					= 32'b?????????????????010?????0100011;
	localparam RV32I_ADDI				= 32'b?????????????????000?????0010011;
	localparam RV32I_SLTI				= 32'b?????????????????010?????0010011;
	localparam RV32I_SLTIU				= 32'b?????????????????011?????0010011;
	localparam RV32I_XORI				= 32'b?????????????????100?????0010011;
	localparam RV32I_ORI				= 32'b?????????????????110?????0010011;
	localparam RV32I_ANDI				= 32'b?????????????????111?????0010011;
	localparam RV32I_SLLI				= 32'b0000000??????????001?????0010011;
	localparam RV32I_SRLI				= 32'b0000000??????????101?????0010011;
	localparam RV32I_SRAI				= 32'b0100000??????????101?????0010011;
	localparam RV32I_ADD				= 32'b0000000??????????000?????0110011;
	localparam RV32I_SUB				= 32'b0100000??????????000?????0110011;
	localparam RV32I_SLL				= 32'b0000000??????????001?????0110011;
	localparam RV32I_SLT				= 32'b0000000??????????010?????0110011;
	localparam RV32I_SLTU				= 32'b0000000??????????011?????0110011;
	localparam RV32I_XOR				= 32'b0000000??????????100?????0110011;
	localparam RV32I_SRL				= 32'b0000000??????????101?????0110011;
	localparam RV32I_SRA				= 32'b0100000??????????101?????0110011;
	localparam RV32I_OR					= 32'b0000000??????????110?????0110011;
	localparam RV32I_AND				= 32'b0000000??????????111?????0110011;
	localparam RV32I_FENCE				= 32'b?????????????????000?????0001111;
	localparam RV32I_ECALL				= 32'b00000000000000000000000001110011;
	localparam RV32I_EBREAK				= 32'b00000000000100000000000001110011;
	
	localparam RV32I_MRET				= 32'b00110000001000000000000001110011;
	localparam RV32I_WFI				= 32'b00010000010100000000000001110011;
	
	//*************************************************************************
	// RV32Zicsr instructions
	localparam RV32Zicsr_CSRRW			= 32'b?????????????????001?????1110011;
	localparam RV32Zicsr_CSRRS			= 32'b?????????????????010?????1110011;
	localparam RV32Zicsr_CSRRC			= 32'b?????????????????011?????1110011;
	localparam RV32Zicsr_CSRRWI			= 32'b?????????????????101?????1110011;
	localparam RV32Zicsr_CSRRSI			= 32'b?????????????????110?????1110011;
	localparam RV32Zicsr_CSRRCI			= 32'b?????????????????111?????1110011;
	
	//*************************************************************************
	// RV32M instructions
	localparam RV32M_MUL				= 32'b0000001??????????000?????0110011;
	localparam RV32M_MULH				= 32'b0000001??????????001?????0110011;
	localparam RV32M_MULHSU				= 32'b0000001??????????010?????0110011;
	localparam RV32M_MULHU				= 32'b0000001??????????011?????0110011;
	localparam RV32M_DIV				= 32'b0000001??????????100?????0110011;
	localparam RV32M_DIVU				= 32'b0000001??????????101?????0110011;
	localparam RV32M_REM				= 32'b0000001??????????110?????0110011;
	localparam RV32M_REMU				= 32'b0000001??????????111?????0110011;
	
	//*************************************************************************
	// RV32F instructions
	localparam RV32F_FLW				= 32'b?????????????????010?????0000111;
	localparam RV32F_FSW				= 32'b?????????????????010?????0100111;
	localparam RV32F_FMADD				= 32'b?????00??????????????????1000011;
	localparam RV32F_FMSUB				= 32'b?????00??????????????????1000111;
	localparam RV32F_FNMSUB				= 32'b?????00??????????????????1001011;
	localparam RV32F_FNMADD				= 32'b?????00??????????????????1001111;
	localparam RV32F_FADD				= 32'b0000000??????????????????1010011;
	localparam RV32F_FSUB				= 32'b0000100??????????????????1010011;
	localparam RV32F_FMUL				= 32'b0001000??????????????????1010011;
	localparam RV32F_FDIV				= 32'b0001100??????????????????1010011;
	localparam RV32F_FSQRT				= 32'b010110000000?????????????1010011;
	localparam RV32F_FSGNJ				= 32'b0010000??????????000?????1010011;
	localparam RV32F_FSGNJN				= 32'b0010000??????????001?????1010011;
	localparam RV32F_FSGNJX				= 32'b0010000??????????010?????1010011;
	localparam RV32F_FMIN				= 32'b0010100??????????000?????1010011;
	localparam RV32F_FMAX				= 32'b0010100??????????001?????1010011;
	localparam RV32F_FCVT_W_S			= 32'b110000000000?????????????1010011;
	localparam RV32F_FCVT_WU_S			= 32'b110000000001?????????????1010011;
	localparam RV32F_FMV_X_W			= 32'b111000000000?????000?????1010011;
	localparam RV32F_FEQ_S				= 32'b1010000??????????010?????1010011;
	localparam RV32F_FLT_S				= 32'b1010000??????????001?????1010011;
	localparam RV32F_FLE_S				= 32'b1010000??????????000?????1010011;
	localparam RV32F_FCLASS_S			= 32'b111000000000?????001?????1010011;
	localparam RV32F_FCVT_S_W			= 32'b110100000000?????????????1010011;
	localparam RV32F_FCVT_S_WU			= 32'b110100000001?????????????1010011;
	localparam RV32F_FMV_W_X			= 32'b111100000000?????000?????1010011;
	
	//*************************************************************************
	// write back sources
	localparam SEL_ALU					= 3'd0;
	localparam SEL_MEM					= 3'd1;
	localparam SEL_CSR					= 3'd2;
	localparam SEL_MUL					= 3'd3;
	localparam SEL_DIV					= 3'd4;
	localparam SEL_FPU					= 3'd5;
	
	//*************************************************************************
	// ALU operations
	localparam ALU_ADD					= 4'd0;
	localparam ALU_SUB					= 4'd1;
	localparam ALU_AND					= 4'd2;
	localparam ALU_OR					= 4'd3;
	localparam ALU_XOR					= 4'd4;
	localparam ALU_SLL					= 4'd5;
	localparam ALU_SRL					= 4'd6;
	localparam ALU_SRA					= 4'd7;
	localparam ALU_SEQ					= 4'd8;
	localparam ALU_SNE					= 4'd9;
	localparam ALU_SLT					= 4'd10;
	localparam ALU_SLTU					= 4'd11;
	localparam ALU_SGE					= 4'd12;
	localparam ALU_SGEU					= 4'd13;
	localparam ALU_INC					= 4'd14;
	
	//*************************************************************************
	// MEM operations
	localparam MEM_LB					= 3'd0;
	localparam MEM_LBU					= 3'd1;
	localparam MEM_LH					= 3'd2;
	localparam MEM_LHU					= 3'd3;
	localparam MEM_LW					= 3'd4;
	localparam MEM_SB					= 3'd5;
	localparam MEM_SH					= 3'd6;
	localparam MEM_SW					= 3'd7;
	
	//*************************************************************************
	// CSR operations
	localparam CSR_RW					= 2'd0;
	localparam CSR_RS					= 2'd1;
	localparam CSR_RC					= 2'd2;
	
	//*************************************************************************
	// MUL operations
	localparam UMULL					= 2'd0;
	localparam UMULH					= 2'd1;
	localparam SMULH					= 2'd2;
	localparam SUMULH					= 2'd3;
	
	//*************************************************************************
	// DIV operations
	localparam UDIV						= 2'd0;
	localparam SDIV						= 2'd1;
	localparam UREM						= 2'd2;
	localparam SREM						= 2'd3;
	
	//*************************************************************************
	// trap causes
	localparam CAUSE_MISALIGNED_INST	= 32'h00000000;
	localparam CAUSE_ILLEGAL_INST		= 32'h00000002;
	localparam CAUSE_BREAKPOINT			= 32'h00000003;
	localparam CAUSE_MISALIGNED_LOAD	= 32'h00000004;
	localparam CAUSE_MISALIGNED_STORE	= 32'h00000006;
	localparam CAUSE_ENV_CALL_FROM_M	= 32'h0000000b;
	localparam CAUSE_IMEM_BUS_ERROR		= 32'h00000018;	// custom (24)
	localparam CAUSE_DMEM_BUS_ERROR		= 32'h00000019;	// custom (25)

	//*************************************************************************
	// CSR addresses
	localparam CSR_ADDR_MVENDORID		= 12'hf11;
	localparam CSR_ADDR_MARCHID			= 12'hf12;
	localparam CSR_ADDR_MIMPID			= 12'hf13;
	localparam CSR_ADDR_MHARTID			= 12'hf14;
	localparam CSR_ADDR_MCONFIGPTR		= 12'hf15;
	localparam CSR_ADDR_MSTATUS			= 12'h300;
	localparam CSR_ADDR_MISA			= 12'h301;
	localparam CSR_ADDR_MIE				= 12'h304;
	localparam CSR_ADDR_MTVEC			= 12'h305;
	localparam CSR_ADDR_MSTATUSH		= 12'h310;
	localparam CSR_ADDR_MSCRATCH		= 12'h340;
	localparam CSR_ADDR_MEPC			= 12'h341;
	localparam CSR_ADDR_MCAUSE			= 12'h342;
	localparam CSR_ADDR_MTVAL			= 12'h343;
	localparam CSR_ADDR_MIP				= 12'h344;
	localparam CSR_ADDR_MCYCLE			= 12'hb00;
	localparam CSR_ADDR_MINSTRET		= 12'hb02;
	localparam CSR_ADDR_MCYCLEH			= 12'hb80;
	localparam CSR_ADDR_MINSTRETH		= 12'hb82;
	localparam CSR_ADDR_MCOUNTINHIBIT	= 12'h320;
	
	localparam CSR_ADDR_FFLAGS			= 12'h001;
	localparam CSR_ADDR_FRM				= 12'h002;
	localparam CSR_ADDR_FCSR			= 12'h003;
	
	//*************************************************************************
	// reset vector
	localparam RESET_VEC				= 32'h00000000;
	
	//*************************************************************************
	// address map (byte aligned)
	localparam BRAM_BASE_ADDR			= 32'h00000000;
	localparam BRAM_LEN					= 32'h00010000;
	
	localparam UART_BASE_ADDR			= 32'h10000000;
	localparam UART_LEN					= 32'h00000028;	// = 10 * 32 bit * 1 byte / 8 bit

endpackage
