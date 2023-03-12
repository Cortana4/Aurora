import CPU_pkg::*;

module MEM_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			valid_out,
	input	logic			ready_in,
	
	// write response channel
	input	logic	[1:0]	dmem_axi_bresp,
	input	logic			dmem_axi_bvalid,
	output	logic			dmem_axi_bready,
	// read address channel
	input	logic	[31:0]	dmem_axi_araddr,
	// read data channel
	input	logic	[31:0]	dmem_axi_rdata,
	input	logic	[1:0]	dmem_axi_rresp,
	input	logic			dmem_axi_rvalid,
	output	logic			dmem_axi_rready,

	input	logic	[31:0]	PC_EX,
	input	logic	[31:0]	IR_EX,
	input	logic	[31:0]	IM_EX,
	input	logic	[5:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic			rd_access_EX,
	input	logic	[2:0]	wb_src_EX,
	input	logic	[2:0]	MEM_op_EX,
	input	logic	[1:0]	imem_axi_rresp_EX,
	input	logic			illegal_inst_EX,
	input	logic			maligned_inst_addr_EX,
	input	logic			maligned_load_addr_EX,
	input	logic			maligned_store_addr_EX,

	output	logic	[31:0]	PC_MEM,
	output	logic	[31:0]	IR_MEM,
	output	logic	[31:0]	IM_MEM,
	output	logic	[5:0]	rd_addr_MEM,
	output	logic	[31:0]	rd_data_MEM,
	output	logic			rd_access_MEM,
	// exceptions
	output	logic	[1:0]	imem_axi_rresp_MEM,
	output	logic			illegal_inst_MEM,
	output	logic			maligned_inst_addr_MEM,
	output	logic			maligned_load_addr_MEM,
	output	logic			maligned_store_addr_MEM,
	output	logic	[1:0]	dmem_axi_bresp_MEM,
	output	logic	[1:0]	dmem_axi_rresp_MEM
);

	logic			stall;

	logic	[31:0]	dmem_axi_rdata_aligned;
	assign			dmem_axi_rdata_aligned	= dmem_axi_rdata >> dmem_axi_araddr[1:0];

	assign			dmem_axi_bready			= ready_in;
	assign			dmem_axi_rready			= ready_in;

	assign			ready_out				= ready_in && !stall;
	assign			stall					= wb_src_EX == SEL_MEM && ((rd_access_EX && !dmem_axi_rvalid) || (!rd_access_EX && !dmem_axi_bvalid));

	// MEM/WB pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out				<= 1'b0;
			PC_MEM					<= 32'h00000000;
			IR_MEM					<= 32'h00000000;
			IM_MEM					<= 32'h00000000;
			rd_addr_MEM				<= 6'd0;
			rd_data_MEM				<= 32'h00000000;
			rd_access_MEM			<= 1'b0;
			imem_axi_rresp_MEM		<= 2'b00;
			illegal_inst_MEM		<= 1'b0;
			maligned_inst_addr_MEM	<= 1'b0;
			maligned_load_addr_MEM	<= 1'b0;
			maligned_store_addr_MEM	<= 1'b0;
			dmem_axi_bresp_MEM		<= 2'b00;
			dmem_axi_rresp_MEM		<= 2'b00;
		end

		else if (valid_in && ready_out) begin
			valid_out				<= 1'b1;
			PC_MEM					<= PC_EX;
			IR_MEM					<= IR_EX;
			IM_MEM					<= IM_EX;
			rd_addr_MEM				<= rd_addr_EX;
			rd_data_MEM				<= rd_data_EX;
			rd_access_MEM			<= rd_access_EX;
			imem_axi_rresp_MEM		<= imem_axi_rresp_EX;
			illegal_inst_MEM		<= illegal_inst_EX;
			maligned_inst_addr_MEM	<= maligned_inst_addr_EX;
			maligned_load_addr_MEM	<= maligned_load_addr_EX;
			maligned_store_addr_MEM	<= maligned_store_addr_EX;
			dmem_axi_bresp_MEM		<= 2'b00;
			dmem_axi_rresp_MEM		<= 2'b00;

			if (wb_src_EX == SEL_MEM) begin
				// dmem read access (load)
				if (rd_access_EX) begin
					case (MEM_op_EX)
					MEM_LB:		rd_data_MEM	<= dmem_axi_rdata_aligned | {24{dmem_axi_rdata_aligned[7]}};
					MEM_LH:		rd_data_MEM	<= dmem_axi_rdata_aligned | {16{dmem_axi_rdata_aligned[15]}};
					default:	rd_data_MEM	<= dmem_axi_rdata_aligned;
					endcase

					dmem_axi_rresp_MEM	<= dmem_axi_rresp;
				end
				// dmem write access (store)
				else begin
					rd_data_MEM			<= 32'h00000000;
					dmem_axi_bresp_MEM	<= dmem_axi_bresp;
				end
			end
		end

		else if (valid_out && ready_in) begin
			valid_out				<= 1'b0;
			PC_MEM					<= 32'h00000000;
			IR_MEM					<= 32'h00000000;
			IM_MEM					<= 32'h00000000;
			rd_addr_MEM				<= 6'd0;
			rd_data_MEM				<= 32'h00000000;
			rd_access_MEM			<= 1'b0;
			imem_axi_rresp_MEM		<= 2'b00;
			illegal_inst_MEM		<= 1'b0;
			maligned_inst_addr_MEM	<= 1'b0;
			maligned_load_addr_MEM	<= 1'b0;
			maligned_store_addr_MEM	<= 1'b0;
			dmem_axi_bresp_MEM		<= 2'b00;
			dmem_axi_rresp_MEM		<= 2'b00;
		end
	end

endmodule