import CPU_pkg::*;

module ID_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	output	logic			valid_out_mul,
	input	logic			ready_in_mul,
	output	logic			valid_out_div,
	input	logic			ready_in_div,
	output	logic			valid_out_fpu,
	input	logic			ready_in_fpu,
	
	input	logic			M_ena_csr,
	input	logic			F_ena_csr,
	input	logic	[31:0]	trap_raddr_csr,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IR_IF,
	input	logic			exc_pend_IF,
	input	logic	[31:0]	exc_cause_IF,
	
	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,
	
	output	logic	[31:0]	PC_ID,
	output	logic	[31:0]	IR_ID,
	output	logic	[31:0]	IM_ID,
	output	logic			rs1_rena_ID,
	output	logic	[5:0]	rs1_addr_ID,
	output	logic	[31:0]	rs1_data_ID,
	output	logic			rs2_rena_ID,
	output	logic	[5:0]	rs2_addr_ID,
	output	logic	[31:0]	rs2_data_ID,
	output	logic			rs3_rena_ID,
	output	logic	[5:0]	rs3_addr_ID,
	output	logic	[31:0]	rs3_data_ID,
	output	logic			rd_wena_ID,
	output	logic	[5:0]	rd_addr_ID,
	output	logic	[11:0]	csr_addr_ID,
	output	logic			csr_rena_ID,
	output	logic			csr_wena_ID,
	output	logic			sel_PC_ID,
	output	logic			sel_IM_ID,
	output	logic	[2:0]	wb_src_ID,
	output	logic	[3:0]	alu_op_ID,
	output	logic	[2:0]	mem_op_ID,
	output	logic	[1:0]	csr_op_ID,
	output	logic	[1:0]	mul_op_ID,
	output	logic	[1:0]	div_op_ID,
	output	logic	[4:0]	fpu_op_ID,
	output	logic	[2:0]	fpu_rm_ID,
	output	logic			jump_ena_ID,
	output	logic			jump_ind_ID,
	output	logic			jump_alw_ID,
	output	logic			jump_pred_ID,
	output	logic			trap_ret_ID,
	output	logic			exc_pend_ID,
	output	logic	[31:0]	exc_cause_ID,
	
	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX,
	
	input	logic			rd_wena_to_WB,
	input	logic	[5:0]	rd_addr_to_WB,
	input	logic	[31:0]	rd_data_to_WB
);
	
	logic	[31:0]	immediate;
	logic			rs1_rena;
	logic	[5:0]	rs1_addr;
	logic	[31:0]	rs1_data;
	logic			rs2_rena;
	logic	[5:0]	rs2_addr;
	logic	[31:0]	rs2_data;
	logic			rs3_rena;
	logic	[5:0]	rs3_addr;
	logic	[31:0]	rs3_data;
	logic			rd_wena;
	logic	[5:0]	rd_addr;
	logic			csr_rena;
	logic			csr_wena;
	logic	[11:0]	csr_addr;
	logic			sel_PC;
	logic			sel_IM;
	logic	[2:0]	wb_src;
	logic	[3:0]	alu_op;
	logic	[2:0]	mem_op;
	logic	[1:0]	csr_op;
	logic	[1:0]	mul_op;
	logic	[1:0]	div_op;
	logic	[4:0]	fpu_op;
	logic	[2:0]	fpu_rm;
	logic			jump_ena;
	logic			jump_ind;
	logic			jump_alw;
	logic			env_call;
	logic			trap_ret;
	logic			illegal_inst;
	
	logic			exc_pend;
	logic	[31:0]	exc_cause;
	
	logic			valid_out_int;
	logic			valid_out_mul_int;
	logic			valid_out_div_int;
	logic			valid_out_fpu_int;
	
	logic			stall;

	assign			valid_out		= valid_out_int && !flush;
	assign			valid_out_mul	= valid_out_mul_int && valid_out;
	assign			valid_out_div	= valid_out_div_int && valid_out;
	assign			valid_out_fpu	= valid_out_fpu_int && valid_out;
	
	assign			ready_out		= ready_in && !stall;
	assign			stall			= csr_wena_ID || csr_rena_ID;
	
	always_comb begin
		if (exc_pend_IF) begin
			exc_pend	= 1'b1;
			exc_cause	= exc_cause_IF;
		end

		else if (illegal_inst) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_ILLEGAL_INST;
		end
		
		else if (env_call) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_ENV_CALL_FROM_M;
		end
		
		else begin
			exc_pend	= 1'b0;
			exc_cause	= 32'h00000000;
		end
	end

	// ID/EX pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_out_int		<= 1'b0;
			valid_out_mul_int	<= 1'b0;
			valid_out_div_int	<= 1'b0;
			valid_out_fpu_int	<= 1'b0;
			PC_ID				<= 32'h00000000;
			IR_ID				<= 32'h00000000;
			IM_ID				<= 32'h00000000;
			rs1_rena_ID			<= 1'b0;
			rs1_addr_ID			<= 6'd0;
			rs1_data_ID			<= 32'h00000000;
			rs2_rena_ID			<= 1'b0;
			rs2_addr_ID			<= 6'd0;
			rs2_data_ID			<= 32'h00000000;
			rs3_rena_ID			<= 1'b0;
			rs3_addr_ID			<= 6'd0;
			rs3_data_ID			<= 32'h00000000;
			rd_wena_ID			<= 1'b0;
			rd_addr_ID			<= 6'd0;
			csr_addr_ID			<= 12'h000;
			csr_rena_ID			<= 1'b0;
			csr_wena_ID			<= 1'b0;
			sel_PC_ID			<= 1'b0;
			sel_IM_ID			<= 1'b0;
			wb_src_ID			<= 3'd0;
			alu_op_ID			<= 4'd0;
			mem_op_ID			<= 3'd0;
			csr_op_ID			<= 2'd0;
			mul_op_ID			<= 2'd0;
			div_op_ID			<= 2'd0;
			fpu_op_ID			<= 5'd0;
			fpu_rm_ID			<= 3'd0;
			jump_ena_ID			<= 1'b0;
			jump_ind_ID			<= 1'b0;
			jump_alw_ID			<= 1'b0;
			jump_pred_ID		<= 1'b0;
			trap_ret_ID			<= 1'b0;
			exc_pend_ID			<= 1'b0;
			exc_cause_ID		<= 32'h00000000;
		end
		
		else if (valid_in && ready_out) begin
			valid_out_int		<= 1'b1;
			valid_out_mul_int	<= wb_src == SEL_MUL;
			valid_out_div_int	<= wb_src == SEL_DIV;
			valid_out_fpu_int	<= wb_src == SEL_FPU;
			PC_ID				<= PC_IF;
			IR_ID				<= IR_IF;
			IM_ID				<= immediate;
			rs1_rena_ID			<= rs1_rena;
			rs1_addr_ID			<= rs1_addr;
			rs1_data_ID			<= rs1_data;
			rs2_rena_ID			<= rs2_rena;
			rs2_addr_ID			<= rs2_addr;
			rs2_data_ID			<= rs2_data;
			rs3_rena_ID			<= rs3_rena;
			rs3_addr_ID			<= rs3_addr;
			rs3_data_ID			<= rs3_data;
			rd_wena_ID			<= rd_wena;
			rd_addr_ID			<= rd_addr;
			csr_addr_ID			<= csr_addr;
			csr_rena_ID			<= csr_rena;
			csr_wena_ID			<= csr_wena;
			sel_PC_ID			<= sel_PC;
			sel_IM_ID			<= sel_IM;
			wb_src_ID			<= wb_src;
			alu_op_ID			<= alu_op;
			mem_op_ID			<= mem_op;
			csr_op_ID			<= csr_op;
			mul_op_ID			<= mul_op;
			div_op_ID			<= div_op;
			fpu_op_ID			<= fpu_op;
			fpu_rm_ID			<= fpu_rm;
			jump_ena_ID			<= jump_ena;
			jump_ind_ID			<= jump_ind;
			jump_alw_ID			<= jump_alw;
			jump_pred_ID		<= jump_pred_IF;
			trap_ret_ID			<= trap_ret;
			exc_pend_ID			<= exc_pend;
			exc_cause_ID		<= exc_cause;
		end
		
		else if (valid_out_int && ready_in) begin
			valid_out_int		<= 1'b0;
			valid_out_mul_int	<= 1'b0;
			valid_out_div_int	<= 1'b0;
			valid_out_fpu_int	<= 1'b0;
			PC_ID				<= 32'h00000000;
			IR_ID				<= 32'h00000000;
			IM_ID				<= 32'h00000000;
			rs1_rena_ID			<= 1'b0;
			rs1_addr_ID			<= 6'd0;
			rs1_data_ID			<= 32'h00000000;
			rs2_rena_ID			<= 1'b0;
			rs2_addr_ID			<= 6'd0;
			rs2_data_ID			<= 32'h00000000;
			rs3_rena_ID			<= 1'b0;
			rs3_addr_ID			<= 6'd0;
			rs3_data_ID			<= 32'h00000000;
			rd_wena_ID			<= 1'b0;
			rd_addr_ID			<= 6'd0;
			csr_addr_ID			<= 12'h000;
			csr_rena_ID			<= 1'b0;
			csr_wena_ID			<= 1'b0;
			sel_PC_ID			<= 1'b0;
			sel_IM_ID			<= 1'b0;
			wb_src_ID			<= 3'd0;
			alu_op_ID			<= 4'd0;
			mem_op_ID			<= 3'd0;
			csr_op_ID			<= 2'd0;
			mul_op_ID			<= 2'd0;
			div_op_ID			<= 2'd0;
			fpu_op_ID			<= 5'd0;
			fpu_rm_ID			<= 3'd0;
			jump_ena_ID			<= 1'b0;
			jump_ind_ID			<= 1'b0;
			jump_alw_ID			<= 1'b0;
			jump_pred_ID		<= 1'b0;
			trap_ret_ID			<= 1'b0;
			exc_pend_ID			<= 1'b0;
			exc_cause_ID		<= 32'h00000000;
		end
		
		else begin
			if (valid_out_mul_int && ready_in_mul)
				valid_out_mul_int	<= 1'b0;
			
			if (valid_out_div_int && ready_in_div)
				valid_out_div_int	<= 1'b0;
			
			if (valid_out_fpu_int && ready_in_fpu)
				valid_out_fpu_int	<= 1'b0;
		end
	end

	inst_decoder inst_decoder_inst
	(
		.IR_IF(IR_IF),
		
		.M_ena(M_ena_csr),
		.F_ena(F_ena_csr),
		
		.immediate(immediate),
		.rs1_rena(rs1_rena),
		.rs1_addr(rs1_addr),
		.rs2_rena(rs2_rena),
		.rs2_addr(rs2_addr),
		.rs3_rena(rs3_rena),
		.rs3_addr(rs3_addr),
		.rd_wena(rd_wena),
		.rd_addr(rd_addr),
		.csr_addr(csr_addr),
		.csr_rena(csr_rena),
		.csr_wena(csr_wena),
		.sel_PC(sel_PC),
		.sel_IM(sel_IM),
		.wb_src(wb_src),
		.alu_op(alu_op),
		.mem_op(mem_op),
		.csr_op(csr_op),
		.mul_op(mul_op),
		.div_op(div_op),
		.fpu_op(fpu_op),
		.fpu_rm(fpu_rm),
		.jump_ena(jump_ena),
		.jump_ind(jump_ind),
		.jump_alw(jump_alw),
		.env_call(env_call),
		.trap_ret(trap_ret),
		.illegal_inst(illegal_inst)
	);
	
	branch_predictor #(3, 2) branch_predictor_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_in(ready_in),
		
		.trap_raddr_csr(trap_raddr_csr),

		.PC_IF(PC_IF),
		.IM_IF(immediate),
		.jump_ena_IF(jump_ena),
		.jump_alw_IF(jump_alw),
		.jump_ind_IF(jump_ind),
		.trap_ret_IF(trap_ret),
		.jump_pred_IF(jump_pred_IF),
		.jump_addr_IF(jump_addr_IF),

		.PC_EX(PC_EX),
		.jump_ena_EX(jump_ena_EX),
		.jump_alw_EX(jump_alw_EX),
		.jump_taken_EX(jump_taken_EX)
	);
	
	reg_file reg_file_inst
	(
		.clk(clk),

		.rd_wena(rd_wena_to_WB),
		.rd_addr(rd_addr_to_WB),
		.rd_data(rd_data_to_WB),

		.rs1_rena(rs1_rena),
		.rs1_addr(rs1_addr),
		.rs1_data(rs1_data),

		.rs2_rena(rs2_rena),
		.rs2_addr(rs2_addr),
		.rs2_data(rs2_data),
		
		.rs3_rena(rs3_rena),
		.rs3_addr(rs3_addr),
		.rs3_data(rs3_data)
	);

endmodule