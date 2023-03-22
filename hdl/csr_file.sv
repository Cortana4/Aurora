import CPU_pkg::*;

module csr_file
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic	[1:0]	op
	
	input	logic	[11:0]	csr_addr,
	input	logic			csr_wena,
	input	logic	[31:0]	csr_wdata,
	input	logic			csr_ren,
	output	logic	[31:0]	csr_rdata
);
	
	logic	[31:0]	misa;
	logic			M_ext_ena;
	logic			F_ext_ena;
	assign			misa =
					{					// bits		description
						2'b01,			// 31-30	MXL (machine XLEN = 32)
						4'b0000,		// 29-26	reserved
						13'h0000,		// 25-13	N-Z disabled
						M_ext_ena,		// 12
						6'b000100,		// 11-6		G-H disabled, I enabled, J-L disabled
						F_ext_ena,		// 5
						5'b00000		// 4-0		A-E disabled
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
	logic	[31:2]	base;
	logic	[1:0]	mode;
	assign			mtvec =				// trap vector base address
					{					// bits		description
						base,			// 31-2		
						mode			// 1-0		0: PC=base 1: PC=base+4*cause (only interrupts)
					};
	
	logic	[31:0]	mip;				// individual interrupt pending bits
	logic	[31:0]	mie;				// individual interrupt enable bits
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
	logic	[31:0]	mepc;				// PC of the instruction that was interrupted or caused the exception
	
	logic	[31:0]	mcause;				// code indicating the event that caused the trap
	logic	[31:0]	mtval;				// ???
	logic	[31:0]	mconfigptr;	assign	mconfigptr	= 32'h00000000;
	
	logic	[31:0]	fcsr;
	logic	[2:0]	frm;
	logic	[4:0]	fflags;
	assign			fcsr =
					{					// bits		description
						24'h000000,		// 31-8		reserved
						frm,			// 7-5		FPU rounding mode
						fflags			// 4-0		FPU flags (IV, DZ, OF, UF, IE)
					};

	logic	[31:0]	csr_wdata_int;
	
	always_comb begin
		case (op)
		CSR_RS:		csr_wdata_int	= csr_rdata |  csr_wdata;
		CSR_RC:		csr_wdata_int	= csr_rdata & ~csr_wdata;
		default:	csr_wdata_int	= csr_wdata;
		endcase
	end
	
	always_comb begin
		case (csr_addr)
		CSR_ADDR_MVENDORID:		csr_rdata	= mvendorid;
		CSR_ADDR_MARCHID:		csr_rdata	= marchid;
		CSR_ADDR_MIMPID:		csr_rdata	= mimpid;
		CSR_ADDR_MHARTID:		csr_rdata	= mhartid;
		CSR_ADDR_MSTATUS:		csr_rdata	= mstatus;
		CSR_ADDR_MSTATUSH:		csr_rdata	= mstatush;
		CSR_ADDR_MTVEC:			csr_rdata	= mtvec;
		CSR_ADDR_MIP:			csr_rdata	= mip;
		CSR_ADDR_MIE:			csr_rdata	= mie;
		CSR_ADDR_MCYCLE:		csr_rdata	= mcycle;
		CSR_ADDR_MCYCLEH:		csr_rdata	= mcycleh;
		CSR_ADDR_MINSTRET:		csr_rdata	= minstret;
		CSR_ADDR_MINSTRETH:		csr_rdata	= minstreth;
		CSR_ADDR_MCOUNTINHIBIT:	csr_rdata	= mcountinhibit;
		CSR_ADDR_MSCRATCH:		csr_rdata	= mscratch;
		CSR_ADDR_MEPC:			csr_rdata	= mepc;
		CSR_ADDR_MCAUSE:		csr_rdata	= mcause;
		CSR_ADDR_MTVAL:			csr_rdata	= mtval;
		CSR_ADDR_MCONFIGPTR:	csr_rdata	= mconfigptr;
		CSR_ADDR_FFLAGS:		csr_rdata	= {27'h0000000, fflags};
		CSR_ADDR_FRM:			csr_rdata	= {29'h00000000, frm};
		CSR_ADDR_FCSR:			csr_rdata	= fcsr;
		default:				csr_rdata	= 32'h00000000;
		endcase
	end
	

	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			
		end
		
		else if (csr_wena) begin
			// write access
			if (csr_wen) begin
				case (csr_addr)
				`MISA_ADDR:	begin
								
							end
				endcase
			end
			// read access
			else begin
				case (csr_addr)
				
				endcase
			end
		end
	end


endmodule