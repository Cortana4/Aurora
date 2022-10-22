module reg_file
(
	input	logic			clk,
	input	logic			reset,

	input	logic			rd_wena,
	input	logic	[4:0]	rd_addr,
	input	logic	[31:0]	rd_data,

	input	logic			rs1_rena,
	input	logic	[4:0]	rs1_addr,
	output	logic	[31:0]	rs1_data,

	input	logic			rs2_rena,
	input	logic	[4:0]	rs2_addr,
	output	logic	[31:0]	rs2_data
);
	// registers[0] is nullptr
	logic	[31:0]	registers [31:1];

	assign			rs1_data	= rs1_rena && |rs1_addr ? registers[rs1_addr] : 32'h00000000;
	assign			rs2_data	= rs2_rena && |rs2_addr ? registers[rs2_addr] : 32'h00000000;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			for (integer i = 1; i <= 31; i = i + 1)
				registers[i]	<= 32'h00000000;
		end

		else if (|rd_addr && rd_wena)
			registers[rd_addr]	<= rd_data;
	end

endmodule