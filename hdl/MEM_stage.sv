import CPU_pkg::*;

module MEM_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			flush_out,
	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,

	input	logic	[31:0]	PC_EX,
	input	logic	[31:0]	IR_EX,
	input	logic			rd_wena_EX,
	input	logic	[5:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic	[11:0]	csr_addr_EX,
	input	logic			csr_rena_EX,
	input	logic			csr_wena_EX,
	input	logic	[31:0]	csr_wdata_EX,
	input	logic	[2:0]	wb_src_EX,
	input	logic	[2:0]	mem_op_EX,
	input	logic	[1:0]	csr_op_EX,
	input	logic	[4:0]	fpu_flags_EX,
	input	logic			trap_ret_EX,
	input	logic			exc_pend_EX,
	input	logic	[31:0]	exc_cause_EX,

	input	logic	[1:0]	dmem_axi_bresp,		// write response channel
	input	logic			dmem_axi_bvalid,
	output	logic			dmem_axi_bready,
	input	logic	[1:0]	dmem_axi_araddr,	// read address channel
	input	logic	[31:0]	dmem_axi_rdata,		// read data channel
	input	logic	[1:0]	dmem_axi_rresp,
	input	logic			dmem_axi_rvalid,
	output	logic			dmem_axi_rready,

	output	logic	[31:0]	PC_MEM,
	output	logic	[31:0]	IR_MEM,
	output	logic			rd_wena_MEM,
	output	logic	[5:0]	rd_addr_MEM,
	output	logic	[31:0]	rd_data_MEM,
	output	logic	[11:0]	csr_addr_MEM,
	output	logic			csr_rena_MEM,
	output	logic			csr_wena_MEM,
	output	logic	[31:0]	csr_wdata_MEM,
	output	logic	[2:0]	wb_src_MEM,
	output	logic	[1:0]	csr_op_MEM,
	output	logic	[4:0]	fpu_flags_MEM,
	output	logic			trap_ret_MEM,
	output	logic			exc_pend_MEM,
	output	logic	[31:0]	exc_cause_MEM,

	input	logic			exc_taken_csr
);

	logic			stall;

	logic	[31:0]	dmem_axi_rdata_sgn_ext;
	logic	[31:0]	dmem_axi_rdata_aligned;
	assign			dmem_axi_rdata_aligned	= dmem_axi_rdata >> (8*dmem_axi_araddr[1:0]);

	assign			dmem_axi_bready			= wb_src_EX == SEL_MEM && !rd_wena_EX && valid_in && ready_out;	// && !flush_out?
	assign			dmem_axi_rready			= wb_src_EX == SEL_MEM &&  rd_wena_EX && valid_in && ready_out;	// && !flush_out?

	assign			ready_out				= ready_in && !stall;
	assign			flush_out				= flush_in || exc_taken_csr;
	assign			stall					= exc_pend_MEM || csr_wena_MEM || csr_rena_MEM ||
											  (!exc_pend_EX && wb_src_EX == SEL_MEM &&
											  ((rd_wena_EX && !dmem_axi_rvalid) ||
											  (!rd_wena_EX && !dmem_axi_bvalid)));

	always_comb begin
		case (mem_op_EX)
		MEM_LB:		dmem_axi_rdata_sgn_ext	= {{24{dmem_axi_rdata_aligned[7]}}, dmem_axi_rdata_aligned[7:0]};
		MEM_LBU:	dmem_axi_rdata_sgn_ext	= {24'h000000, dmem_axi_rdata_aligned[7:0]};
		MEM_LH:		dmem_axi_rdata_sgn_ext	= {{16{dmem_axi_rdata_aligned[15]}}, dmem_axi_rdata_aligned[15:0]};
		MEM_LHU:	dmem_axi_rdata_sgn_ext	= {16'h0000, dmem_axi_rdata_aligned[15:0]};
		default:	dmem_axi_rdata_sgn_ext	= dmem_axi_rdata_aligned;
		endcase
	end
	
	// MEM/WB pipeline registers
	always_ff @(posedge clk) begin
		if (reset || flush_in) begin
			PC_MEM			<= 32'h00000000;
			IR_MEM			<= 32'h00000000;
			rd_wena_MEM		<= 1'b0;
			rd_addr_MEM		<= 6'd0;
			rd_data_MEM		<= 32'h00000000;
			csr_addr_MEM	<= 12'h000;
			csr_rena_MEM	<= 1'b0;
			csr_wena_MEM	<= 1'b0;
			csr_wdata_MEM	<= 32'h00000000;
			wb_src_MEM		<= 3'd0;
			csr_op_MEM		<= 2'd0;
			fpu_flags_MEM	<= 5'b00000;
			trap_ret_MEM	<= 1'b0;
			exc_pend_MEM	<= 1'b0;
			exc_cause_MEM	<= 32'h00000000;
			valid_out		<= 1'b0;
		end

		else if (valid_in && ready_out && !flush_out) begin
			PC_MEM			<= PC_EX;
			IR_MEM			<= IR_EX;
			rd_wena_MEM		<= rd_wena_EX;
			rd_addr_MEM		<= rd_addr_EX;
			rd_data_MEM		<= rd_data_EX;
			csr_addr_MEM	<= csr_addr_EX;
			csr_rena_MEM	<= csr_rena_EX;
			csr_wena_MEM	<= csr_wena_EX;
			csr_wdata_MEM	<= csr_wdata_EX;
			wb_src_MEM		<= wb_src_EX;
			csr_op_MEM		<= csr_op_EX;
			fpu_flags_MEM	<= fpu_flags_EX;
			trap_ret_MEM	<= trap_ret_EX;
			exc_pend_MEM	<= exc_pend_EX;
			exc_cause_MEM	<= exc_cause_EX;
			valid_out		<= 1'b1;

			if (wb_src_EX == SEL_MEM) begin
				// dmem read access (load)
				if (rd_wena_EX) begin
					if (|dmem_axi_rresp) begin
						exc_pend_MEM	<= 1'b1;
						exc_cause_MEM	<= CAUSE_DMEM_BUS_ERROR;
					end

					else
						rd_data_MEM		<= dmem_axi_rdata_sgn_ext;
				end
				// dmem write access (store)
				else if (|dmem_axi_bresp) begin
					exc_pend_MEM	<= 1'b1;
					exc_cause_MEM	<= CAUSE_DMEM_BUS_ERROR;
				end
			end
		end

		else if (valid_out && ready_in) begin
			PC_MEM			<= 32'h00000000;
			IR_MEM			<= 32'h00000000;
			rd_wena_MEM		<= 1'b0;
			rd_addr_MEM		<= 6'd0;
			rd_data_MEM		<= 32'h00000000;
			csr_addr_MEM	<= 12'h000;
			csr_rena_MEM	<= 1'b0;
			csr_wena_MEM	<= 1'b0;
			csr_wdata_MEM	<= 32'h00000000;
			wb_src_MEM		<= 3'd0;
			csr_op_MEM		<= 2'd0;
			fpu_flags_MEM	<= 5'b00000;
			trap_ret_MEM	<= 1'b0;
			exc_pend_MEM	<= 1'b0;
			exc_cause_MEM	<= 32'h00000000;
			valid_out		<= 1'b0;
		end
	end

endmodule