module ID_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			stall,
	input	logic			clear,
	
	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IR_IF,
	
	output	logic	[31:0]	PC_ID,
	output	logic	[31:0]	IR_ID,
	output	logic	[31:0]	IM_ID,
	output	logic	[4:0]	rs1_addr_ID,
	output	logic	[31:0]	rs1_data_ID,
	output	logic			rs1_access_ID,
	output	logic	[4:0]	rs2_addr_ID,
	output	logic	[31:0]	rs2_data_ID,
	output	logic			rs2_access_ID,
	output	logic	[4:0]	rd_addr_ID,
	output	logic			rd_access_ID,
	output	logic			sel_PC_ID,
	output	logic			sel_IM_ID,
	output	logic			sel_MUL_ID,
	output	logic			sel_DIV_ID,
	output	logic	[2:0]	MEM_op_ID,
	output	logic	[3:0]	ALU_op_ID,
	output	logic	[1:0]	MUL_op_ID,
	output	logic	[1:0]	DIV_op_ID,
	output	logic			dmem_access_ID,
	output	logic			jump_ena_ID,
	output	logic			jump_ind_ID,
	output	logic			illegal_inst_ID,
	
	input	logic	[4:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,
	input	logic			rd_access_MEM
);
	
	logic	[31:0]	immediate;
	logic	[4:0]	rs1_addr;
	logic	[31:0]	rs1_data;
	logic			rs1_access;
	logic	[4:0]	rs2_addr;
	logic	[31:0]	rs2_data;
	logic			rs2_access;
	logic	[4:0]	rd_addr;
	logic			rd_access;
	logic			sel_PC;
	logic			sel_IM;
	logic			sel_MUL;
	logic			sel_DIV;
	logic	[2:0]	MEM_op;
	logic	[3:0]	ALU_op;
	logic	[1:0]	MUL_op;
	logic	[1:0]	DIV_op;
	logic			dmem_access;
	logic			jump_ena;
	logic			jump_ind;
	logic			illegal_inst;

	// ID/EX pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset || clear) begin
			PC_ID			<= 32'h00000000;
			IR_ID			<= 32'h00000000;
			IM_ID			<= 32'h00000000;
			rs1_addr_ID		<= 5'd0;
			rs1_data_ID		<= 32'h00000000;
			rs1_access_ID	<= 1'b0;
			rs2_addr_ID		<= 5'd0;
			rs2_data_ID		<= 32'h00000000;
			rs2_access_ID	<= 1'b0;
			rd_addr_ID		<= 5'd0;
			rd_access_ID	<= 1'b0;
			sel_PC_ID		<= 1'b0;
			sel_IM_ID		<= 1'b0;
			sel_MUL_ID		<= 1'b0;
			sel_DIV_ID		<= 1'b0;
			MEM_op_ID		<= 3'd0;
			ALU_op_ID		<= 4'd0;
			MUL_op_ID		<= 2'd0;
			DIV_op_ID		<= 2'd0;
			dmem_access_ID	<= 1'b0;
			jump_ena_ID		<= 1'b0;
			jump_ind_ID		<= 1'b0;
			illegal_inst_ID	<= 1'b0;
		end
		
		else if (!stall) begin
			PC_ID			<= PC_IF;
			IR_ID			<= IR_IF;
			IM_ID			<= immediate;
			rs1_addr_ID		<= rs1_addr;
			rs1_data_ID		<= rs1_data;
			rs1_access_ID	<= rs1_access;
			rs2_addr_ID		<= rs2_addr;
			rs2_data_ID		<= rs2_data;
			rs2_access_ID	<= rs2_access;
			rd_addr_ID		<= rd_addr;
			rd_access_ID	<= rd_access;
			sel_PC_ID		<= sel_PC;
			sel_IM_ID		<= sel_IM;
			sel_MUL_ID		<= sel_MUL;
			sel_DIV_ID		<= sel_DIV;
			MEM_op_ID		<= MEM_op;
			ALU_op_ID		<= ALU_op;
			MUL_op_ID		<= MUL_op;
			DIV_op_ID		<= DIV_op;
			dmem_access_ID	<= dmem_access;
			jump_ena_ID		<= jump_ena;
			jump_ind_ID		<= jump_ind;
			illegal_inst_ID	<= illegal_inst;
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
		.rd_addr(rd_addr),
		.rd_access(rd_access),
		.sel_PC(sel_PC),
		.sel_IM(sel_IM),
		.sel_MUL(sel_MUL),
		.sel_DIV(sel_DIV),
		.MEM_op(MEM_op),
		.ALU_op(ALU_op),
		.MUL_op(MUL_op),
		.DIV_op(DIV_op),
		.dmem_access(dmem_access),
		.jump_ena(jump_ena),
		.jump_ind(jump_ind),
		.illegal_inst(illegal_inst)
	);
	
	reg_file reg_file_inst
	(
		.clk(clk),
		.reset(reset),

		.rd_wena(rd_access_MEM),
		.rd_addr(rd_addr_MEM),
		.rd_data(rd_data_MEM),

		.rs1_rena(rs1_access),
		.rs1_addr(rs1_addr),
		.rs1_data(rs1_data),

		.rs2_rena(rs1_access),
		.rs2_addr(rs2_addr),
		.rs2_data(rs2_data)
	);

endmodule