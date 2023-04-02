import CPU_pkg::*;
import FPU_pkg::*;

module EX_stage
(
	input	logic			clk,
	input	logic			reset,
	input	logic			flush,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,

	input	logic			valid_in_mul,
	output	logic			ready_out_mul,
	input	logic			valid_in_div,
	output	logic			ready_out_div,
	input	logic			valid_in_fpu,
	output	logic			ready_out_fpu,
	
	input	logic	[2:0]	frm,

	input	logic	[31:0]	PC_ID,
	input	logic	[31:0]	IR_ID,
	input	logic	[31:0]	IM_ID,
	input	logic			rs1_rena_ID,
	input	logic	[5:0]	rs1_addr_ID,
	input	logic	[31:0]	rs1_data_ID,
	input	logic			rs2_rena_ID,
	input	logic	[5:0]	rs2_addr_ID,
	input	logic	[31:0]	rs2_data_ID,
	input	logic			rs3_rena_ID,
	input	logic	[5:0]	rs3_addr_ID,
	input	logic	[31:0]	rs3_data_ID,
	input	logic			rd_wena_ID,
	input	logic	[5:0]	rd_addr_ID,
	input	logic	[11:0]	csr_addr_ID,
	input	logic			csr_rena_ID,
	input	logic			csr_wena_ID,
	input	logic			sel_PC_ID,
	input	logic			sel_IM_ID,
	input	logic	[2:0]	wb_src_ID,
	input	logic	[3:0]	alu_op_ID,
	input	logic	[2:0]	mem_op_ID,
	input	logic	[1:0]	csr_op_ID,
	input	logic	[1:0]	mul_op_ID,
	input	logic	[1:0]	div_op_ID,
	input	logic	[4:0]	fpu_op_ID,
	input	logic	[2:0]	fpu_rm_ID,
	input	logic			jump_ena_ID,
	input	logic			jump_ind_ID,
	input	logic			jump_alw_ID,
	input	logic			jump_pred_ID,
	input	logic			trap_taken_ID,
	input	logic	[31:0]	trap_cause_ID,

	output	logic	[31:0]	PC_EX,
	output	logic	[31:0]	IR_EX,
	output	logic	[31:0]	IM_EX,
	output	logic			rd_wena_EX,
	output	logic	[5:0]	rd_addr_EX,
	output	logic	[31:0]	rd_data_EX,
	output	logic	[11:0]	csr_addr_EX,
	output	logic			csr_rena_EX,
	output	logic			csr_wena_EX,
	output	logic	[31:0]	csr_wdata_EX,
	output	logic	[2:0]	wb_src_EX,
	output	logic	[2:0]	mem_op_EX,
	output	logic	[1:0]	csr_op_EX,
	output	logic	[4:0]	fpu_flags_EX,
	output	logic			jump_ena_EX,
	output	logic			jump_alw_EX,
	output	logic			jump_taken_EX,
	output	logic			jump_mpred_EX,
	output	logic	[31:0]	jump_addr_EX,
	
	output	logic			trap_taken_EX,
	output	logic	[31:0]	trap_cause_EX,

	output	logic	[31:0]	dmem_axi_awaddr,	// write address channel
	output	logic	[2:0]	dmem_axi_awprot,
	output	logic			dmem_axi_awvalid,
	input	logic			dmem_axi_awready,
	output	logic	[31:0]	dmem_axi_wdata,		// write data channel
	output	logic	[3:0]	dmem_axi_wstrb,
	output	logic			dmem_axi_wvalid,
	input	logic			dmem_axi_wready,
	output	logic	[31:0]	dmem_axi_araddr,	// read address channel
	output	logic	[2:0]	dmem_axi_arprot,
	output	logic			dmem_axi_arvalid,
	input	logic			dmem_axi_arready,

	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM
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

	logic	[31:0]	csr_wdata;
	logic	[31:0]	a;
	logic	[31:0]	b;
	logic	[31:0]	c;

	logic			jump_taken;
	logic			jump_mpred;
	logic	[31:0]	jump_addr;

	logic	[31:0]	alu_out;
	logic	[31:0]	mul_out;
	logic			valid_out_mul;
	logic	[31:0]	div_out;
	logic			valid_out_div;
	logic	[31:0]	fpu_out;
	logic	[4:0]	fpu_flags;
	logic			valid_out_fpu;

	logic			maligned_inst_addr;
	logic			maligned_load_addr;
	logic			maligned_store_addr;

	logic			trap_taken;
	logic			trap_cause;
	
	logic			dmem_axi_awvalid_int;
	logic	[31:0]	dmem_axi_wdata_int;
	logic	[3:0]	dmem_axi_wstrb_int;
	logic			dmem_axi_wvalid_int;
	logic			dmem_axi_arvalid_int;

	logic			valid_out_int;
	logic			stall;

	assign			bypass_rs1_EX		= rs1_rena_ID && |rs1_addr_ID && rd_wena_EX  && rs1_addr_ID == rd_addr_EX;
	assign			bypass_rs1_MEM		= rs1_rena_ID && |rs1_addr_ID && rd_wena_MEM && rs1_addr_ID == rd_addr_MEM;
	assign			bypass_rs2_EX		= rs2_rena_ID && |rs2_addr_ID && rd_wena_EX  && rs2_addr_ID == rd_addr_EX;
	assign			bypass_rs2_MEM		= rs2_rena_ID && |rs2_addr_ID && rd_wena_MEM && rs2_addr_ID == rd_addr_MEM;
	assign			bypass_rs3_EX		= rs3_rena_ID && |rs3_addr_ID && rd_wena_EX  && rs3_addr_ID == rd_addr_EX;
	assign			bypass_rs3_MEM		= rs3_rena_ID && |rs3_addr_ID && rd_wena_MEM && rs3_addr_ID == rd_addr_MEM;
	assign			rd_after_ld_hazard	= (bypass_rs1_EX || bypass_rs2_EX || bypass_rs3_EX) && wb_src_EX == SEL_MEM;

	assign			csr_wdata			= sel_IM_ID ? IM_ID : rs1_data;
	assign			a					= sel_PC_ID ? PC_ID : rs1_data;
	assign			b					= sel_IM_ID ? IM_ID : rs2_data;
	assign			c					= rs3_data;

	assign			jump_taken			= jump_ena_ID && (alu_out[0] || jump_alw_ID);
	assign			jump_mpred			= jump_ena_ID && jump_pred_ID != jump_taken;
	assign			maligned_inst_addr	= jump_taken  && |jump_addr[1:0];
	
	assign			dmem_axi_awvalid	= dmem_axi_awvalid_int && valid_out && !trap_taken_EX;
	assign			dmem_axi_wvalid		= dmem_axi_wvalid_int  && valid_out && !trap_taken_EX;
	assign			dmem_axi_arvalid	= dmem_axi_arvalid_int && valid_out && !trap_taken_EX;

	assign			valid_out			= valid_out_int && !flush;
	assign			ready_out			= ready_in && !stall;
	assign			stall				= rd_after_ld_hazard || csr_wena_EX || csr_rena_EX ||
										  (wb_src_ID == SEL_MUL && !valid_out_mul) ||
										  (wb_src_ID == SEL_DIV && !valid_out_div) ||
										  (wb_src_ID == SEL_FPU && !valid_out_fpu);

	// wdata and byte enable computation
	always_comb begin
		dmem_axi_wdata_int	= 32'h00000000;
		dmem_axi_wstrb_int	= 4'b0000;

		if (wb_src_ID == SEL_MEM) begin
			case (mem_op_ID)
			MEM_SB:	begin
						dmem_axi_wdata_int	= {4{rs2_data[7:0]}};
						dmem_axi_wstrb_int	= 4'b0001 << dmem_axi_awaddr[1:0];
					end
			MEM_SH:	begin
						dmem_axi_wdata_int	= {2{rs2_data[15:0]}};
						dmem_axi_wstrb_int	= 4'b0011 << dmem_axi_awaddr[1:0];
					end
			MEM_SW:	begin
						dmem_axi_wdata_int	= rs2_data;
						dmem_axi_wstrb_int	= 4'b1111 << dmem_axi_awaddr[1:0];
					end
			endcase
		end
	end

	// check for misaligned data address exception
	always_comb begin
		maligned_load_addr	= 1'b0;
		maligned_store_addr	= 1'b0;

		if (wb_src_ID == SEL_MEM) begin
			case (mem_op_ID)
			MEM_LH,
			MEM_LHU:	maligned_load_addr	= alu_out[0];
			MEM_LW:		maligned_load_addr	= |alu_out[1:0];
			MEM_SH:		maligned_store_addr	= alu_out[0];
			MEM_SW:		maligned_store_addr	= |alu_out[1:0];
			endcase
		end
	end

	always_comb begin
		if (trap_taken_ID) begin
			trap_taken	= 1'b1;
			trap_cause	= trap_caus_ID;
		end
		
		else if (maligned_inst_addr) begin
			trap_taken	= 1'b1;
			trap_cause	= CAUSE_MALIGNED_INST;
		end

		else if (maligned_load_addr) begin
			trap_taken	= 1'b1;
			trap_cause	= CAUSE_MALIGNED_LOAD;
		end

		else if (maligned_store_addr) begin
			trap_taken	= 1'b1;
			trap_cause	= CAUSE_MALIGNED_STORE;
		end

		else begin
			trap_taken	= 1'b0;
			trap_cause	= 32'h00000000;
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
		if (reset || flush) begin
			valid_out_int			<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_wena_EX				<= 1'b0;
			rd_addr_EX				<= 6'd0;
			rd_data_EX				<= 32'h00000000;
			csr_addr_EX				<= 12'h000;
			csr_rena_EX				<= 1'b0;
			csr_wena_EX				<= 1'b0;
			csr_wdata_EX			<= 32'h00000000;
			wb_src_EX				<= 3'd0;
			mem_op_EX				<= 3'd0;
			csr_op_EX				<= 2'd0;
			fpu_flags_EX			<= 5'b00000;
			jump_ena_EX				<= 1'b0;
			jump_alw_EX				<= 1'b0;
			jump_taken_EX			<= 1'b0;
			jump_mpred_EX			<= 1'b0;
			jump_addr_EX			<= 32'h00000000;
			trap_taken_EX			<= 1'b0;
			trap_cause_EX			<= 32'h00000000;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid_int	<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wstrb			<= 4'b0000;
			dmem_axi_wvalid_int		<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid_int	<= 1'b0;
		end

		else if (valid_in && ready_out) begin
			valid_out_int			<= 1'b1;
			PC_EX					<= PC_ID;
			IR_EX					<= IR_ID;
			IM_EX					<= IM_ID;
			rd_wena_EX				<= rd_wena_ID;
			rd_addr_EX				<= rd_addr_ID;
			rd_data_EX				<= 32'h00000000;
			csr_addr_EX				<= csr_addr_ID;
			csr_rena_EX				<= csr_rena_ID;
			csr_wena_EX				<= csr_wena_ID;
			csr_wdata_EX			<= csr_wdata;
			wb_src_EX				<= wb_src_ID;
			mem_op_EX				<= mem_op_ID;
			fpu_flags_EX			<= fpu_flags;
			jump_ena_EX				<= jump_ena_ID;
			jump_alw_EX				<= jump_alw_ID;
			jump_taken_EX			<= jump_taken;
			jump_mpred_EX			<= jump_mpred;
			jump_addr_EX			<= jump_addr;
			trap_taken_ID			<= trap_taken;
			trap_cause_ID			<= trap_cause;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid_int	<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wstrb			<= 4'b0000;
			dmem_axi_wvalid_int		<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid_int	<= 1'b0;

			case (wb_src_ID)
			SEL_MEM:	begin
							// dmem read access (load)
							if (rd_wena_ID) begin
								dmem_axi_araddr			<= alu_out;
								dmem_axi_arprot			<= 3'b010;
								dmem_axi_arvalid_int	<= 1'b1;
							end
							// dmem write access (store)
							else begin
								dmem_axi_awaddr			<= alu_out;
								dmem_axi_awprot			<= 3'b010;
								dmem_axi_awvalid_int	<= 1'b1;
								dmem_axi_wdata			<= dmem_axi_wdata_int;
								dmem_axi_wstrb			<= dmem_axi_wstrb_int;
								dmem_axi_wvalid_int		<= 1'b1;
							end
						end
			SEL_MUL:	rd_data_EX	<= mul_out;
			SEL_DIV:	rd_data_EX	<= div_out;
			SEL_FPU:	rd_data_EX	<= fpu_out;
			default:	rd_data_EX	<= alu_out;
			endcase
		end

		else if (valid_out_int && ready_in) begin
			valid_out_int			<= 1'b0;
			PC_EX					<= 32'h00000000;
			IR_EX					<= 32'h00000000;
			IM_EX					<= 32'h00000000;
			rd_wena_EX				<= 1'b0;
			rd_addr_EX				<= 6'd0;
			rd_data_EX				<= 32'h00000000;
			csr_addr_EX				<= 12'h000;
			csr_rena_EX				<= 1'b0;
			csr_wena_EX				<= 1'b0;
			csr_wdata_EX			<= 32'h00000000;
			wb_src_EX				<= 3'd0;
			mem_op_EX				<= 3'd0;
			csr_op_EX				<= 2'd0;
			fpu_flags_EX			<= 5'b00000;
			jump_ena_EX				<= 1'b0;
			jump_alw_EX				<= 1'b0;
			jump_taken_EX			<= 1'b0;
			jump_mpred_EX			<= 1'b0;
			jump_addr_EX			<= 32'h00000000;
			trap_taken_EX			<= 1'b0;
			trap_cause_EX			<= 32'h00000000;
			dmem_axi_awaddr			<= 32'h00000000;
			dmem_axi_awprot			<= 3'b000;
			dmem_axi_awvalid		<= 1'b0;
			dmem_axi_wdata			<= 32'h00000000;
			dmem_axi_wstrb			<= 4'b0000;
			dmem_axi_wvalid			<= 1'b0;
			dmem_axi_araddr			<= 32'h00000000;
			dmem_axi_arprot			<= 3'b000;
			dmem_axi_arvalid		<= 1'b0;
		end

		else begin
			if (dmem_axi_awvalid_int && dmem_axi_awready)
				dmem_axi_awvalid_int	<= 1'b0;

			if (dmem_axi_wvalid_int  && dmem_axi_wready)
				dmem_axi_wvalid_int		<= 1'b0;

			if (dmem_axi_arvalid_int && dmem_axi_arready)
				dmem_axi_arvalid_int	<= 1'b0;
		end
	end

	ALU ALU_inst
	(
		.op(alu_op_ID),

		.a(a),
		.b(b),

		.y(alu_out)
	);

	int_multiplier #(32, 8) int_multiplier_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(flush),
		
		.valid_in(valid_in_mul),
		.ready_out(ready_out_mul),
		.valid_out(valid_out_mul),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(mul_op_ID),

		.a(a),
		.b(b),

		.y(mul_out)
	);

	int_divider #(32, 2) int_divider_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(flush),

		.valid_in(valid_in_div),
		.ready_out(ready_out_div),
		.valid_out(valid_out_div),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(div_op_ID),

		.a(a),
		.b(b),

		.y(div_out)
	);

	FPU FPU_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(flush),

		.valid_in(valid_in_fpu),
		.ready_out(ready_out_fpu),
		.valid_out(valid_out_fpu),
		.ready_in(ready_in && !rd_after_ld_hazard),

		.op(fpu_op_ID),
		.rm(fpu_rm_ID == FPU_RM_DYN ? frm : fpu_rm_ID),

		.a(a),
		.b(b),
		.c(c),

		.result(fpu_out),

		.IV(fpu_flags[4]),
		.DZ(fpu_flags[3]),
		.OF(fpu_flags[2]),
		.UF(fpu_flags[1]),
		.IE(fpu_flags[0])
	);

endmodule