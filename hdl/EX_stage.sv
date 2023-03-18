import CPU_pkg::*;

module EX_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic			valid_in_MUL,
	output	logic			ready_out_MUL,
	input	logic			valid_in_DIV,
	output	logic			ready_out_DIV,
	input	logic			valid_in_FPU,
	output	logic			ready_out_FPU,

	// write address channel
	output	logic	[31:0]	dmem_axi_awaddr,
	output	logic	[2:0]	dmem_axi_awprot,
	output	logic			dmem_axi_awvalid,
	input	logic			dmem_axi_awready,
	// write data channel
	output	logic	[31:0]	dmem_axi_wdata,
	output	logic	[3:0]	dmem_axi_wstrb,
	output	logic			dmem_axi_wvalid,
	input	logic			dmem_axi_wready,
	// read address channel
	output	logic	[31:0]	dmem_axi_araddr,
	output	logic	[2:0]	dmem_axi_arprot,
	output	logic			dmem_axi_arvalid,
	input	logic			dmem_axi_arready,

	input	logic	[31:0]	PC_ID,
	input	logic	[31:0]	IR_ID,
	input	logic	[31:0]	IM_ID,
	input	logic	[5:0]	rs1_addr_ID,
	input	logic	[31:0]	rs1_data_ID,
	input	logic			rs1_access_ID,
	input	logic	[5:0]	rs2_addr_ID,
	input	logic	[31:0]	rs2_data_ID,
	input	logic			rs2_access_ID,
	input	logic	[5:0]	rs3_addr_ID,
	input	logic	[31:0]	rs3_data_ID,
	input	logic			rs3_access_ID,
	input	logic	[5:0]	rd_addr_ID,
	input	logic			rd_access_ID,
	input	logic			sel_PC_ID,
	input	logic			sel_IM_ID,
	input	logic	[2:0]	wb_src_ID,
	input	logic	[3:0]	ALU_op_ID,
	input	logic	[2:0]	MEM_op_ID,
	input	logic	[1:0]	MUL_op_ID,
	input	logic	[1:0]	DIV_op_ID,
	input	logic	[4:0]	FPU_op_ID,
	input	logic	[2:0]	FPU_rm_ID,
	input	logic			jump_ena_ID,
	input	logic			jump_ind_ID,
	input	logic			jump_alw_ID,
	input	logic			jump_pred_ID,
	input	logic	[1:0]	imem_axi_rresp_ID,
	input	logic			illegal_inst_ID,

	output	logic	[31:0]	PC_EX,
	output	logic	[31:0]	IR_EX,
	output	logic	[31:0]	IM_EX,
	output	logic	[5:0]	rd_addr_EX,
	output	logic	[31:0]	rd_data_EX,
	output	logic			rd_access_EX,
	output	logic	[2:0]	wb_src_EX,
	output	logic	[2:0]	MEM_op_EX,
	output	logic			jump_ena_EX,
	output	logic			jump_alw_EX,
	output	logic			jump_taken_EX,
	output	logic			jump_mpred_EX,
	output	logic	[31:0]	jump_addr_EX,
	// exceptions
	output	logic	[1:0]	imem_axi_rresp_EX,
	output	logic			illegal_inst_EX,
	output	logic			maligned_inst_addr_EX,
	output	logic			maligned_load_addr_EX,
	output	logic			maligned_store_addr_EX,

	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,
	input	logic			rd_access_MEM
);

	logic	[31:0]	rs1_data;
	logic			bypass_rs1_EX;
	logic			bypass_rs1_MEM;

	logic	[31:0]	rs2_data;
	logic			bypass_rs2_EX;
	logic			bypass_rs2_MEM;

	logic	[31:0]	rs3_data;
	logic			bypass_rs3_EX;
	logic			bypass_rs3_MEM;

	logic			rd_after_ld_hazard;

	logic	[31:0]	a;
	logic	[31:0]	b;
	logic	[31:0]	c;
	
	logic			jump_taken;
	logic			jump_mpred;
	logic	[31:0]	jump_addr;

	logic	[31:0]	ALU_out;

	logic	[31:0]	MUL_out;
	logic			valid_out_MUL;
	
	logic	[31:0]	DIV_out;
	logic			valid_out_DIV;
	
	logic	[31:0]	FPU_out;
	logic			valid_out_FPU;

	logic			maligned_inst_addr;
	logic			maligned_load_addr;
	logic			maligned_store_addr;

	logic			stall;

	assign			bypass_rs1_EX		= rs1_access_ID && |rs1_addr_ID && rd_access_EX  && rs1_addr_ID == rd_addr_EX;
	assign			bypass_rs1_MEM		= rs1_access_ID && |rs1_addr_ID && rd_access_MEM && rs1_addr_ID == rd_addr_MEM;

	assign			bypass_rs2_EX		= rs2_access_ID && |rs2_addr_ID && rd_access_EX  && rs2_addr_ID == rd_addr_EX;
	assign			bypass_rs2_MEM		= rs2_access_ID && |rs2_addr_ID && rd_access_MEM && rs2_addr_ID == rd_addr_MEM;

	assign			bypass_rs3_EX		= rs3_access_ID && |rs3_addr_ID && rd_access_EX  && rs3_addr_ID == rd_addr_EX;
	assign			bypass_rs3_MEM		= rs3_access_ID && |rs3_addr_ID && rd_access_MEM && rs3_addr_ID == rd_addr_MEM;

	assign			rd_after_ld_hazard	= (bypass_rs1_EX || bypass_rs2_EX || bypass_rs3_EX) && wb_src_EX == SEL_MEM;

	assign			a					= sel_PC_ID ? PC_ID : rs1_data;
	assign			b					= sel_IM_ID ? IM_ID : rs2_data;
	assign			c					= rs3_data;

	assign			jump_taken			= jump_ena_ID && (ALU_out[0] || jump_alw_ID);
	assign			jump_mpred			= jump_ena_ID && jump_pred_ID != jump_taken;
	assign			maligned_inst_addr	= jump_taken && |jump_addr[1:0];

	assign			ready_out			= ready_in && !stall;
	assign			stall				= rd_after_ld_hazard ||
										  (wb_src_ID == SEL_MUL && !valid_out_MUL) ||
										  (wb_src_ID == SEL_DIV && !valid_out_DIV) ||
										  (wb_src_ID == SEL_FPU && !valid_out_FPU);

	// byte enable computation
	always_comb begin
		dmem_axi_wstrb	= 4'b0000;

		if (dmem_axi_awvalid) begin
			case (MEM_op_EX)
			MEM_SB:	dmem_axi_wstrb	= 4'b0001 << dmem_axi_awaddr[1:0];
			MEM_SH:	dmem_axi_wstrb	= 4'b0011 << dmem_axi_awaddr[1:0];
			MEM_SW:	dmem_axi_wstrb	= 4'b1111 << dmem_axi_awaddr[1:0];
			endcase
		end
	end

	// check for maligned data address exception
	always_comb begin
		maligned_load_addr	= 1'b0;
		maligned_store_addr	= 1'b0;

		if (wb_src_ID == SEL_MEM) begin
			case (MEM_op_ID)
			MEM_LH,
			MEM_LHU:	maligned_load_addr	= &ALU_out[1:0];
			MEM_LW:		maligned_load_addr	= |ALU_out[1:0];
			MEM_SH:		maligned_store_addr	= &ALU_out[1:0];
			MEM_SW:		maligned_store_addr	= |ALU_out[1:0];
			endcase
		end
	end

	// rs1 bypass
	always_comb begin
		if (bypass_rs1_EX)
			rs1_data	= rd_data_EX;

		else if (bypass_rs1_MEM)
			rs1_data	= rd_data_MEM;

		else
			rs1_data	= rs1_data_ID;
	end

	// rs2 bypass
	always_comb begin
		if (bypass_rs2_EX)
			rs2_data	= rd_data_EX;

		else if (bypass_rs2_MEM)
			rs2_data	= rd_data_MEM;

		else
			rs2_data	= rs2_data_ID;
	end

	// rs3 bypass
	always_comb begin
		if (bypass_rs3_EX)
			rs3_data	= rd_data_EX;

		else if (bypass_rs3_MEM)
			rs3_data	= rd_data_MEM;

		else
			rs3_data	= rs3_data_ID;
	end

	// jump address computation
	always_comb begin
		if (!jump_taken)
			jump_addr	= PC_ID + 32'd4;
			
		else if (jump_ind_ID)
			jump_addr	= (rs1_data + IM_ID) & 32'hfffffffe;

		else
			jump_addr	= PC_ID + IM_ID;
	end

	// EX/MEM pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out				<= 1'b0;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_addr_EX				<= 6'd0;
			rd_data_EX				<= 32'h00000000;
			rd_access_EX			<= 1'b0;
			wb_src_EX				<= 3'd0;
			MEM_op_EX				<= 3'd0;
			jump_ena_EX				<= 1'b0;
			jump_alw_EX				<= 1'b0;
			jump_taken_EX			<= 1'b0;
			jump_mpred_EX			<= 1'b0;
			jump_addr_EX			<= 32'h00000000;
			imem_axi_rresp_EX		<= 2'b00;
			illegal_inst_EX			<= 1'b0;
			maligned_inst_addr_EX	<= 1'b0;
			maligned_load_addr_EX	<= 1'b0;
			maligned_store_addr_EX	<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out				<= 1'b1;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			PC_EX					<= PC_ID;
			IR_EX					<= IR_ID;
			IM_EX					<= IM_ID;
			rd_addr_EX				<= rd_addr_ID;
			rd_data_EX				<= 32'h00000000;
			rd_access_EX			<= rd_access_ID;
			wb_src_EX				<= wb_src_ID;
			MEM_op_EX				<= MEM_op_ID;
			jump_ena_EX				<= jump_ena_ID;
			jump_alw_EX				<= jump_alw_ID;
			jump_taken_EX			<= jump_taken;
			jump_mpred_EX			<= jump_mpred;
			jump_addr_EX			<= jump_addr;
			imem_axi_rresp_EX		<= imem_axi_rresp_ID;
			illegal_inst_EX			<= illegal_inst_ID;
			maligned_inst_addr_EX	<= maligned_inst_addr;
			maligned_load_addr_EX	<= maligned_load_addr;
			maligned_store_addr_EX	<= maligned_store_addr;
			
			case (wb_src_ID)
			SEL_MEM:	begin
							// dmem read access (load)
							if (rd_access_ID) begin
								dmem_axi_araddr		<= ALU_out;
								dmem_axi_arprot		<= 3'b010;
								dmem_axi_arvalid	<= 1'b1;
							end
							// dmem write access (store)
							else begin
								dmem_axi_awaddr		<= ALU_out;
								dmem_axi_awprot		<= 3'b010;
								dmem_axi_awvalid	<= 1'b1;
								dmem_axi_wdata		<= rs2_data;
								dmem_axi_wvalid		<= 1'b1;
							end
						end
			SEL_MUL:	rd_data_EX	<= MUL_out;
			SEL_DIV:	rd_data_EX	<= DIV_out;
			SEL_FPU:	rd_data_EX	<= FPU_out;
			default:	rd_data_EX	<= ALU_out;
			endcase
		end

		else if (valid_out && ready_in) begin
			valid_out				<= 1'b0;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_addr_EX				<= 6'd0;
			rd_data_EX				<= 32'h00000000;
			rd_access_EX			<= 1'b0;
			wb_src_EX				<= 3'd0;
			MEM_op_EX				<= 3'd0;
			jump_ena_EX				<= 1'b0;
			jump_alw_EX				<= 1'b0;
			jump_taken_EX			<= 1'b0;
			jump_mpred_EX			<= 1'b0;
			jump_addr_EX			<= 32'h00000000;
			imem_axi_rresp_EX		<= 2'b00;
			illegal_inst_EX			<= 1'b0;
			maligned_inst_addr_EX	<= 1'b0;
			maligned_load_addr_EX	<= 1'b0;
			maligned_store_addr_EX	<= 1'b0;
		end

		else begin
			if (dmem_axi_awvalid && dmem_axi_awready)
				dmem_axi_awvalid	<= 1'b0;

			if (dmem_axi_wvalid  && dmem_axi_wready)
				dmem_axi_wvalid		<= 1'b0;
			
			if (dmem_axi_arvalid && dmem_axi_arready)
				dmem_axi_arvalid	<= 1'b0;
		end
	end

	ALU ALU_inst
	(
		.op(ALU_op_ID),

		.a(a),
		.b(b),

		.y(ALU_out)
	);
	
	int_multiplier #(32, 8) int_multiplier_inst
	(
		.clk(clk),
		.reset(reset),

		.valid_in(valid_in_MUL),
		.ready_out(ready_out_MUL),
		.valid_out(valid_out_MUL),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(MUL_op_ID),

		.a(a),
		.b(b),

		.y(MUL_out)
	);

	int_divider #(32, 2) int_divider_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in_DIV),
		.ready_out(ready_out_DIV),
		.valid_out(valid_out_DIV),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(DIV_op_ID),

		.a(a),
		.b(b),

		.y(DIV_out)
	);

	FPU FPU_inst
	(
		.clk(clk),
		.reset(reset),
		
		.valid_in(valid_in_FPU),
		.ready_out(ready_out_FPU),
		.valid_out(valid_out_FPU),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(FPU_op_ID),
		.rm(FPU_rm_ID),

		.a(a),
		.b(b),
		.c(c),

		.result(FPU_out),

		.IV(),
		.DZ(),
		.OF(),
		.UF(),
		.IE()
	);

endmodule