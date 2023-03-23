import CPU_pkg::*;

module ID_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			flush_out,
	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,
	
	output	logic			valid_out_mul,
	input	logic			ready_in_mul,
	output	logic			valid_out_div,
	input	logic			ready_in_div,
	output	logic			valid_out_fpu,
	input	logic			ready_in_fpu,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IR_IF,
	input	logic	[1:0]	imem_axi_rresp_IF,
	
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
	// exception signals
	output	logic	[1:0]	imem_axi_rresp_ID,
	output	logic			illegal_inst_ID,
	
	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX,
	
	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM
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
	logic			illegal_inst;
	
	logic			valid_reg;
	logic			valid_reg_mul;
	logic			valid_reg_div;
	logic			valid_reg_fpu;
	
	logic			stall;

	assign			valid_out		= valid_reg && !flush;
	assign			valid_out_mul	= valid_reg_mul && !flush;
	assign			valid_out_div	= valid_reg_div && !flush;
	assign			valid_out_fpu	= valid_reg_fpu && !flush;
	
	assign			ready_out		= ready_in && !stall;
	assign			stall			= csr_wena_ID;

	// ID/EX pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush) begin
			valid_reg			<= 1'b0;
			valid_reg_mul		<= 1'b0;
			valid_reg_div		<= 1'b0;
			valid_reg_fpu		<= 1'b0;
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
			imem_axi_rresp_ID	<= 2'b00;
			illegal_inst_ID		<= 1'b0;
		end
		
		else if (valid_in && ready_out) begin
			valid_reg			<= 1'b1;
			valid_reg_mul		<= wb_src == SEL_MUL;
			valid_reg_div		<= wb_src == SEL_DIV;
			valid_reg_fpu		<= wb_src == SEL_FPU;
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
			imem_axi_rresp_ID	<= imem_axi_rresp_IF;
			illegal_inst_ID		<= illegal_inst;
		end
		
		else if (valid_reg && ready_in) begin
			valid_reg			<= 1'b0;
			valid_reg_mul		<= 1'b0;
			valid_reg_div		<= 1'b0;
			valid_reg_fpu		<= 1'b0;
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
			imem_axi_rresp_ID	<= 2'b00;
			illegal_inst_ID		<= 1'b0;
		end
		
		else begin
			if (valid_reg_mul && ready_in_mul)
				valid_reg_mul	<= 1'b0;
			
			if (valid_reg_div && ready_in_div)
				valid_reg_div	<= 1'b0;
			
			if (valid_reg_fpu && ready_in_fpu)
				valid_reg_fpu	<= 1'b0;
		end
	end

	inst_decoder inst_decoder_inst
	(
		.IR_IF(IR_IF),
		
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
		.csr_op(),
		.mul_op(mul_op),
		.div_op(div_op),
		.fpu_op(fpu_op),
		.fpu_rm(fpu_rm),
		.jump_ena(jump_ena),
		.jump_ind(jump_ind),
		.jump_alw(jump_alw),
		.illegal_inst(illegal_inst)
	);
	
	branch_predictor #(3, 2) branch_predictor_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in),
		.ready_in(ready_in),

		.PC_IF(PC_IF),
		.IM_IF(immediate),
		.jump_ena_IF(jump_ena),
		.jump_alw_IF(jump_alw),
		.jump_ind_IF(jump_ind),
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

		.rd_wena(rd_wena_MEM),
		.rd_addr(rd_addr_MEM),
		.rd_data(rd_data_MEM),

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
	
	// csr_file

endmodule