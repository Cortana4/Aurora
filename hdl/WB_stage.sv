import CPU_pkg::*;

module WB_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			flush_out,
	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,

	input	logic	[31:0]	int_PC,
	input	logic	[15:0]	int_req_ext,
	input	logic			int_req_ictrl,
	input	logic			int_req_timer,
	input	logic			int_req_soft,

	input	logic			csr_rena_EX,
	input	logic			csr_wena_EX,
	input	logic			exc_pend_EX,

	input	logic	[31:0]	PC_MEM,
	input	logic	[31:0]	IR_MEM,
	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,
	input	logic	[11:0]	csr_addr_MEM,
	input	logic			csr_rena_MEM,
	input	logic			csr_wena_MEM,
	input	logic	[31:0]	csr_wdata_MEM,
	input	logic	[2:0]	wb_src_MEM,
	input	logic	[1:0]	csr_op_MEM,
	input	logic	[4:0]	fpu_flags_MEM,
	input	logic			trap_ret_MEM,
	input	logic			exc_pend_MEM,
	input	logic	[31:0]	exc_cause_MEM,

	output	logic	[31:0]	PC_WB,
	output	logic	[31:0]	IR_WB,
	output	logic			rd_wena_WB,
	output	logic	[5:0]	rd_addr_WB,
	output	logic	[31:0]	rd_data_WB,

	output	logic			M_ena_csr,
	output	logic			F_ena_csr,
	output	logic	[2:0]	fpu_rm_csr,
	output	logic			int_taken_csr,
	output	logic			exc_taken_csr,
	output	logic			trap_taken_csr,
	output	logic	[31:0]	trap_addr_csr,
	output	logic	[31:0]	trap_raddr_csr
);

	logic	[31:0]	csr_rdata;
	logic			stall_int;

	assign			rd_wena_WB	= rd_wena_MEM && !exc_taken_csr && valid_in && ready_out;
	assign			rd_addr_WB	= rd_addr_MEM;
	assign			rd_data_WB	= wb_src_MEM == SEL_CSR ? csr_rdata : rd_data_MEM;

	assign			ready_out	= ready_in;
	assign			flush_out	= flush_in;
	assign			stall_int	= exc_pend_EX  || csr_wena_EX  || csr_rena_EX  ||
								  exc_pend_MEM || csr_wena_MEM || csr_rena_MEM;

	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush_in) begin
			valid_out	<= 1'b0;
			PC_WB		<= 32'h00000000;
			IR_WB		<= 32'h00000000;
		end

		else if (valid_in && ready_out && !flush_out) begin
			valid_out	<= 1'b1;
			PC_WB		<= PC_MEM;
			IR_WB		<= IR_MEM;
		end

		else if (valid_out && ready_in) begin
			valid_out	<= 1'b0;
			PC_WB		<= 32'h00000000;
			IR_WB		<= 32'h00000000;
		end
	end

	csr_file csr_file_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in),
		.ready_in(ready_in),

		.op(csr_op_MEM),

		.csr_addr(csr_addr_MEM),
		.csr_wena(csr_wena_MEM),
		.csr_wdata(csr_wdata_MEM),
		.csr_rena(csr_rena_MEM),
		.csr_rdata(csr_rdata),

		.M_ena(M_ena_csr),
		.F_ena(F_ena_csr),

		.fpu_dirty(rd_wena_MEM && rd_addr_MEM[5]),
		.fpu_flags(fpu_flags_MEM),
		.fpu_rm(fpu_rm_csr),

		.exc_PC(PC_MEM),
		.exc_pend(exc_pend_MEM),
		.exc_cause(exc_cause_MEM),
		.exc_taken(exc_taken_csr),

		.int_PC(int_PC),
		.int_ena(!stall_int),
		.int_req_ext(int_req_ext),
		.int_req_ictrl(int_req_ictrl),
		.int_req_timer(int_req_timer),
		.int_req_soft(int_req_soft),
		.int_taken(int_taken_csr),

		.trap_taken(trap_taken_csr),
		.trap_addr(trap_addr_csr),
		.trap_ret(trap_ret_MEM),
		.trap_raddr(trap_raddr_csr)
	);

endmodule