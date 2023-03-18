import CPU_pkg::*;

module ID_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	output	logic			valid_out_MUL,
	input	logic			ready_in_MUL,
	output	logic			valid_out_DIV,
	input	logic			ready_in_DIV,
	output	logic			valid_out_FPU,
	input	logic			ready_in_FPU,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IR_IF,
	input	logic	[1:0]	imem_axi_rresp_IF,
	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,
	
	output	logic	[31:0]	PC_ID,
	output	logic	[31:0]	IR_ID,
	output	logic	[31:0]	IM_ID,
	output	logic	[5:0]	rs1_addr_ID,
	output	logic	[31:0]	rs1_data_ID,
	output	logic			rs1_access_ID,
	output	logic	[5:0]	rs2_addr_ID,
	output	logic	[31:0]	rs2_data_ID,
	output	logic			rs2_access_ID,
	output	logic	[5:0]	rs3_addr_ID,
	output	logic	[31:0]	rs3_data_ID,
	output	logic			rs3_access_ID,
	output	logic	[5:0]	rd_addr_ID,
	output	logic			rd_access_ID,
	output	logic			sel_PC_ID,
	output	logic			sel_IM_ID,
	output	logic	[2:0]	wb_src_ID,
	output	logic	[3:0]	ALU_op_ID,
	output	logic	[2:0]	MEM_op_ID,
	output	logic	[1:0]	MUL_op_ID,
	output	logic	[1:0]	DIV_op_ID,
	output	logic	[4:0]	FPU_op_ID,
	output	logic	[2:0]	FPU_rm_ID,
	output	logic			jump_ena_ID,
	output	logic			jump_ind_ID,
	output	logic			jump_alw_ID,
	output	logic			jump_pred_ID,
	// exceptions
	output	logic	[1:0]	imem_axi_rresp_ID,
	output	logic			illegal_inst_ID,
	
	input	logic	[31:0]	PC_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX,
	input	logic			jump_mpred_EX,
	
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,
	input	logic			rd_access_MEM
);
	
	logic	[31:0]	immediate;
	logic	[5:0]	rs1_addr;
	logic	[31:0]	rs1_data;
	logic			rs1_access;
	logic	[5:0]	rs2_addr;
	logic	[31:0]	rs2_data;
	logic			rs2_access;
	logic	[5:0]	rs3_addr;
	logic	[31:0]	rs3_data;
	logic			rs3_access;
	logic	[5:0]	rd_addr;
	logic			rd_access;
	logic			sel_PC;
	logic			sel_IM;
	logic	[2:0]	wb_src;
	logic	[3:0]	ALU_op;
	logic	[2:0]	MEM_op;
	logic	[1:0]	MUL_op;
	logic	[1:0]	DIV_op;
	logic	[4:0]	FPU_op;
	logic	[2:0]	FPU_rm;
	logic			jump_ena;
	logic			jump_ind;
	logic			jump_alw;
	logic			illegal_inst;
	
	logic			valid_reg;
	logic			valid_reg_MUL;
	logic			valid_reg_DIV;
	logic			valid_reg_FPU;

	assign			valid_out		= valid_reg && !jump_mpred_EX;
	assign			valid_out_MUL	= valid_reg_MUL && !jump_mpred_EX;
	assign			valid_out_DIV	= valid_reg_DIV && !jump_mpred_EX;
	assign			valid_out_FPU	= valid_reg_FPU && !jump_mpred_EX;
	assign			ready_out		= ready_in;

	// ID/EX pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_reg			<= 1'b0;
			valid_reg_MUL		<= 1'b0;
			valid_reg_DIV		<= 1'b0;
			valid_reg_FPU		<= 1'b0;
			PC_ID				<= 32'h00000000;
			IR_ID				<= 32'h00000000;
			IM_ID				<= 32'h00000000;
			rs1_addr_ID			<= 6'd0;
			rs1_data_ID			<= 32'h00000000;
			rs1_access_ID		<= 1'b0;
			rs2_addr_ID			<= 6'd0;
			rs2_data_ID			<= 32'h00000000;
			rs2_access_ID		<= 1'b0;
			rs3_addr_ID			<= 6'd0;
			rs3_data_ID			<= 32'h00000000;
			rs3_access_ID		<= 1'b0;
			rd_addr_ID			<= 6'd0;
			rd_access_ID		<= 1'b0;
			sel_PC_ID			<= 1'b0;
			sel_IM_ID			<= 1'b0;
			wb_src_ID			<= 3'd0;
			ALU_op_ID			<= 4'd0;
			MEM_op_ID			<= 3'd0;
			MUL_op_ID			<= 2'd0;
			DIV_op_ID			<= 2'd0;
			FPU_op_ID			<= 5'd0;
			FPU_rm_ID			<= 3'd0;
			jump_ena_ID			<= 1'b0;
			jump_ind_ID			<= 1'b0;
			jump_alw_ID			<= 1'b0;
			jump_pred_ID		<= 1'b0;
			imem_axi_rresp_ID	<= 2'b00;
			illegal_inst_ID		<= 1'b0;
		end
		
		else if (valid_in && ready_out) begin
			valid_reg			<= 1'b1;
			valid_reg_MUL		<= wb_src == SEL_MUL;
			valid_reg_DIV		<= wb_src == SEL_DIV;
			valid_reg_FPU		<= wb_src == SEL_FPU;
			PC_ID				<= PC_IF;
			IR_ID				<= IR_IF;
			IM_ID				<= immediate;
			rs1_addr_ID			<= rs1_addr;
			rs1_data_ID			<= rs1_data;
			rs1_access_ID		<= rs1_access;
			rs2_addr_ID			<= rs2_addr;
			rs2_data_ID			<= rs2_data;
			rs2_access_ID		<= rs2_access;
			rs3_addr_ID			<= rs3_addr;
			rs3_data_ID			<= rs3_data;
			rs3_access_ID		<= rs3_access;
			rd_addr_ID			<= rd_addr;
			rd_access_ID		<= rd_access;
			sel_PC_ID			<= sel_PC;
			sel_IM_ID			<= sel_IM;
			wb_src_ID			<= wb_src;
			ALU_op_ID			<= ALU_op;
			MEM_op_ID			<= MEM_op;
			MUL_op_ID			<= MUL_op;
			DIV_op_ID			<= DIV_op;
			FPU_op_ID			<= FPU_op;
			FPU_rm_ID			<= FPU_rm;
			jump_ena_ID			<= jump_ena;
			jump_ind_ID			<= jump_ind;
			jump_alw_ID			<= jump_alw;
			jump_pred_ID		<= jump_pred_IF;
			imem_axi_rresp_ID	<= imem_axi_rresp_IF;
			illegal_inst_ID		<= illegal_inst;
		end
		
		else if (valid_reg && ready_in) begin
			valid_reg			<= 1'b0;
			valid_reg_MUL		<= 1'b0;
			valid_reg_DIV		<= 1'b0;
			valid_reg_FPU		<= 1'b0;
			PC_ID				<= 32'h00000000;
			IR_ID				<= 32'h00000000;
			IM_ID				<= 32'h00000000;
			rs1_addr_ID			<= 6'd0;
			rs1_data_ID			<= 32'h00000000;
			rs1_access_ID		<= 1'b0;
			rs2_addr_ID			<= 6'd0;
			rs2_data_ID			<= 32'h00000000;
			rs2_access_ID		<= 1'b0;
			rs3_addr_ID			<= 6'd0;
			rs3_data_ID			<= 32'h00000000;
			rs3_access_ID		<= 1'b0;
			rd_addr_ID			<= 6'd0;
			rd_access_ID		<= 1'b0;
			sel_PC_ID			<= 1'b0;
			sel_IM_ID			<= 1'b0;
			wb_src_ID			<= 3'd0;
			ALU_op_ID			<= 4'd0;
			MEM_op_ID			<= 3'd0;
			MUL_op_ID			<= 2'd0;
			DIV_op_ID			<= 2'd0;
			FPU_op_ID			<= 5'd0;
			FPU_rm_ID			<= 3'd0;
			jump_ena_ID			<= 1'b0;
			jump_ind_ID			<= 1'b0;
			jump_alw_ID			<= 1'b0;
			jump_pred_ID		<= 1'b0;
			imem_axi_rresp_ID	<= 2'b00;
			illegal_inst_ID		<= 1'b0;
		end
		
		else begin
			if (valid_reg_MUL && ready_in_MUL)
				valid_reg_MUL	<= 1'b0;
			
			if (valid_reg_DIV && ready_in_DIV)
				valid_reg_DIV	<= 1'b0;
			
			if (valid_reg_FPU && ready_in_FPU)
				valid_reg_FPU	<= 1'b0;
		end
	end

	inst_decoder inst_decoder_inst
	(
		.IR_IF(IR_IF),
		
		.immediate(immediate),
		.rs1_addr(rs1_addr),
		.rs1_access(rs1_access),
		.rs2_addr(rs2_addr),
		.rs2_access(rs2_access),
		.rs3_addr(rs3_addr),
		.rs3_access(rs3_access),
		.rd_addr(rd_addr),
		.rd_access(rd_access),
		.sel_PC(sel_PC),
		.sel_IM(sel_IM),
		.wb_src(wb_src),
		.ALU_op(ALU_op),
		.MEM_op(MEM_op),
		.MUL_op(MUL_op),
		.DIV_op(DIV_op),
		.FPU_op(FPU_op),
		.FPU_rm(FPU_rm),
		.jump_ena(jump_ena),
		.jump_ind(jump_ind),
		.jump_alw(jump_alw),
		.illegal_inst(illegal_inst)
	);
	
	branch_predictor #(2, 2) branch_predictor_inst
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

		.rd_wena(rd_access_MEM),
		.rd_addr(rd_addr_MEM),
		.rd_data(rd_data_MEM),

		.rs1_rena(rs1_access),
		.rs1_addr(rs1_addr),
		.rs1_data(rs1_data),

		.rs2_rena(rs2_access),
		.rs2_addr(rs2_addr),
		.rs2_data(rs2_data),
		
		.rs3_rena(rs3_access),
		.rs3_addr(rs3_addr),
		.rs3_data(rs3_data)
	);
	
	// csr_file

endmodule