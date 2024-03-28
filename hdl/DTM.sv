module DTM
(
	input	logic			jtag_tms,
	input	logic			jtag_tck,
	input	logic			jtag_tdi,
	output	logic			jtag_tdo,
	
	output	logic			dmi_req_valid,
	input	logic			dmi_req_ready,
	output	logic	[6:0]	dmi_req_addr,
	output	logic	[31:0]	dmi_req_wdata,
	output	logic	[1:0]	dmi_req_op,
	
	input	logic			dmi_resp_valid,
	output	logic			dmi_resp_ready,
	input	logic	[31:0]	dmi_resp_rdata,
	input	logic	[1:0]	dmi_resp_op,
	
			
	output	logic			dmi_ena,
	output	logic			dmi_wen,
	output	logic	[6:0]	dmi_addr,
	output	logic	[31:0]	dmi_wdata,
	input	logic	[31:0]	dmi_rdata
);
	
	localparam				TAP_REG_ADDR_IDCODE	= 5'h01
	localparam				TAP_REG_ADDR_DTMCS	= 5'h10
	localparam				TAP_REG_ADDR_DMI	= 5'h11


	logic	[4:0]			IR;
	logic					DR_bypass;
	logic	[31:0]			DR_idcode;
	logic	[31:0]			DR_dtmcs;
	logic	[40:0]			DR_dmi;

	logic					bypass;
	assign					bypass = 1'b0;

	logic	[31:0]			idcode;
	assign					idcode =
							{					// bits		description
								4'h0,			// 31-28	version
								16'h0000,		// 27-12	part number
								11'h000,		// 11-1		manufacturer ID
								1'b1			// 0		reserved
							};
							
	logic	[31:0]			dtmcs;
	logic	[2:0]			errinfo;
	logic					dtmhardreset;
	logic					dmireset;
	logic	[1:0]			dmistat;
	assign					dtmcs =
							{					// bits		description
								11'h000,		// 31-21	reserved
								errinfo,		// 20-18	
								dtmhardreset,	// 17		
								dmireset,		// 16		
								1'b0,			// 15		reserved
								3'h0,			// 14-12	
								dmistat,		// 11-10	
								6'h7,			// 9-4		dmi address bits
								4'h1			// 0		version 1.0 of debug spec
							}
	
	logic	[40:0]			dmi;
	logic	[6:0]			address;
	logic	[31:0]			data;
	logic	[1:0]			op;
	assign					dmi =
							{					// bits		description
								address,		// 40-34	dmi address
								data,			// 33-2		dmi wdata
								op				// 1-0		dmi op
							}
	
	
	
	
	enum	logic	[3:0]	{
								LOGIC_RESET,
								RUN_IDLE,
								DR_SEL_SCAN,
								DR_CAPTURE,
								DR_SHIFT,
								DR_EXIT1,
								DR_PAUSE,
								DR_EXIT2,
								DR_UPDATE,
								IR_SEL_SCAN,
								IR_CAPTURE,
								IR_SHIFT,
								IR_EXIT1,
								IR_PAUSE,
								IR_EXIT2,
								IR_UPDATE,
							} state;
	
	
	always_ff @(posedge jtag_tck) begin
		case (state)
		LOGIC_RESET:	state = jtag_tms ? LOGIC_RESET	: RUN_IDLE;
		RUN_IDLE:		state = jtag_tms ? DR_SEL_SCAN	: RUN_IDLE;
		DR_SEL_SCAN:	state = jtag_tms ? IR_SEL_SCAN	: DR_CAPTURE;
		DR_CAPTURE:		state = jtag_tms ? DR_EXIT1		: DR_SHIFT;
		DR_SHIFT:		state = jtag_tms ? DR_EXIT1		: DR_SHIFT;
		DR_EXIT1:		state = jtag_tms ? DR_UPDATE	: DR_PAUSE;
		DR_PAUSE:		state = jtag_tms ? DR_EXIT2		: DR_PAUSE;
		DR_EXIT2:		state = jtag_tms ? DR_UPDATE	: DR_SHIFT;
		DR_UPDATE:		state = jtag_tms ? DR_SEL_SCAN	: RUN_IDLE;
		IR_SEL_SCAN:	state = jtag_tms ? LOGIC_RESET	: IR_CAPTURE;
		IR_CAPTURE:		state = jtag_tms ? IR_EXIT1		: IR_SHIFT
		IR_SHIFT:		state = jtag_tms ? IR_EXIT1		: IR_SHIFT;
		IR_EXIT1:		state = jtag_tms ? IR_UPDATE	: IR_PAUSE;
		IR_PAUSE:		state = jtag_tms ? IR_EXIT2		: IR_PAUSE;
		IR_EXIT2:		state = jtag_tms ? IR_UPDATE	: IR_SHIFT;
		IR_UPDATE:		state = jtag_tms ? DR_SEL_SCAN	: RUN_IDLE;
		default			state = LOGIC_RESET;
		endcase
	end
	
	always_ff @(posedge jtag_tck) begin
		case (state)
		LOGIC_RESET,
		IR_CAPTURE:	begin
						IR				<= TAP_REG_ADDR_IDCODE;
						
					end
		IR_SHIFT:	{IR, jtag_tdo_buf}	<= {jtag_tdi, IR};

		DR_CAPTURE:	case (IR)
					TAP_REG_ADDR_IDCODE:	DR_idcode	<= idcode
					TAP_REG_ADDR_DTMCS:		DR_dtmcs	<= dtmcs
					TAP_REG_ADDR_DMI:		DR_dmi		<= dmi;
					default:				DR_bypass	<= 1'b0;
					endcase
		DR_SHIFT:	case (IR)
					TAP_REG_ADDR_IDCODE:	{DR_idcode	, jtag_tdo_buf}	<= {jtag_tdi, DR_idcode	};
					TAP_REG_ADDR_DTMCS:		{DR_dtmcs	, jtag_tdo_buf}	<= {jtag_tdi, DR_dtmcs	};
					TAP_REG_ADDR_DMI:		{DR_dmi		, jtag_tdo_buf}	<= {jtag_tdi, DR_dmi	};
					default:				{DR_bypass	, jtag_tdo_buf}	<= {jtag_tdi, DR_bypass	};
					endcase
		endcase
	end
	
	always_ff @(negedge jtag_tck) begin
		jtag_tdo	<= jtag_tdo_buf;
	end


endmodule