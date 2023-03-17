package FPU_pkg;
	/*
	// these instructions are not performed by the FPU
	// they are only listed for completeness
	// load/store RAM					// assembler instruction
	localparam FPU_OP_SW	= 5'd2;		// FSW
	localparam FPU_OP_LW	= 5'd1;		// FLW

	// load/store int register
	localparam FPU_OP_SR	= 5'd19;	// FMV.X.W
	localparam FPU_OP_LR	= 5'd26;	// FMV.W.X
	*/

	// multiply add/multiply sub
	localparam FPU_OP_MADD	= 5'd3;		// FMADD.S
	localparam FPU_OP_MSUB	= 5'd4;		// FMSUB.S
	localparam FPU_OP_NMSUB	= 5'd5;		// FNMSUB.S
	localparam FPU_OP_NMADD	= 5'd6;		// FNMADD.S

	// standard functions
	localparam FPU_OP_ADD	= 5'd7;		// FADD.S
	localparam FPU_OP_SUB	= 5'd8;		// FSUB.S
	localparam FPU_OP_MUL	= 5'd9;		// FMUL.S
	localparam FPU_OP_DIV	= 5'd10;	// FDIV.S
	localparam FPU_OP_SQRT	= 5'd11;	// FSQRT.S
	localparam FPU_OP_SGNJ	= 5'd12;	// FSGNJ.S
	localparam FPU_OP_SGNJN	= 5'd13;	// FSGNJN.S
	localparam FPU_OP_SGNJX	= 5'd14;	// FSGNJX.S
	localparam FPU_OP_MIN	= 5'd15;	// FMIN.S
	localparam FPU_OP_MAX	= 5'd16;	// FMAX.S

	// conversion
	localparam FPU_OP_CVTFI	= 5'd17;	// FCVT.W.S
	localparam FPU_OP_CVTFU	= 5'd18;	// FCVT.WU.S
	localparam FPU_OP_CVTIF	= 5'd24;	// FCVT.S.W
	localparam FPU_OP_CVTUF	= 5'd25;	// FCVT.S.WU

	// compare
	localparam FPU_OP_SEQ	= 5'd20;	// FEQ.S
	localparam FPU_OP_SLT	= 5'd21;	// FLT.S
	localparam FPU_OP_SLE	= 5'd22;	// FLE.S
	localparam FPU_OP_CLASS	= 5'd23;	// FCLASS.S

	localparam FPU_OP_NOP	= 5'd0;

	// rounding modes
	localparam FPU_RM_RNE	= 3'b000;	// round to nearest (tie to even)
	localparam FPU_RM_RTZ	= 3'b001;	// round towards 0 (truncate)
	localparam FPU_RM_RDN	= 3'b010;	// round down (towards -inf)
	localparam FPU_RM_RUP	= 3'b011;	// round up (towards +inf)
	localparam FPU_RM_RMM	= 3'b100;	// round to nearest (tie to max magnitude)
	localparam FPU_RM_DYN	= 3'b111;	// use rounding mode from fcsr

endpackage