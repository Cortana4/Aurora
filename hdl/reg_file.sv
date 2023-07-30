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

	// rs1 port
	always_comb begin
		rs1_data	= 32'h00000000;

		if (rs1_rena && |rs1_addr) begin
			// bypass rd_data (write first)
			if (rd_wena && (rs1_addr == rd_addr))
				rs1_data	= rd_data;
			else
				rs1_data	= registers[rs1_addr];
		end
	end

	// rs2 port
	always_comb begin
		rs2_data	= 32'h00000000;

		if (rs2_rena && |rs2_addr) begin
			// bypass rd_data (write first)
			if (rd_wena && (rs2_addr == rd_addr))
				rs2_data	= rd_data;
			else
				rs2_data	= registers[rs2_addr];
		end
	end

	// rs3 port
	always_comb begin
		rs3_data	= 32'h00000000;

		if (rs3_rena && |rs3_addr) begin
			// bypass rd_data (write first)
			if (rd_wena && (rs3_addr == rd_addr))
				rs3_data	= rd_data;
			else
				rs3_data	= registers[rs3_addr];
		end
	end

	always_ff @(posedge clk) begin
		if (|rd_addr && rd_wena)
			registers[rd_addr]	<= rd_data;
	end

endmodule