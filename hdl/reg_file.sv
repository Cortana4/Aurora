module reg_file
(
	input	logic			clk,

	input	logic			rd_wena,
	input	logic	[5:0]	rd_addr,
	input	logic	[31:0]	rd_data,

	input	logic			rs1_rena,
	input	logic	[5:0]	rs1_addr,
	output	logic	[31:0]	rs1_data,

	input	logic			rs2_rena,
	input	logic	[5:0]	rs2_addr,
	output	logic	[31:0]	rs2_data,
	
	input	logic			rs3_rena,
	input	logic	[5:0]	rs3_addr,
	output	logic	[31:0]	rs3_data
);
	// registers[0] is nullptr
	logic	[31:0]	registers [63:1];

	assign			rs1_data	= rs1_rena && |rs1_addr ? registers[rs1_addr] : 32'h00000000;
	assign			rs2_data	= rs2_rena && |rs2_addr ? registers[rs2_addr] : 32'h00000000;
	assign			rs3_data	= rs3_rena && |rs3_addr ? registers[rs3_addr] : 32'h00000000;

	always_ff @(posedge clk) begin
		if (|rd_addr && rd_wena)
			registers[rd_addr]	<= rd_data;
	end

endmodule