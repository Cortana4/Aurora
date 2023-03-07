`include "CPU_constants.svh"

module csr_file
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic	[1:0]	op
	
	input	logic	[11:0]	csr_addr,
	output	logic	[31:0]	csr_dout,
	input	logic	[31:0]	csr_din,
	input	logic			csr_ena,
	input	logic			csr_wen
);
	
	logic	[31:0]	misa;
	logic			M_ext_ena;
	logic			F_ext_ena;
	assign			misa =
					{
						2'b01,			// MXL
						4'b0000,
						13'h0000,		// N-Z disabled
						M_ext_ena,
						6'b000100,		// G-H disabled, I enabled, J-L disabled
						F_ext_ena,
						5'b00000		// A-E disabled
					};
	
	logic	[31:0]	mvendorid;
	assign			mvendorid =
						32'h00000000;	// non-commercial implementation
	
	logic	[31:0]	marchid;
	assign			marchid =
						32'h00000000;
	
	logic	[31:0]	mimpid;
	assign			mimpid =
						32'h00000000;
	
	logic	[31:0]	mhartid;
	assign			mhartid =
						32'h00000000;
	
	logic	[31:0]	mstatus;
	logic			SD;
	logic			TSR;
	logic			TW;
	logic			TVM;
	logic			MXR;
	logic			SUM;
	logic			MPRV;
	logic	[1:0]	XS;
	logic	[1:0]	FS;
	logic	[1:0]	MPP;
	logic	[1:0]	VS;
	logic			SPP;
	logic			MPIE;
	logic			UBE;
	logic			SPIE;
	logic			MIE;
	logic			SIE;	// immer 0, da nur M mode
	assign			mstatus =
					{
						SD,
						8'h00,
						TSR,
						TW,
						TVM,
						MXR,
						SUM,
						MPRV,
						
						XS,
						FS,
						MPP,
						VS,
						SPP,
						MPIE,
						UBE,
						SPIE,
						1'b0,
						MIE,
						1'b0,
						SIE,
						1'b0
					};
	
	
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			M_ext_ena	<= 1'b1;
			F_ext_ena	<= 1'b1;
		end
		
		else if (csr_ena) begin
			// write access
			if (csr_wen) begin
				case (csr_addr)
				`MISA_ADDR:	begin
								M_ext_ena	<= wdata[12];
								F_ext_ena	<= wdata[5];
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
	
	always_comb begin
		case (op)
		`CSR_RS:		wdata	= rdata | csr_din;
		`CSR_RC:		wdata	= rdata & ~csr_din;
		default:		wdata	= csr_din;
		endcase
	end
	
	always_comb begin
		case (csr_addr)
		`MISA_ADDR:		rdata	= misa;
		default:		rdata	= 32'h00000000;
		endcase
	end
	
	

	
	logic	[31:0]	mstatush;
	logic			MBE;
	logic			SBE;
	
	logic			mtvec;
	logic	[31:2]	base;
	logic	[1:0]	mode;
	
	logic	[31:0]	mdeleg;
	logic	[31:0]	mideleg;
	
	logic	[31:0]	mip;
	logic			MEIP;
	logic			SEIP;
	logic			MTIP;
	logic			STIP;
	logic			MSIP;
	logic			SSIP;
	
	logic	[31:0]	mie;
	logic			MEIE;
	logic			SEIE;
	logic			MTIE;
	logic			STIE;
	logic			MSIE;
	logic			SSIE;
	
	logic	[31:0]	mcycle;
	logic	[31:0]	minstret;
	logic	[31:0]	mhpmcounter		[31:3];
	logic	[31:0]	mhpmevent		[31:3];
	
	logic	[31:0]	mcycleh;
	logic	[31:0]	minstreth;
	logic	[31:0]	mhpmcounterh	[31:3];
	
	logic	[31:0]	mcounteren;
	logic	[28:0]	HPM;
	logic			IR;
	logic			TM;
	logic			CY;
	
	logic	[31:0]	mcountinhibit;
	logic	[31:0]	mscratch;
	logic	[31:0]	mepc;
	
	logic	[31:0]	mcause
	logic			interrupt;
	logic	[30:0]	code;
	
	logic	[31:0]	mtval;
	logic	[31:0]	mconfigptr;
	
	logic	[31:0]	mtime;
	logic	[31:0]	mtimeh;

	logic	[31:0]	mtimecmp;
	logic	[31:0]	mtimecmph;

endmodule