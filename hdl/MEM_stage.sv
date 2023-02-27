`include "AmberFive_constants.svh"

module MEM_stage
(
	input	logic			clk,
	input	logic			reset,
	
	input	logic			valid_in,
	output	logic			ready_out,
	
	output	logic			valid_out,
	input	logic			ready_in,
	
	input	logic	[31:0]	PC_EX,
	input	logic	[31:0]	IR_EX,
	input	logic	[31:0]	IM_EX,
	input	logic	[5:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic			rd_access_EX,
	input	logic	[2:0]	MEM_op_EX,
	input	logic			dmem_access_EX,
	input	logic			illegal_inst_EX,
	input	logic			misaligned_addr_EX,
	
	// read address channel
	input	logic	[31:0]	dmem_axi_araddr,
	
	// write response channel
	output	logic			dmem_axi_bready,
	input	logic	[1:0]	dmem_axi_bresp,
	input	logic			dmem_axi_bvalid,
	// read data channel
	input	logic	[31:0]	dmem_axi_rdata,
	output	logic			dmem_axi_rready,
	input	logic	[1:0]	dmem_axi_rresp,
	input	logic			dmem_axi_rvalid,
	
	output	logic	[31:0]	PC_MEM,
	output	logic	[31:0]	IR_MEM,
	output	logic	[31:0]	IM_MEM,
	output	logic	[5:0]	rd_addr_MEM,
	output	logic	[31:0]	rd_data_MEM,
	output	logic			rd_access_MEM,
	output	logic			illegal_inst_MEM,
	output	logic			misaligned_addr_MEM,
	output	logic	[1:0]	dmem_axi_bresp_MEM,
	output	logic	[1:0]	dmem_axi_rresp_MEM
);

	logic			stall;
	
	logic	[31:0]	dmem_axi_rdata_aligned;
	assign			dmem_axi_rdata_aligned	= dmem_axi_rdata >> dmem_axi_araddr[1:0];
	
	assign			dmem_axi_bready			= ready_in;
	assign			dmem_axi_rready			= ready_in;
	
	assign			ready_out				= ready_in && !stall;
	assign			stall					= dmem_access_EX && ((rd_access_EX && !dmem_axi_rvalid) || (!rd_access_EX && !dmem_axi_bvalid));

	// MEM/WB pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			valid_out			<= 1'b0;
			PC_MEM				<= 32'h00000000;
			IR_MEM				<= 32'h00000000;
			IM_MEM				<= 32'h00000000;
			rd_addr_MEM			<= 4'h0;
			rd_data_MEM			<= 32'h00000000;
			rd_access_MEM		<= 1'b0;
			illegal_inst_MEM	<= 1'b0;
			misaligned_addr_MEM	<= 1'b0;
			dmem_axi_bresp_MEM	<= 2'b00;
			dmem_axi_rresp_MEM	<= 2'b00;
		end
		
		else if (valid_in && ready_out) begin
			valid_out			<= 1'b1;
			PC_MEM				<= PC_EX;
			IR_MEM				<= IR_EX;
			IM_MEM				<= IM_EX;
			rd_addr_MEM			<= rd_addr_EX;
			rd_data_MEM			<= rd_data_EX;
			rd_access_MEM		<= rd_access_EX;
			illegal_inst_MEM	<= illegal_inst_EX;
			misaligned_addr_MEM	<= misaligned_addr_EX;
			dmem_axi_bresp_MEM	<= 2'b00;
			dmem_axi_rresp_MEM	<= 2'b00;
			
			if (dmem_access_EX) begin
				// dmem read access (load)
				if (rd_access_EX) begin
					case (MEM_op_EX)
					`MEM_LB:	rd_data_MEM	<= dmem_axi_rdata_aligned | {24{dmem_axi_rdata_aligned[7]}};
					`MEM_LH:	rd_data_MEM	<= dmem_axi_rdata_aligned | {16{dmem_axi_rdata_aligned[15]}};
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
			valid_out			<= 1'b0;
			PC_MEM				<= 32'h00000000;
			IR_MEM				<= 32'h00000000;
			IM_MEM				<= 32'h00000000;
			rd_addr_MEM			<= 4'h0;
			rd_data_MEM			<= 32'h00000000;
			rd_access_MEM		<= 1'b0;
			illegal_inst_MEM	<= 1'b0;
			misaligned_addr_MEM	<= 1'b0;
			dmem_axi_bresp_MEM	<= 2'b00;
			dmem_axi_rresp_MEM	<= 2'b00;
		end
	end
	
endmodule