import CPU_pkg::*;
import FPU_pkg::*;

module EX_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			flush_out,
	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,

	input	logic			valid_in_mul,
	output	logic			ready_out_mul,
	input	logic			valid_in_div,
	output	logic			ready_out_div,
	input	logic			valid_in_fpu,
	output	logic			ready_out_fpu,

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
	input	logic			trap_ret_ID,
	input	logic			exc_pend_ID,
	input	logic	[31:0]	exc_cause_ID,

	output	logic	[31:0]	PC_EX,
	output	logic	[31:0]	IR_EX,
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
	output	logic			trap_ret_EX,
	output	logic			exc_pend_EX,
	output	logic	[31:0]	exc_cause_EX,

	output	logic	[31:0]	PC_EX_buf,
	output	logic	[31:0]	IR_EX_buf,
	output	logic			rd_wena_EX_buf,
	output	logic	[5:0]	rd_addr_EX_buf,
	output	logic	[31:0]	rd_data_EX_buf,
	output	logic	[11:0]	csr_addr_EX_buf,
	output	logic			csr_rena_EX_buf,
	output	logic			csr_wena_EX_buf,
	output	logic	[31:0]	csr_wdata_EX_buf,
	output	logic	[2:0]	wb_src_EX_buf,
	output	logic	[2:0]	mem_op_EX_buf,
	output	logic	[1:0]	csr_op_EX_buf,
	output	logic	[4:0]	fpu_flags_EX_buf,
	output	logic			jump_ena_EX_buf,
	output	logic			jump_alw_EX_buf,
	output	logic			jump_taken_EX_buf,
	output	logic			jump_mpred_EX_buf,
	output	logic	[31:0]	jump_addr_EX_buf,
	output	logic			trap_ret_EX_buf,
	output	logic			exc_pend_EX_buf,
	output	logic	[31:0]	exc_cause_EX_buf,

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
	input	logic	[31:0]	rd_data_MEM,

	input	logic			rd_wena_MEM_buf,
	input	logic	[5:0]	rd_addr_MEM_buf,
	input	logic	[31:0]	rd_data_MEM_buf,

	input	logic	[2:0]	fpu_rm_csr,
	input	logic			int_taken_csr
);

	logic	[31:0]	rs1_data;
	logic	[31:0]	rs2_data;
	logic	[31:0]	rs3_data;

	logic	[31:0]	csr_wdata;
	logic	[31:0]	a;
	logic	[31:0]	b;
	logic	[31:0]	c;

	logic			jump_taken;
	logic			jump_mpred;
	logic	[31:0]	jump_addr;

	logic			dmem_axi_awvalid_int;
	logic	[31:0]	dmem_axi_wdata_int;
	logic	[3:0]	dmem_axi_wstrb_int;
	logic			dmem_axi_wvalid_int;
	logic			dmem_axi_arvalid_int;

	logic	[31:0]	dmem_axi_awaddr_buf;
	logic	[2:0]	dmem_axi_awprot_buf;
	logic			dmem_axi_awvalid_buf;
	logic	[31:0]	dmem_axi_wdata_buf;
	logic	[3:0]	dmem_axi_wstrb_buf;
	logic			dmem_axi_wvalid_buf;
	logic	[31:0]	dmem_axi_araddr_buf;
	logic	[2:0]	dmem_axi_arprot_buf;
	logic			dmem_axi_arvalid_buf;

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

	logic			exc_pend;
	logic	[31:0]	exc_cause;

	logic			rd_after_ld_hazard;
	logic			valid_out_buf;
	logic			stall;

	assign			csr_wdata			= sel_IM_ID ? IM_ID : rs1_data;
	assign			a					= sel_PC_ID ? PC_ID : rs1_data;
	assign			b					= sel_IM_ID ? IM_ID : rs2_data;
	assign			c					= rs3_data;

	assign			jump_taken			= jump_ena_ID && (jump_alw_ID || alu_out[0]);
	assign			jump_mpred			= jump_ena_ID && jump_pred_ID != jump_taken;
	assign			maligned_inst_addr	= jump_taken  && |jump_addr[1:0];

	assign			dmem_axi_awvalid	= dmem_axi_awvalid_int && !exc_pend_EX && !flush_in;
	assign			dmem_axi_wvalid		= dmem_axi_wvalid_int  && !exc_pend_EX && !flush_in;
	assign			dmem_axi_arvalid	= dmem_axi_arvalid_int && !exc_pend_EX && !flush_in;

	assign			ready_out			= !valid_out_buf && !stall;
	assign			flush_out			= flush_in || jump_mpred_EX || int_taken_csr;
	assign			stall				= exc_pend_EX || csr_wena_EX || csr_rena_EX || flush_out ||
										  (!exc_pend_ID && (rd_after_ld_hazard ||
										  (wb_src_ID == SEL_MUL && !valid_out_mul) ||
										  (wb_src_ID == SEL_DIV && !valid_out_div) ||
										  (wb_src_ID == SEL_FPU && !valid_out_fpu)));

	// jump address computation
	always_comb begin
		if (!jump_taken)
			jump_addr	= PC_ID + 32'd4;

		else if (jump_ind_ID)
			jump_addr	= (rs1_data + IM_ID) & 32'hfffffffe;

		else
			jump_addr	= PC_ID + IM_ID;
	end

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
		if (exc_pend_ID) begin
			exc_pend	= 1'b1;
			exc_cause	= exc_cause_ID;
		end

		else if (maligned_inst_addr) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_MISALIGNED_INST;
		end

		else if (maligned_load_addr) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_MISALIGNED_LOAD;
		end

		else if (maligned_store_addr) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_MISALIGNED_STORE;
		end

		else begin
			exc_pend	= 1'b0;
			exc_cause	= 32'h00000000;
		end
	end

	// EX/MEM pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush_in) begin
			{PC_EX					, PC_EX_buf				}	<= {2{32'h00000000	}};
			{IR_EX					, IR_EX_buf				}	<= {2{32'h00000000	}};
			{rd_wena_EX				, rd_wena_EX_buf		}	<= {2{1'b0			}};
			{rd_addr_EX				, rd_addr_EX_buf		}	<= {2{6'd0			}};
			{rd_data_EX				, rd_data_EX_buf		}	<= {2{32'h00000000	}};
			{csr_addr_EX			, csr_addr_EX_buf		}	<= {2{12'h000		}};
			{csr_rena_EX			, csr_rena_EX_buf		}	<= {2{1'b0			}};
			{csr_wena_EX			, csr_wena_EX_buf		}	<= {2{1'b0			}};
			{csr_wdata_EX			, csr_wdata_EX_buf		}	<= {2{32'h00000000	}};
			{wb_src_EX				, wb_src_EX_buf			}	<= {2{3'd0			}};
			{mem_op_EX				, mem_op_EX_buf			}	<= {2{3'd0			}};
			{csr_op_EX				, csr_op_EX_buf			}	<= {2{2'd0			}};
			{fpu_flags_EX			, fpu_flags_EX_buf		}	<= {2{5'b00000		}};
			{jump_ena_EX			, jump_ena_EX_buf		}	<= {2{1'b0			}};
			{jump_alw_EX			, jump_alw_EX_buf		}	<= {2{1'b0			}};
			{jump_taken_EX			, jump_taken_EX_buf		}	<= {2{1'b0			}};
			{jump_mpred_EX			, jump_mpred_EX_buf		}	<= {2{1'b0			}};
			{jump_addr_EX			, jump_addr_EX_buf		}	<= {2{32'h00000000	}};
			{trap_ret_EX			, trap_ret_EX_buf		}	<= {2{1'b0			}};
			{exc_pend_EX			, exc_pend_EX_buf		}	<= {2{1'b0			}};
			{exc_cause_EX			, exc_cause_EX_buf		}	<= {2{32'h00000000	}};
			{dmem_axi_awaddr		, dmem_axi_awaddr_buf	}	<= {2{32'h00000000	}};
			{dmem_axi_awprot		, dmem_axi_awprot_buf	}	<= {2{3'b000		}};
			{dmem_axi_awvalid_int	, dmem_axi_awvalid_buf	}	<= {2{1'b0			}};
			{dmem_axi_wdata			, dmem_axi_wdata_buf	}	<= {2{32'h00000000	}};
			{dmem_axi_wstrb			, dmem_axi_wstrb_buf	}	<= {2{4'b0000		}};
			{dmem_axi_wvalid_int	, dmem_axi_wvalid_buf	}	<= {2{1'b0			}};
			{dmem_axi_araddr		, dmem_axi_araddr_buf	}	<= {2{32'h00000000	}};
			{dmem_axi_arprot		, dmem_axi_arprot_buf	}	<= {2{3'b000		}};
			{dmem_axi_arvalid_int	, dmem_axi_arvalid_buf	}	<= {2{1'b0			}};
			{valid_out				, valid_out_buf			}	<= {2{1'b0			}};
		end

		else if (!valid_out_buf) begin
			// input to output
			if (valid_in && (ready_in || !valid_out) && !stall) begin
				PC_EX					<= PC_ID;
				IR_EX					<= IR_ID;
				rd_wena_EX				<= rd_wena_ID;
				rd_addr_EX				<= rd_addr_ID;
				rd_data_EX				<= 32'h00000000;
				csr_addr_EX				<= csr_addr_ID;
				csr_rena_EX				<= csr_rena_ID;
				csr_wena_EX				<= csr_wena_ID;
				csr_wdata_EX			<= csr_wdata;
				wb_src_EX				<= wb_src_ID;
				mem_op_EX				<= mem_op_ID;
				csr_op_EX				<= csr_op_ID;
				fpu_flags_EX			<= fpu_flags;
				jump_ena_EX				<= jump_ena_ID;
				jump_alw_EX				<= jump_alw_ID;
				jump_taken_EX			<= jump_taken;
				jump_mpred_EX			<= jump_mpred;
				jump_addr_EX			<= jump_addr;
				trap_ret_EX				<= trap_ret_ID;
				exc_pend_EX				<= exc_pend;
				exc_cause_EX			<= exc_cause;
				dmem_axi_awaddr			<= 32'h00000000;
				dmem_axi_awprot			<= 3'b000;
				dmem_axi_awvalid_int	<= 1'b0;
				dmem_axi_wdata			<= 32'h00000000;
				dmem_axi_wstrb			<= 4'b0000;
				dmem_axi_wvalid_int		<= 1'b0;
				dmem_axi_araddr			<= 32'h00000000;
				dmem_axi_arprot			<= 3'b000;
				dmem_axi_arvalid_int	<= 1'b0;
				valid_out				<= 1'b1;

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
			// input to buffer
			else if (valid_in && !stall) begin
				PC_EX_buf				<= PC_ID;
				IR_EX_buf				<= IR_ID;
				rd_wena_EX_buf			<= rd_wena_ID;
				rd_addr_EX_buf			<= rd_addr_ID;
				rd_data_EX_buf			<= 32'h00000000;
				csr_addr_EX_buf			<= csr_addr_ID;
				csr_rena_EX_buf			<= csr_rena_ID;
				csr_wena_EX_buf			<= csr_wena_ID;
				csr_wdata_EX_buf		<= csr_wdata;
				wb_src_EX_buf			<= wb_src_ID;
				mem_op_EX_buf			<= mem_op_ID;
				csr_op_EX_buf			<= csr_op_ID;
				fpu_flags_EX_buf		<= fpu_flags;
				jump_ena_EX_buf			<= jump_ena_ID;
				jump_alw_EX_buf			<= jump_alw_ID;
				jump_taken_EX_buf		<= jump_taken;
				jump_mpred_EX_buf		<= jump_mpred;
				jump_addr_EX_buf		<= jump_addr;
				trap_ret_EX_buf			<= trap_ret_ID;
				exc_pend_EX_buf			<= exc_pend;
				exc_cause_EX_buf		<= exc_cause;
				dmem_axi_awaddr_buf		<= 32'h00000000;
				dmem_axi_awprot_buf		<= 3'b000;
				dmem_axi_awvalid_buf	<= 1'b0;
				dmem_axi_wdata_buf		<= 32'h00000000;
				dmem_axi_wstrb_buf		<= 4'b0000;
				dmem_axi_wvalid_buf		<= 1'b0;
				dmem_axi_araddr_buf		<= 32'h00000000;
				dmem_axi_arprot_buf		<= 3'b000;
				dmem_axi_arvalid_buf	<= 1'b0;
				valid_out_buf			<= 1'b1;

				case (wb_src_ID)
				SEL_MEM:	begin
								// dmem read access (load)
								if (rd_wena_ID) begin
									dmem_axi_araddr_buf		<= alu_out;
									dmem_axi_arprot_buf		<= 3'b010;
									dmem_axi_arvalid_buf	<= 1'b1;
								end
								// dmem write access (store)
								else begin
									dmem_axi_awaddr_buf		<= alu_out;
									dmem_axi_awprot_buf		<= 3'b010;
									dmem_axi_awvalid_buf	<= 1'b1;
									dmem_axi_wdata_buf		<= dmem_axi_wdata_int;
									dmem_axi_wstrb_buf		<= dmem_axi_wstrb_int;
									dmem_axi_wvalid_buf		<= 1'b1;
								end
							end
				SEL_MUL:	rd_data_EX_buf	<= mul_out;
				SEL_DIV:	rd_data_EX_buf	<= div_out;
				SEL_FPU:	rd_data_EX_buf	<= fpu_out;
				default:	rd_data_EX_buf	<= alu_out;
				endcase
			end
			// bubble
			else if (valid_out && ready_in) begin
				PC_EX					<= 32'h00000000;
				IR_EX					<= 32'h00000000;
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
				trap_ret_EX				<= 1'b0;
				exc_pend_EX				<= 1'b0;
				exc_cause_EX			<= 32'h00000000;
				dmem_axi_awaddr			<= 32'h00000000;
				dmem_axi_awprot			<= 3'b000;
				dmem_axi_awvalid_int	<= 1'b0;
				dmem_axi_wdata			<= 32'h00000000;
				dmem_axi_wstrb			<= 4'b0000;
				dmem_axi_wvalid_int		<= 1'b0;
				dmem_axi_araddr			<= 32'h00000000;
				dmem_axi_arprot			<= 3'b000;
				dmem_axi_arvalid_int	<= 1'b0;
				valid_out				<= 1'b0;
			end
		end
		// buffer to output
		else if (ready_in) begin
			{PC_EX					, PC_EX_buf				}	<= {PC_EX_buf			, 32'h00000000	};
			{IR_EX					, IR_EX_buf				}	<= {IR_EX_buf			, 32'h00000000	};
			{rd_wena_EX				, rd_wena_EX_buf		}	<= {rd_wena_EX_buf		, 1'b0			};
			{rd_addr_EX				, rd_addr_EX_buf		}	<= {rd_addr_EX_buf		, 6'd0			};
			{rd_data_EX				, rd_data_EX_buf		}	<= {rd_data_EX_buf		, 32'h00000000	};
			{csr_addr_EX			, csr_addr_EX_buf		}	<= {csr_addr_EX_buf		, 12'h000		};
			{csr_rena_EX			, csr_rena_EX_buf		}	<= {csr_rena_EX_buf		, 1'b0			};
			{csr_wena_EX			, csr_wena_EX_buf		}	<= {csr_wena_EX_buf		, 1'b0			};
			{csr_wdata_EX			, csr_wdata_EX_buf		}	<= {csr_wdata_EX_buf	, 32'h00000000	};
			{wb_src_EX				, wb_src_EX_buf			}	<= {wb_src_EX_buf		, 3'd0			};
			{mem_op_EX				, mem_op_EX_buf			}	<= {mem_op_EX_buf		, 3'd0			};
			{csr_op_EX				, csr_op_EX_buf			}	<= {csr_op_EX_buf		, 2'd0			};
			{fpu_flags_EX			, fpu_flags_EX_buf		}	<= {fpu_flags_EX_buf	, 5'b00000		};
			{jump_ena_EX			, jump_ena_EX_buf		}	<= {jump_ena_EX_buf		, 1'b0			};
			{jump_alw_EX			, jump_alw_EX_buf		}	<= {jump_alw_EX_buf		, 1'b0			};
			{jump_taken_EX			, jump_taken_EX_buf		}	<= {jump_taken_EX_buf	, 1'b0			};
			{jump_mpred_EX			, jump_mpred_EX_buf		}	<= {jump_mpred_EX_buf	, 1'b0			};
			{jump_addr_EX			, jump_addr_EX_buf		}	<= {jump_addr_EX_buf	, 32'h00000000	};
			{trap_ret_EX			, trap_ret_EX_buf		}	<= {trap_ret_EX_buf		, 1'b0			};
			{exc_pend_EX			, exc_pend_EX_buf		}	<= {exc_pend_EX_buf		, 1'b0			};
			{exc_cause_EX			, exc_cause_EX_buf		}	<= {exc_cause_EX_buf	, 32'h00000000	};
			{dmem_axi_awaddr		, dmem_axi_awaddr_buf	}	<= {dmem_axi_awaddr_buf	, 32'h00000000	};
			{dmem_axi_awprot		, dmem_axi_awprot_buf	}	<= {dmem_axi_awprot_buf	, 3'b000		};
			{dmem_axi_awvalid_int	, dmem_axi_awvalid_buf	}	<= {dmem_axi_awvalid_buf, 1'b0			};
			{dmem_axi_wdata			, dmem_axi_wdata_buf	}	<= {dmem_axi_wdata_buf	, 32'h00000000	};
			{dmem_axi_wstrb			, dmem_axi_wstrb_buf	}	<= {dmem_axi_wstrb_buf	, 4'b0000		};
			{dmem_axi_wvalid_int	, dmem_axi_wvalid_buf	}	<= {dmem_axi_wvalid_buf	, 1'b0			};
			{dmem_axi_araddr		, dmem_axi_araddr_buf	}	<= {dmem_axi_araddr_buf	, 32'h00000000	};
			{dmem_axi_arprot		, dmem_axi_arprot_buf	}	<= {dmem_axi_arprot_buf	, 3'b000		};
			{dmem_axi_arvalid_int	, dmem_axi_arvalid_buf	}	<= {dmem_axi_arvalid_buf, 1'b0			};
			{valid_out				, valid_out_buf			}	<= {1'b1				, 1'b0			};
		end

		else begin
			jump_ena_EX				<= 1'b0;

			if (dmem_axi_awvalid_int && dmem_axi_awready)
				dmem_axi_awvalid_int	<= 1'b0;

			if (dmem_axi_wvalid_int  && dmem_axi_wready)
				dmem_axi_wvalid_int		<= 1'b0;

			if (dmem_axi_arvalid_int && dmem_axi_arready)
				dmem_axi_arvalid_int	<= 1'b0;
		end
	end

	bypass_logic bypass_logic_inst
	(
		.rs1_rena_ID		(rs1_rena_ID),
		.rs1_addr_ID		(rs1_addr_ID),
		.rs1_data_ID		(rs1_data_ID),
		.rs2_rena_ID		(rs2_rena_ID),
		.rs2_addr_ID		(rs2_addr_ID),
		.rs2_data_ID		(rs2_data_ID),
		.rs3_rena_ID		(rs3_rena_ID),
		.rs3_addr_ID		(rs3_addr_ID),
		.rs3_data_ID		(rs3_data_ID),

		.rd_wena_EX			(rd_wena_EX),
		.rd_addr_EX			(rd_addr_EX),
		.rd_data_EX			(rd_data_EX),
		.wb_src_EX			(wb_src_EX),

		.rd_wena_MEM		(rd_wena_MEM),
		.rd_addr_MEM		(rd_addr_MEM),
		.rd_data_MEM		(rd_data_MEM),

		.rd_wena_MEM_buf	(rd_wena_MEM_buf),
		.rd_addr_MEM_buf	(rd_addr_MEM_buf),
		.rd_data_MEM_buf	(rd_data_MEM_buf),

		.rs1_data			(rs1_data),
		.rs2_data			(rs2_data),
		.rs3_data			(rs3_data),
		.rd_after_ld_hazard	(rd_after_ld_hazard)
	);

	ALU ALU_inst
	(
		.op					(alu_op_ID),

		.a					(a),
		.b					(b),

		.y					(alu_out)
	);

	int_multiplier #(32, 8) int_multiplier_inst
	(
		.clk				(clk),
		.reset				(reset),
		.flush				(flush_out),

		.valid_in			(valid_in_mul && !exc_pend_ID),
		.ready_out			(ready_out_mul),
		.valid_out			(valid_out_mul),
		.ready_in			(ready_in && !rd_after_ld_hazard),

		.op					(mul_op_ID),

		.a					(a),
		.b					(b),

		.y					(mul_out)
	);

	int_divider #(32, 2) int_divider_inst
	(
		.clk				(clk),
		.reset				(reset),
		.flush				(flush_out),

		.valid_in			(valid_in_div && !exc_pend_ID),
		.ready_out			(ready_out_div),
		.valid_out			(valid_out_div),
		.ready_in			(ready_in && !rd_after_ld_hazard),

		.op					(div_op_ID),

		.a					(a),
		.b					(b),

		.y					(div_out)
	);

	FPU FPU_inst
	(
		.clk				(clk),
		.reset				(reset),
		.flush				(flush_out),

		.valid_in			(valid_in_fpu && !exc_pend_ID),
		.ready_out			(ready_out_fpu),
		.valid_out			(valid_out_fpu),
		.ready_in			(ready_in && !rd_after_ld_hazard),

		.op					(fpu_op_ID),
		.rm					(fpu_rm_ID == FPU_RM_DYN ? fpu_rm_csr : fpu_rm_ID),

		.a					(a),
		.b					(b),
		.c					(c),

		.y					(fpu_out),

		.IV					(fpu_flags[4]),
		.DZ					(fpu_flags[3]),
		.OF					(fpu_flags[2]),
		.UF					(fpu_flags[1]),
		.IE					(fpu_flags[0])
	);

endmodule