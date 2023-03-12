`include "CPU_constants.svh"

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
					{
						2'b01,			// MXL (machine XLEN = 32)
						4'b0000,
						13'h0000,		// N-Z disabled
						M_ext_ena,
						6'b000100,		// G-H disabled, I enabled, J-L disabled
						F_ext_ena,
						5'b00000		// A-E disabled
					};
	
	logic	[31:0]	mvendorid;
	assign			mvendorid =			// (non-commercial implementation)
					{
						25'h0000000,	// bank
						7'h00			// offset
					};
	
	logic	[31:0]	marchid;	assign	archid		= 32'h00000000;
	logic	[31:0]	mimpid;		assign	mimpid		= 32'h00000000;
	logic	[31:0]	mhartid;	assign	mhartid		= 32'h00000000;
	
	logic	[31:0]	mstatus;
	logic	[1:0]	FS;
	logic	[1:0]	XS;			assign	XS			= FS;
	logic			SD;			assign	SD			= &XS;
	logic	[1:0]	MPP;		assign	MPP			= 2'b11;
	logic			MPIE;
	logic			MIE;
	assign			mstatus =
					{
						SD,				// SD	(some registers dirty)
						8'h00,
						1'b0,			// TSR	(trap SRET instruction)
						1'b0,			// TW	(timeout wait)
						1'b0,			// TVM	(trap virtual memory management operations in S-mode)
						1'b0,			// MXR	(modify privilege of virtual load)
						1'b0,			// SUM	(modify privilege of virtual load/store in S-mode)
						1'b0,			// MPRV	(modify privilege of load/store)
						XS,				// XS	(register status summary of all ext.)
						FS,				// FS	(status of F-ext. registers)
						MPP,			// MPP	(previous privilege mode when in M-mode)
						2'b00,			// VS	(status of V-ext. registers)
						1'b0,			// SPP	(previous privilege mode when in S-mode)
						MPIE,			// MPIE	(MIE prior trap)
						1'b0,			// UBE	(U-mode little-/big-endian)
						1'b0,			// SPIE	(SIE prior trap)
						1'b0,
						MIE,			// MIE	(M-mode interrupt enable)
						1'b0,
						1'b0,			// SIE	(S-mode interrupt enable)
						1'b0
					};
	
	logic	[31:0]	mstatush;
	assign			mstatush =
					{
						26'h0000000,
						1'b0,			// MBE	(M-mode little-/big-endian)
						1'b0,			// SBE	(S-mode little-/big-endian)
						4'h0
					};
	
	logic	[31:0]	mtvec;
	logic	[31:2]	base;
	logic	[1:0]	mode;
	assign			mtvec =				// trap vector base address
					{
						base,
						mode			// 0: PC=base 1: PC=base+4*cause (only interrupts)
					};
	
	logic	[31:0]	mip;				// individual interrupt pending bits
	logic	[31:0]	mie;				// individual interrupt enable bits
	logic	[63:0]	mcycle;				// cycle counter
	logic	[63:0]	minstret;			// instruction counter
	
	logic	[31:0]	mcountinhibit;
	logic			IR;
	logic			CY;
	assign			mcountinhibit =
					{
						29'h00000000,	// mhpcounter3 - mhpcounter31 disabled 
						IR,				// instruction counter disable
						1'b0,
						CY				// cycle counter disable
					};
	
	logic	[31:0]	mscratch;			// ???
	logic	[31:0]	mepc;				// PC of the instruction that was interrupted or caused the exception
	
	logic	[31:0]	mcause;				// code indicating the event that caused the trap
	logic	[31:0]	mtval;				// ???
	logic	[31:0]	mconfigptr;	assign	mconfigptr	= 32'h00000000;
	logic	[31:0]	mseccfg;	assign	mseccfg		= 32'h00000000;
	
	logic	[31:0]	fcsr;
	logic	[2:0]	frm;
	logic	[4:0]	fflags;
	assign			fcsr =
					{
						24'h000000,
						frm,
						fflags
					};
	
	logic	[31:0]	rdata;
	logic	[31:0]	wdata;
	
	always_comb begin
		case (op)
		`CSR_RS:		wdata	= rdata |  csr_wdata;
		`CSR_RC:		wdata	= rdata & ~csr_wdata;
		default:		wdata	= csr_wdata;
		endcase
	end
	
	always_comb begin
		case (csr_addr)
		`CSR_ADDR_MVENDORID:		rdata	= mvendorid;
		`CSR_ADDR_MARCHID:			rdata	= marchid;
		`CSR_ADDR_MIMPID:			rdata	= mimpid;
		`CSR_ADDR_MHARTID:			rdata	= mhartid;
		`CSR_ADDR_MSTATUS:			rdata	= mstatus;
		`CSR_ADDR_MSTATUSH:			rdata	= mstatush;
		`CSR_ADDR_MTVEC:			rdata	= mtvec;
		`CSR_ADDR_MIP:				rdata	= mip;
		`CSR_ADDR_MIE:				rdata	= mie;
		`CSR_ADDR_MCYCLE:			rdata	= mcycle;
		`CSR_ADDR_MCYCLEH:			rdata	= mcycleh;
		`CSR_ADDR_MINSTRET:			rdata	= minstret;
		`CSR_ADDR_MINSTRETH:		rdata	= minstreth;
		`CSR_ADDR_MCOUNTINHIBIT:	rdata	= mcountinhibit;
		`CSR_ADDR_MSCRATCH:			rdata	= mscratch;
		`CSR_ADDR_MEPC:				rdata	= mepc;
		`CSR_ADDR_MCAUSE:			rdata	= mcause;
		`CSR_ADDR_MTVAL:			rdata	= mtval;
		`CSR_ADDR_MCONFIGPTR:		rdata	= mconfigptr;
		`CSR_ADDR_MSECCFG:			rdata	= ;
		`CSR_ADDR_MSECCFGH:			rdata	= ;
		`CSR_ADDR_FFLAGS,
		`CSR_ADDR_FRM,
		`CSR_ADDR_FCSR:				rdata	= fcsr;
		default:					rdata	= 32'h00000000;
		endcase
	end
	
	always_comb begin
		csr_rdata	= 32'h00000000;
		
		if (csr_ren) begin
			case (csr_addr)
			`CSR_ADDR_FFLAGS:	csr_rdata	= {27'h0000000, fflags};
			`CSR_ADDR_FRM:		csr_rdata	= {29'h00000000, frm};
			default:			csr_rdata	= rdata;
			endcase
		end
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