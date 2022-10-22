module csr_file
(

);
	
	logic	[31:0]	misa;
	logic	[1:0]	mxl;
	logic	[25:0]	extensions;
	
	logic	[31:0]	mvendorid;
	logic	[24:0]	bank;
	logic	[6:0]	offset;
	
	logic	[31:0]	marchid;
	
	logic	[31:0]	mimpid;
	
	logic	[31:0]	mhartid;
	
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
	logic			SIE;
	
	logic	[31:0]	mstatush;
	logic			MBE;
	logic			SBE;
	
	logic			mtvec;
	logic	[31:2]	base;
	logic	[1:0]	mode;

endmodule