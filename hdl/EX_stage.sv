`include "AmberFive_constants.svh"

module EX_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	
	output	logic			valid_out,
	input	logic			ready_in,
	
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
	input	logic			sel_MUL_ID,
	input	logic			sel_DIV_ID,
	input	logic			sel_FPU_ID,
	input	logic	[2:0]	MEM_op_ID,
	input	logic	[3:0]	ALU_op_ID,
	input	logic	[1:0]	MUL_op_ID,
	input	logic	[1:0]	DIV_op_ID,
	input	logic	[4:0]	FPU_op_ID,
	input	logic	[2:0]	FPU_rm_ID,
	input	logic			dmem_access_ID,
	input	logic			jump_ena_ID,
	input	logic			jump_ind_ID,
	input	logic			illegal_inst_ID,
	
	output	logic			jump_taken,
	output	logic	[31:0]	jump_addr,
	
	// read address channel
	output	logic	[31:0]	dmem_axi_araddr,
	output	logic	[2:0]	dmem_axi_arprot,
	input	logic			dmem_axi_arready,
	output	logic			dmem_axi_arvalid,
	// write address channel
	output	logic	[31:0]	dmem_axi_awaddr,
	output	logic	[2:0]	dmem_axi_awprot,
	input	logic			dmem_axi_awready,
	output	logic			dmem_axi_awvalid,
	// write data channel
	output	logic	[31:0]	dmem_axi_wdata,
	input	logic			dmem_axi_wready,
	output	logic	[3:0]	dmem_axi_wstrb,
	output	logic			dmem_axi_wvalid,
	
	output	logic	[31:0]	PC_EX,
	output	logic	[31:0]	IR_EX,
	output	logic	[31:0]	IM_EX,
	output	logic	[5:0]	rd_addr_EX,
	output	logic	[31:0]	rd_data_EX,
	output	logic			rd_access_EX,
	output	logic	[2:0]	MEM_op_EX,
	output	logic			dmem_access_EX,
	output	logic			illegal_inst_EX,
	output	logic			misaligned_addr_EX,

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
	
	logic	[31:0]	ALU_out;
	
	logic			MUL_load;
	logic	[31:0]	MUL_out;
	logic			MUL_busy;
	logic			MUL_ready;
	
	logic			DIV_load;
	logic	[31:0]	DIV_out;
	logic			DIV_busy;
	logic			DIV_ready;
	
	logic			FPU_load;
	logic	[31:0]	FPU_out;
	logic			FPU_busy;
	logic			FPU_ready;
	
	logic	[31:0]	rd_data;

	logic			misaligned_addr;
	
	logic			stall;
	
	assign			bypass_rs1_EX		= rs1_access_ID && |rs1_addr_ID && rd_access_EX  && rs1_addr_ID == rd_addr_EX;
	assign			bypass_rs1_MEM		= rs1_access_ID && |rs1_addr_ID && rd_access_MEM && rs1_addr_ID == rd_addr_MEM;
	
	assign			bypass_rs2_EX		= rs2_access_ID && |rs2_addr_ID && rd_access_EX  && rs2_addr_ID == rd_addr_EX;
	assign			bypass_rs2_MEM		= rs2_access_ID && |rs2_addr_ID && rd_access_MEM && rs2_addr_ID == rd_addr_MEM;
	
	assign			bypass_rs3_EX		= rs3_access_ID && |rs3_addr_ID && rd_access_EX  && rs3_addr_ID == rd_addr_EX;
	assign			bypass_rs3_MEM		= rs3_access_ID && |rs3_addr_ID && rd_access_MEM && rs3_addr_ID == rd_addr_MEM;
	
	assign			rd_after_ld_hazard	= (bypass_rs1_EX || bypass_rs2_EX || bypass_rs3_EX) && dmem_access_EX;

	assign			a					= sel_PC_ID ? PC_ID : rs1_data;
	assign			b					= sel_IM_ID ? IM_ID : rs2_data;
	assign			c					= rs3_data;
	
	assign			MUL_load			= sel_MUL_ID && !MUL_busy && !MUL_ready;
	assign			DIV_load			= sel_DIV_ID && !DIV_busy && !DIV_ready;
	assign			FPU_load			= sel_FPU_ID && !FPU_busy && !FPU_ready;
	
	assign			jump_taken			= jump_ena_ID && ALU_out[0] && !rd_after_ld_hazard;
	
	assign			ready_out			= ready_in && !stall;
	assign			stall				= rd_after_ld_hazard || !ready ||
											(dmem_axi_arvalid && !dmem_axi_arready) ||
											(dmem_axi_awvalid && !dmem_axi_awready) ||
											(dmem_axi_wvalid  && !dmem_axi_wready);

	// byte enable computation
	always_comb begin
		dmem_axi_wstrb	= 4'b0000;
		
		if (dmem_axi_awvalid) begin
			case (MEM_op_EX)
			`MEM_SB:	dmem_axi_wstrb	= 4'b0001 << dmem_axi_awaddr[1:0];
			`MEM_SH:	dmem_axi_wstrb	= 4'b0011 << dmem_axi_awaddr[1:0];
			`MEM_SW:	dmem_axi_wstrb	= 4'b1111 << dmem_axi_awaddr[1:0];
			endcase
		end
	end
	
	// check for misaligned access exception
	always_comb begin
		misaligned_addr	= 1'b0;
		
		if (dmem_access_ID) begin
			case (MEM_op_ID)
			`MEM_LH,
			`MEM_LHU,
			`MEM_SH:	misaligned_addr	= &ALU_out[1:0];
			`MEM_LW,
			`MEM_SW:	misaligned_addr	= |ALU_out[1:0];
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
	
	// output multiplexer
	always_comb begin
		if (sel_MUL_ID) begin
			rd_data		= MUL_out;
			ready		= MUL_ready;
		end
		
		else if (sel_DIV_ID) begin
			rd_data		= DIV_out;
			ready		= DIV_ready;
		end
		
		else if (sel_FPU_ID) begin
			rd_data		= FPU_out;
			ready		= FPU_ready;
		end
		
		else begin
			rd_data		= ALU_out;
			ready		= 1'b1;
		end
	end
	
	// jump address computation
	always_comb begin
		if (jump_ind_ID)
			jump_addr	= (rs1_data + IM_ID) & 32'hfffffffe;
		
		else
			jump_addr	= PC_ID + IM_ID;
	end
	
	// valid_out bypass
	always_comb begin
		if (dmem_access_EX) begin
			if (rd_access_EX)
				valid_out	= dmem_axi_araddr_taken || (dmem_axi_arvalid && dmem_axi_arready);

			else begin
				valid_out	= (dmem_axi_awaddr_taken && dmem_axi_awaddr_taken) ||
							  (dmem_axi_awaddr_taken && dmem_axi_wvalid  && dmem_axi_wready) ||
							  (dmem_axi_wdata_taken  && dmem_axi_awvalid && dmem_axi_awready);
			end
		end
		
		else
			valid_out	= valid_reg;
	end
	
	// EX/MEM pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_reg				<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			dmem_axi_araddr_taken	<= 1'b0;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_awaddr_taken	<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_wdata_taken	<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_addr_EX				<= 4'h0;
			rd_data_EX				<= 32'h00000000;
			rd_access_EX			<= 1'b0;
			MEM_op_EX				<= 3'd0;
			dmem_access_EX			<= 1'b0;
			illegal_inst_EX			<= 1'b0;
			misaligned_addr_EX		<= 1'b0;
		end
		
		else if (valid_in && ready_out) begin
			valid_reg				<= 1'b1;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			dmem_axi_araddr_taken	<= 1'b0;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_awaddr_taken	<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_wdata_taken	<= 1'b0;
			PC_EX					<= PC_ID;
			IR_EX					<= IR_ID;
			IM_EX					<= IM_ID;
			rd_addr_EX				<= rd_addr_ID;
			rd_data_EX				<= rd_data;
			rd_access_EX			<= rd_access_ID;
			MEM_op_EX				<= MEM_op_ID;
			dmem_access_EX			<= dmem_access_ID;
			illegal_inst_EX			<= illegal_inst_ID;
			misaligned_addr_EX		<= misaligned_addr;
			
			if (dmem_access_ID) begin
				// dmem read access (load)
				if (rd_access_ID) begin
					valid_reg			<= dmem_axi_arready;
					dmem_axi_araddr		<= ALU_out;
					dmem_axi_arprot		<= 3'b010;
					dmem_axi_arvalid	<= 1'b1;
				end
				// dmem write access (store)
				else begin
					valid_reg			<= dmem_axi_awready && dmem_axi_wready;
					dmem_axi_awaddr		<= ALU_out;
					dmem_axi_awprot		<= 3'b010;
					dmem_axi_awvalid	<= 1'b1;
					dmem_axi_wdata		<= rs2_data;
					dmem_axi_wvalid		<= 1'b1;
				end
			end
		end
		
		else if (valid_out && ready_in) begin
			valid_reg				<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
			dmem_axi_araddr_taken	<= 1'b0;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_awaddr_taken	<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_wdata_taken	<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_addr_EX				<= 4'h0;
			rd_data_EX				<= 32'h00000000;
			rd_access_EX			<= 1'b0;
			MEM_op_EX				<= 3'd0;
			dmem_access_EX			<= 1'b0;
			illegal_inst_EX			<= 1'b0;
			misaligned_addr_EX		<= 1'b0;
		end
		
		else begin
			if (dmem_axi_arvalid && dmem_axi_arready) begin
				dmem_axi_arvalid		<= 1'b0;
				dmem_axi_araddr_taken	<= 1'b1;
			end
			
			if (dmem_axi_awvalid && dmem_axi_awready) begin
				dmem_axi_awvalid		<= 1'b0;
				dmem_axi_awaddr_taken	<= 1'b1;
			end
			
			if (dmem_axi_wvalid && dmem_axi_wready) begin
				dmem_axi_wvalid			<= 1'b0;
				dmem_axi_wdata_taken	<= 1'b1;
			end
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
		.load(MUL_load),

		.op(MUL_op_ID),

		.a(a),
		.b(b),

		.y(MUL_out),
		
		.busy(MUL_busy),
		.ready(MUL_ready)
	);
	
	int_divider #(32, 4) int_divider_inst
	(
		.clk(clk),
		.reset(reset),
		.load(DIV_load),

		.op(DIV_op_ID),

		.a(a),
		.b(b),

		.y(DIV_out),

		.busy(DIV_busy),
		.ready(DIV_ready)
	);
	
	FPU FPU_inst
	(
		.clk(clk),
		.reset(reset),
		.load(FPU_load),

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
		.IE(),

		.busy(FPU_busy),
		.ready(FPU_ready)
	);

endmodule