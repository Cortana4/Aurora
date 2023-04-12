import CPU_pkg::*;

module WB_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic	[15:0]	irq_ext,
	input	logic			irq_int_controller,
	input	logic			irq_timer,
	input	logic			irq_software,
	
	output	logic			M_ena_csr,
	output	logic			F_ena_csr,
	output	logic	[2:0]	fpu_rm_csr,
	output	logic			exc_taken_csr,
	output	logic			trap_taken_csr,
	output	logic	[31:0]	trap_addr_csr,
	output	logic	[31:0]	trap_raddr_csr,

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
	input	logic	[4:0]	fpu_flags_MEM,
	input	logic			trap_ret_MEM,
	input	logic			exc_pend_MEM,
	input	logic	[31:0]	exc_cause_MEM,

	input	logic			rd_wena_WB,
	input	logic	[5:0]	rd_addr_WB,
	input	logic	[31:0]	rd_data_WB
);
	
	logic	[31:0]	csr_rdata;
	
	assign			rd_wena_WB	= rd_wena_MEM && !exc_taken_csr && valid_in && ready_out;
	assign			rd_addr_WB	= rd_addr_MEM;
	assign			rd_data_WB	= wb_src_MEM == SEL_CSR ? csr_rdata : rd_data_MEM;
	
	assign			ready_out	= ready_in;
	
	always_ff @(posedge clk, posedge reset) begin
		if (reset)
			valid_out	<= 1'b0;
			
		else if (valid_in && ready_out)
			valid_out	<= 1'b1;
		
		else if (valid_out && ready_in)
			valid_out	<= 1'b0;
	end

	csr_file csr_file_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_out(ready_out),
		.valid_out(valid_out),
		.ready_in(ready_in),

		.op(csr_op_MEM),

		.csr_addr(csr_addr_MEM),
		.csr_wena(csr_wena_MEM),
		.csr_wdata(csr_wdata_MEM),
		.csr_rena(csr_rena_MEM),
		.csr_rdata(csr_rdata),

		.valid_in(valid_in),

		.PC_int(),
		.PC(PC_MEM),

		.rd_wena(rd_wena_MEM),
		.rd_addr(rd_addr_MEM),

		.M_ena(M_ena_csr),
		.F_ena(F_ena_csr),

		.fpu_flags(fpu_flags_MEM),
		.fpu_rm(fpu_rm_csr),

		.exc_pend(exc_pend_MEM),
		.exc_cause(exc_cause_MEM),

		.irq_ext(irq_ext),
		.irq_int_controller(irq_int_controller),
		.irq_timer(irq_timer),
		.irq_software(irq_software),

		.exc_taken(exc_taken_csr),
		.trap_taken(trap_taken_csr),
		.trap_addr(trap_addr_csr),
		.trap_ret(trap_ret_MEM),
		.trap_raddr(trap_raddr_csr)
	);

endmodule