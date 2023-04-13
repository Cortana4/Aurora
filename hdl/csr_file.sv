import CPU_pkg::*;

module csr_file
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic	[1:0]	op,
	
	input	logic	[11:0]	csr_addr,
	input	logic			csr_wena,
	input	logic	[31:0]	csr_wdata,
	input	logic			csr_rena,
	output	logic	[31:0]	csr_rdata,
	
	
	
	input	logic	[31:0]	PC_int,
	input	logic	[31:0]	PC,
	
	input	logic			rd_wena,
	input	logic	[5:0]	rd_addr,
	
	// extension enable signals
	output	logic			M_ena,
	output	logic			F_ena,
	
	// fpu signals
	input	logic	[4:0]	fpu_flags,
	output	logic	[2:0]	fpu_rm,
	
	// exception signals
	input	logic			exc_pend,
	input	logic	[31:0]	exc_cause,

	// interrupt request signals
	input	logic	[15:0]	irq_ext,
	input	logic			irq_int_controller,
	input	logic			irq_timer,
	input	logic			irq_software,
	
	// trap signals
	output	logic			int_taken,
	output	logic			exc_taken,
	output	logic			trap_taken,
	output	logic	[31:0]	trap_addr,
	input	logic			trap_ret,
	output	logic	[31:0]	trap_raddr
);
	
	// machine level csr's
	logic	[31:0]	misa;
	assign			misa =
					{					// bits		description
						2'b01,			// 31-30	MXL		(machine XLEN = 32)
						4'b0000,		// 29-26	reserved
						1'b0,			// 25		Z		(reserved)
						1'b0,			// 24		Y		(reserved)
						1'b0,			// 23		X		(non-standard)
						1'b0,			// 22		W		(reserved)
						1'b0,			// 21		V		(vector)
						1'b0,			// 20		U		(U-mode)
						1'b0,			// 19		T		(reserved)
						1'b0,			// 18		S		(S-mode)
						1'b0,			// 17		R		(reserved)
						1'b0,			// 16		Q		(quad-precision floating-point)
						1'b0,			// 15		P		(packed-SIMD)
						1'b0,			// 14		O		(reserved)
						1'b0,			// 13		N		(user-level interrupts)
						M_ena,			// 12		M		(integer multiply/divide)
						1'b0,			// 11		L		(reserved)
						1'b0,			// 10		K		(reserved)
						1'b0,			// 9		J		(dynamically translated languages)
						1'b1,			// 8		I		(base ISA)
						1'b0,			// 7		H		(H-mode)
						1'b0,			// 6		G		(reserved)
						F_ena,			// 5		F		(single-precision floating-point)
						1'b0,			// 4		E		(RV32E base ISA)
						1'b0,			// 3		D		(double-precision floating-point)
						1'b0,			// 2		C		(compressed)
						1'b0,			// 1		B		(bit-manipulation)
						1'b0			// 0		A		(atomic)
					};
	
	logic	[31:0]	mvendorid;
	assign			mvendorid =			// (non-commercial implementation)
					{					// bits		description
						25'h0000000,	// 31-7		bank
						7'h00			// 6-0		offset
					};
	
	logic	[31:0]	marchid;	assign	archid		= 32'h00000000;
	logic	[31:0]	mimpid;		assign	mimpid		= 32'h00000000;
	logic	[31:0]	mhartid;	assign	mhartid		= 32'h00000000;
	
	logic	[31:0]	mstatus;
	logic	[1:0]	FS;
	logic	[1:0]	XS;			assign	XS			= FS;
	logic			SD;			assign	SD			= &XS;
	logic			MPIE;
	logic			MIE;
	assign			mstatus =
					{					// bits		description
						SD,				// 31		SD		(some registers dirty)
						8'h00,			// 30-23	reserved
						1'b0,			// 22		TSR		(trap SRET instruction)
						1'b0,			// 21		TW		(timeout wait)
						1'b0,			// 20		TVM		(trap virtual memory management operations in S-mode)
						1'b0,			// 19		MXR		(modify privilege of virtual load)
						1'b0,			// 18		SUM		(modify privilege of virtual load/store in S-mode)
						1'b0,			// 17		MPRV	(modify privilege of load/store)
						XS,				// 16-15	XS		(register status summary of all ext.)
						FS,				// 14-13	FS		(status of F-ext. registers)
						2'b11,			// 12-11	MPP		(previous privilege mode when entering M-mode)
						2'b00,			// 10-9		VS		(status of V-ext. registers)
						1'b0,			// 8		SPP		(previous privilege mode when entering S-mode)
						MPIE,			// 7		MPIE	(MIE prior trap)
						1'b0,			// 6		UBE		(U-mode little-/big-endian)
						1'b0,			// 5		SPIE	(SIE prior trap)
						1'b0,			// 4		reserved
						MIE,			// 3		MIE		(M-mode interrupt enable)
						1'b0,			// 2		reserved
						1'b0,			// 1		SIE		(S-mode interrupt enable)
						1'b0			// 0		reserved
					};
	
	logic	[31:0]	mstatush;
	assign			mstatush =
					{					// bits		description
						26'h0000000,	// 31-6		reserved
						1'b0,			// 5		MBE		(M-mode little-/big-endian)
						1'b0,			// 4		SBE		(S-mode little-/big-endian)
						4'h0			// 3-0		reserved
					};
	
	logic	[31:0]	mtvec;
	logic	[29:0]	base;
	logic	[1:0]	mode;
	assign			mtvec =				// trap vector base address
					{					// bits		description
						base,			// 31-2		
						mode			// 1-0		interrupts set PC to 0: base 1: base+4*cause
					};
	
	logic	[31:0]	mip;
	logic	[15:0]	MCIP;		assign	MCIP		= irq_ext;
	logic			MEIP;		assign	MEIP		= irq_int_controller;
	logic			MTIP;		assign	MTIP		= irq_timer;
	logic			MSIP;		assign	MSIP		= irq_software;
	assign			mip =
					{					// bits		description
						MCIP,			// 31-16	custom use
						4'h0,			// 15-12	reserved
						MEIP,			// 11		MEIP	(M-mode extern interrupt pending)
						1'b0,			// 10		reserved
						1'b0,			// 9		SEIP	(S-mode extern interrupt pending)
						1'b0,			// 8		reserved
						MTIP,			// 7		MTIP	(M-mode timer interrupt pending)
						1'b0,			// 6		reserved
						1'b0,			// 5		STIP	(S-mode timer interrupt pending)
						1'b0,			// 4		reserved
						MSIP,			// 3		MSIP	(M-mode software interrupt pending)
						1'b0,			// 2		reserved
						1'b0,			// 1		SSIP	(S-mode software interrupt pending)
						1'b0			// 0		reserved
					};

	logic	[31:0]	mie;
	logic	[15:0]	MCIE;
	logic			MEIE;
	logic			MTIE;
	logic			MSIE
	assign			mie =
					{					// bits		description
						MCIE,			// 31-16	custom use
						4'h0,			// 15-12	reserved
						MEIE,			// 11		MEIE	(M-mode extern interrupt enable)
						1'b0,			// 10		reserved
						1'b0,			// 9		SEIE	(S-mode extern interrupt enable)
						1'b0,			// 8		reserved
						MTIE,			// 7		MTIE	(M-mode timer interrupt enable)
						1'b0,			// 6		reserved
						1'b0,			// 5		STIE	(S-mode timer interrupt enable)
						1'b0,			// 4		reserved
						MSIE,			// 3		MSIE	(M-mode software interrupt enable)
						1'b0,			// 2		reserved
						1'b0,			// 1		SSIE	(S-mode software interrupt enable)
						1'b0			// 0		reserved
					};
	
	logic	[63:0]	mcycle;				// cycle counter
	logic	[63:0]	minstret;			// instruction counter
	
	logic	[31:0]	mcountinhibit;
	logic			IR;
	logic			CY;
	assign			mcountinhibit =
					{					// bits		description
						29'h00000000,	// 31-3		mhpcounter3 - mhpcounter31 disabled 
						IR,				// 2		instruction counter disable
						1'b0,			// 1		reserved
						CY				// 0		cycle counter disable
					};
	
	logic	[31:0]	mscratch;			// ???
	logic	[31:0]	mepc;		assign	trap_raddr	= mepc;
										// PC of the instruction that was interrupted or caused the exception (used as return address)
	
	logic	[31:0]	mcause;				// code indicating the event that caused the trap
	logic	[31:0]	mtval;				// ???
	logic	[31:0]	mconfigptr;	assign	mconfigptr	= 32'h00000000;
	
	logic	[31:0]	fcsr;
	logic	[2:0]	frm;		assign	fpu_rm		= frm;
	logic	[4:0]	fflags;
	assign			fcsr =
					{					// bits		description
						24'h000000,		// 31-8		reserved
						frm,			// 7-5		FPU rounding mode
						fflags			// 4-0		FPU flags (IV, DZ, OF, UF, IE)
					};

	// 
	logic	[31:0]	csr_wdata_int;
	
	logic			illegal_inst;

	logic	[4:0]	int_cause;
	logic	[31:0]	trap_cause;
	
	assign			illegal_inst	= (csr_wena && &csr_addr[11:10]) ||			// write read only
									  ((csr_wena || csr_rena) && illegal_csr);	// read/write non-existent


	priority_encoder #(5) priority_encoder_inst
	(
		.x(mip),
		.y(int_cause)
	);

	always_comb begin
		int_taken		= 1'b0;
		exc_taken		= 1'b0;
		trap_taken		= 1'b0;
		trap_addr		= 32'h00000000;
		trap_cause		= 32'h00000000;
		trap_raddr_int	= 32'h00000000;
			
		if (valid_in && exc_pend) begin
			exc_taken		= 1'b1;
			trap_taken		= 1'b1;
			trap_addr		= {base, 2'b00};
			trap_cause		= exc_cause;
			trap_raddr_int	= PC;
		end
		
		else if (valid_in && illegal_inst) begin
			exc_taken		= 1'b1;
			trap_taken		= 1'b1;
			trap_addr		= {base, 2'b00};
			trap_cause		= CAUSE_ILLEGAL_INST;
			trap_raddr_int	= PC;
		end
		
		else if (MIE && |(mie & mip)) begin
			int_taken		= 1'b1;
			trap_taken		= 1'b1;
			trap_addr		= {base, 2'b00};
			trap_cause		= 32'h80000000 | int_cause;
			trap_raddr_int	= PC_int;

			if (mode == 2'b01)
				trap_addr	= {base, 2'b00} + (trap_cause << 2);
		end
	end

	always_comb begin
		case (op)
		CSR_RS:		csr_wdata_int	= csr_rdata |  csr_wdata;
		CSR_RC:		csr_wdata_int	= csr_rdata & ~csr_wdata;
		default:	csr_wdata_int	= csr_wdata;
		endcase
	end

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			M_ena		<= 1'b1;		// misa
			F_ena		<= 1'b1;
			FS			<= 2'd1;		// mstatus
			MPIE		<= 1'b0;
			MIE			<= 1'b0;
			base		<= 30'h00000000;// mtvec
			mode		<= 2'd0;
			MCIE		<= 16'h0000;	// mie
			MEIE		<= 1'b0;
			MTIE		<= 1'b0;
			MSIE		<= 1'b0;
			mcycle		<= 64'd0;
			minstret	<= 64'd0;
			IR			<= 1'b1;		// mcountinhibit
			CY			<= 1'b1;
			mscratch	<= 32'h00000000;
			mepc		<= 32'h00000000;
			mcause		<= 32'h00000000;
			mtval		<= 32'h00000000;
			fflags		<= 5'b00000;	// fcsr
			frm			<= 3'b000;
		end
		
		else begin
			if (!CY)
				mcycle		<= mcycle + 32'd1;

			if (ready_out) begin
				if (trap_taken) begin
					MPIE		<= MIE;
					MIE			<= 1'b0;
					mepc		<= trap_raddr_int;
				end
				
				if (valid_in && !exc_taken) begin
					if (!IR)
						minstret	<= minstret + 32'd1;
					
					if (F_ena && rd_wena && rd_addr[5]) begin
						fflags		<= fflags | fpu_flags;
						FS			<= 2'd2;
					end
					
					if (trap_ret) begin
						MIE			<= MPIE;
						MPIE		<= 1'b1;
					end
					
					if (csr_wena) begin
						case (csr_addr)
						CSR_ADDR_MISA:			begin
													M_ena	<= csr_wdata_int[12];
													F_ena	<= csr_wdata_int[5];
													FS		<= csr_wdata_int[5] ? 2'd1 : 2'd0;
												end
						CSR_ADDR_MSTATUS:		begin
													FS		<= F_ena ? csr_wdata_int[14:13] : 2'd0;
													MPIE	<= csr_wdata_int[7];
													MIE		<= csr_wdata_int[3];
												end
						CSR_ADDR_MSTATUSH:		;
						CSR_ADDR_MTVEC:			begin
													base	<= csr_wdata_int[31:2];
													mode	<= {1'b0, csr_wdata_int[1:0] == 2'd1};
												end
						CSR_ADDR_MIP:			;
						CSR_ADDR_MIE:			begin
													MCIE	<= csr_wdata_int[13:16];
													MEIE	<= csr_wdata_int[11];
													MTIE	<= csr_wdata_int[7];
													MSIE	<= csr_wdata_int[3];
												end
						CSR_ADDR_MCYCLE:		mcycle		<= {mcycle[63:32], csr_wdata_int};
						CSR_ADDR_MCYCLEH:		mcycle		<= {csr_wdata_int, mcycle[31:0]};
						CSR_ADDR_MINSTRET:		minstret	<= {minstret[63:32], csr_wdata_int};
						CSR_ADDR_MINSTRETH:		minstret	<= {csr_wdata_int, minstret[31:0]};
						CSR_ADDR_MCOUNTINHIBIT:	begin
													IR		<= csr_wdata_int[2];
													CY		<= csr_wdata_int[0];
												end
						CSR_ADDR_MSCRATCH:		mscratch	<= csr_wdata_int;
						CSR_ADDR_MEPC:			mepc		<= csr_wdata_int;
						CSR_ADDR_MCAUSE:		mcause		<= csr_wdata_int;
						CSR_ADDR_MTVAL:			mtval		<= csr_wdata_int;
						CSR_ADDR_FFLAGS:		if (F_ena) begin
													fflags	<= csr_wdata_int[4:0];
												end
						CSR_ADDR_FRM:			if (F_ena) begin
													frm		<= csr_wdata_int[2:0];
												end
						CSR_ADDR_FCSR			if (F_ena) begin
													frm		<= csr_wdata_int[7:5];
													fflags	<= csr_wdata_int[4:0];
												end
						endcase
					end
				end
		end
	end

	always_comb begin
		csr_rdata	= 32'h00000000;
		illegal_csr	= 1'b0;
		
		case (csr_addr)
		CSR_ADDR_MISA:			csr_rdata	= misa;
		CSR_ADDR_MVENDORID:		csr_rdata	= mvendorid;
		CSR_ADDR_MARCHID:		csr_rdata	= marchid;
		CSR_ADDR_MIMPID:		csr_rdata	= mimpid;
		CSR_ADDR_MHARTID:		csr_rdata	= mhartid;
		CSR_ADDR_MSTATUS:		csr_rdata	= mstatus;
		CSR_ADDR_MSTATUSH:		csr_rdata	= mstatush;
		CSR_ADDR_MTVEC:			csr_rdata	= mtvec;
		CSR_ADDR_MIP:			csr_rdata	= mip;
		CSR_ADDR_MIE:			csr_rdata	= mie;
		CSR_ADDR_MCYCLE:		csr_rdata	= mcycle[31:0];
		CSR_ADDR_MCYCLEH:		csr_rdata	= mcycle[63:32];
		CSR_ADDR_MINSTRET:		csr_rdata	= minstret[31:0];
		CSR_ADDR_MINSTRETH:		csr_rdata	= minstret[63:32];
		CSR_ADDR_MCOUNTINHIBIT:	csr_rdata	= mcountinhibit;
		CSR_ADDR_MSCRATCH:		csr_rdata	= mscratch;
		CSR_ADDR_MEPC:			csr_rdata	= mepc;
		CSR_ADDR_MCAUSE:		csr_rdata	= mcause;
		CSR_ADDR_MTVAL:			csr_rdata	= mtval;
		CSR_ADDR_MCONFIGPTR:	csr_rdata	= mconfigptr;
		CSR_ADDR_FFLAGS:		begin
									if (F_ena)
										csr_rdata	= {27'h0000000, fflags};
									else
										illegal_csr	= 1'b1;
								end
		CSR_ADDR_FRM:			begin
									if (F_ena)
										csr_rdata	= {29'h00000000, frm};
									else
										illegal_csr	= 1'b1;
								end
		CSR_ADDR_FCSR:			begin
									if (F_ena)
										csr_rdata	= fcsr;
									else
										illegal_csr	= 1'b1;
								end
		default:				illegal_csr	= 1'b1;
		endcase
	end


endmodule