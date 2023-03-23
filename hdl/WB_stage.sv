import CPU_pkg::*;

module WB_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic	[31:0]	PC_MEM,
	input	logic	[31:0]	IR_MEM,
	input	logic	[31:0]	IM_MEM,
	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,
	input	logic	[11:0]	csr_addr_MEM,
	input	logic			csr_rena_MEM,
	input	logic			csr_wena_MEM,
	input	logic	[31:0]	csr_wdata_MEM,
	input	logic	[2:0]	wb_src_MEM,
	input	logic	[1:0]	csr_op_MEM,
	input	logic	[1:0]	imem_axi_rresp_MEM,
	input	logic			illegal_inst_MEM,
	input	logic			maligned_inst_addr_MEM,
	input	logic			maligned_load_addr_MEM,
	input	logic			maligned_store_addr_MEM,
	input	logic	[1:0]	dmem_axi_bresp_MEM,
	input	logic	[1:0]	dmem_axi_rresp_MEM,
	
	input	logic			rd_wena_WB,
	input	logic	[5:0]	rd_addr_WB,
	input	logic	[31:0]	rd_data_WB
);
	
	logic	[31:0]	csr_rdata;
	
	assign			rd_wena_WB	= valid_in;
	assign			rd_data_WB	= wb_src_MEM == SEL_CSR ? csr_rdata : rd_data_MEM;

	csr_file csr_file_inst
	(
		.clk(clk),
		.reset(reset),

		.op(csr_op_MEM),

		.csr_addr(csr_addr_MEM),
		.csr_wena(valid_in && csr_wena_MEM),
		.csr_wdata(csr_wdata_MEM),
		.csr_rena(valid_in && csr_rena_MEM),
		.csr_rdata(csr_rdata)
	);

endmodule