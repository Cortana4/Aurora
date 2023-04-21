module bypass_logic
(
	input	logic			rs1_rena_ID,
	input	logic	[5:0]	rs1_addr_ID,
	input	logic	[31:0]	rs1_data_ID,
	input	logic			rs2_rena_ID,
	input	logic	[5:0]	rs2_addr_ID,
	input	logic	[31:0]	rs2_data_ID,
	input	logic			rs3_rena_ID,
	input	logic	[5:0]	rs3_addr_ID,
	input	logic	[31:0]	rs3_data_ID,

	input	logic			rd_wena_EX,
	input	logic	[5:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic	[2:0]	wb_src_EX,

	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,

	output	logic	[31:0]	rs1_data,
	output	logic	[31:0]	rs2_data,
	output	logic	[31:0]	rs3_data,
	output	logic			rd_after_ld_hazard
);

	logic	bypass_rs1_EX;
	logic	bypass_rs1_MEM;

	logic	bypass_rs2_EX;
	logic	bypass_rs2_MEM;

	logic	bypass_rs3_EX;
	logic	bypass_rs3_MEM;

	assign	bypass_rs1_EX		= rs1_rena_ID && |rs1_addr_ID && rd_wena_EX  && rs1_addr_ID == rd_addr_EX;
	assign	bypass_rs1_MEM		= rs1_rena_ID && |rs1_addr_ID && rd_wena_MEM && rs1_addr_ID == rd_addr_MEM;

	assign	bypass_rs2_EX		= rs2_rena_ID && |rs2_addr_ID && rd_wena_EX  && rs2_addr_ID == rd_addr_EX;
	assign	bypass_rs2_MEM		= rs2_rena_ID && |rs2_addr_ID && rd_wena_MEM && rs2_addr_ID == rd_addr_MEM;

	assign	bypass_rs3_EX		= rs3_rena_ID && |rs3_addr_ID && rd_wena_EX  && rs3_addr_ID == rd_addr_EX;
	assign	bypass_rs3_MEM		= rs3_rena_ID && |rs3_addr_ID && rd_wena_MEM && rs3_addr_ID == rd_addr_MEM;

	assign	rd_after_ld_hazard	= (bypass_rs1_EX || bypass_rs2_EX || bypass_rs3_EX) && wb_src_EX == SEL_MEM;

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
			rs3_data	= rs1_data_ID;
	end

endmodule
