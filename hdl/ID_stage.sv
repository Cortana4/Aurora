import CPU_pkg::*;

module ID_stage
(
	input	logic			clk,
	input	logic			reset,

	input	logic			valid_in,
	output	logic			ready_out,
	output	logic			flush_out,
	output	logic			valid_out,
	input	logic			ready_in,
	input	logic			flush_in,

	output	logic			valid_out_mul,
	input	logic			ready_in_mul,
	output	logic			valid_out_div,
	input	logic			ready_in_div,
	output	logic			valid_out_fpu,
	input	logic			ready_in_fpu,

	input	logic	[31:0]	PC_IF,
	input	logic	[31:0]	IR_IF,
	input	logic			exc_pend_IF,
	input	logic	[31:0]	exc_cause_IF,

	output	logic			jump_pred_IF,
	output	logic	[31:0]	jump_addr_IF,

	output	logic	[31:0]	PC_ID,
	output	logic	[31:0]	IR_ID,
	output	logic	[31:0]	IM_ID,
	output	logic			rs1_rena_ID,
	output	logic	[5:0]	rs1_addr_ID,
	output	logic	[31:0]	rs1_data_ID,
	output	logic			rs2_rena_ID,
	output	logic	[5:0]	rs2_addr_ID,
	output	logic	[31:0]	rs2_data_ID,
	output	logic			rs3_rena_ID,
	output	logic	[5:0]	rs3_addr_ID,
	output	logic	[31:0]	rs3_data_ID,
	output	logic			rd_wena_ID,
	output	logic	[5:0]	rd_addr_ID,
	output	logic	[11:0]	csr_addr_ID,
	output	logic			csr_rena_ID,
	output	logic			csr_wena_ID,
	output	logic			sel_PC_ID,
	output	logic			sel_IM_ID,
	output	logic	[2:0]	wb_src_ID,
	output	logic	[3:0]	alu_op_ID,
	output	logic	[2:0]	mem_op_ID,
	output	logic	[1:0]	csr_op_ID,
	output	logic	[1:0]	mul_op_ID,
	output	logic	[1:0]	div_op_ID,
	output	logic	[4:0]	fpu_op_ID,
	output	logic	[2:0]	fpu_rm_ID,
	output	logic			jump_ena_ID,
	output	logic			jump_ind_ID,
	output	logic			jump_alw_ID,
	output	logic			jump_pred_ID,
	output	logic			trap_ret_ID,
	output	logic			exc_pend_ID,
	output	logic	[31:0]	exc_cause_ID,

	output	logic	[31:0]	PC_ID_buf,
	output	logic	[31:0]	IR_ID_buf,
	output	logic	[31:0]	IM_ID_buf,
	output	logic			rs1_rena_ID_buf,
	output	logic	[5:0]	rs1_addr_ID_buf,
	output	logic	[31:0]	rs1_data_ID_buf,
	output	logic			rs2_rena_ID_buf,
	output	logic	[5:0]	rs2_addr_ID_buf,
	output	logic	[31:0]	rs2_data_ID_buf,
	output	logic			rs3_rena_ID_buf,
	output	logic	[5:0]	rs3_addr_ID_buf,
	output	logic	[31:0]	rs3_data_ID_buf,
	output	logic			rd_wena_ID_buf,
	output	logic	[5:0]	rd_addr_ID_buf,
	output	logic	[11:0]	csr_addr_ID_buf,
	output	logic			csr_rena_ID_buf,
	output	logic			csr_wena_ID_buf,
	output	logic			sel_PC_ID_buf,
	output	logic			sel_IM_ID_buf,
	output	logic	[2:0]	wb_src_ID_buf,
	output	logic	[3:0]	alu_op_ID_buf,
	output	logic	[2:0]	mem_op_ID_buf,
	output	logic	[1:0]	csr_op_ID_buf,
	output	logic	[1:0]	mul_op_ID_buf,
	output	logic	[1:0]	div_op_ID_buf,
	output	logic	[4:0]	fpu_op_ID_buf,
	output	logic	[2:0]	fpu_rm_ID_buf,
	output	logic			jump_ena_ID_buf,
	output	logic			jump_ind_ID_buf,
	output	logic			jump_alw_ID_buf,
	output	logic			jump_pred_ID_buf,
	output	logic			trap_ret_ID_buf,
	output	logic			exc_pend_ID_buf,
	output	logic	[31:0]	exc_cause_ID_buf,

	input	logic	[31:0]	PC_EX,
	input	logic			rd_wena_EX,
	input	logic	[5:0]	rd_addr_EX,
	input	logic	[31:0]	rd_data_EX,
	input	logic	[2:0]	wb_src_EX,
	input	logic			jump_ena_EX,
	input	logic			jump_alw_EX,
	input	logic			jump_taken_EX,

	input	logic			rd_wena_MEM,
	input	logic	[5:0]	rd_addr_MEM,
	input	logic	[31:0]	rd_data_MEM,

	input	logic			rd_wena_MEM_buf,
	input	logic	[5:0]	rd_addr_MEM_buf,
	input	logic	[31:0]	rd_data_MEM_buf,

	input	logic			rd_wena_WB,
	input	logic	[5:0]	rd_addr_WB,
	input	logic	[31:0]	rd_data_WB,

	input	logic			M_ena_csr,
	input	logic			F_ena_csr,
	input	logic	[31:0]	trap_raddr_csr
);

	logic	[31:0]	immediate;
	logic			rs1_rena;
	logic	[5:0]	rs1_addr;
	logic	[31:0]	rs1_data;
	logic			rs2_rena;
	logic	[5:0]	rs2_addr;
	logic	[31:0]	rs2_data;
	logic			rs3_rena;
	logic	[5:0]	rs3_addr;
	logic	[31:0]	rs3_data;
	logic			rd_wena;
	logic	[5:0]	rd_addr;
	logic			csr_rena;
	logic			csr_wena;
	logic	[11:0]	csr_addr;
	logic			sel_PC;
	logic			sel_IM;
	logic	[2:0]	wb_src;
	logic	[3:0]	alu_op;
	logic	[2:0]	mem_op;
	logic	[1:0]	csr_op;
	logic	[1:0]	mul_op;
	logic	[1:0]	div_op;
	logic	[4:0]	fpu_op;
	logic	[2:0]	fpu_rm;
	logic			jump_ena;
	logic			jump_ind;
	logic			jump_alw;
	logic			env_call;
	logic			trap_ret;
	logic			illegal_inst;

	logic	[31:0]	rs1_data_bypassed;
	logic	[31:0]	rs2_data_bypassed;
	logic	[31:0]	rs3_data_bypassed;

	logic	[31:0]	rs1_data_bypassed_buf;
	logic	[31:0]	rs2_data_bypassed_buf;
	logic	[31:0]	rs3_data_bypassed_buf;

	logic			exc_pend;
	logic	[31:0]	exc_cause;

	logic			valid_out_mul_buf;
	logic			valid_out_div_buf;
	logic			valid_out_fpu_buf;

	logic			valid_out_buf;
	logic			stall;

	assign			ready_out	= !valid_out_buf && !stall;
	assign			flush_out	= flush_in;
	assign			stall		= exc_pend_ID || csr_wena_ID || csr_rena_ID || flush_out;

	always_comb begin
		if (exc_pend_IF) begin
			exc_pend	= 1'b1;
			exc_cause	= exc_cause_IF;
		end

		else if (illegal_inst) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_ILLEGAL_INST;
		end

		else if (env_call) begin
			exc_pend	= 1'b1;
			exc_cause	= CAUSE_ENV_CALL_FROM_M;
		end

		else begin
			exc_pend	= 1'b0;
			exc_cause	= 32'h00000000;
		end
	end

	// ID/EX pipeline registers
	always_ff @(posedge clk, posedge reset) begin
		if (reset || flush_in) begin
			{PC_ID			, PC_ID_buf			}	<= {2{32'h00000000	}};
			{IR_ID			, IR_ID_buf			}	<= {2{32'h00000000	}};
			{IM_ID			, IM_ID_buf			}	<= {2{32'h00000000	}};
			{rs1_rena_ID	, rs1_rena_ID_buf	}	<= {2{1'b0			}};
			{rs1_addr_ID	, rs1_addr_ID_buf	}	<= {2{6'd0			}};
			{rs1_data_ID	, rs1_data_ID_buf	}	<= {2{32'h00000000	}};
			{rs2_rena_ID	, rs2_rena_ID_buf	}	<= {2{1'b0			}};
			{rs2_addr_ID	, rs2_addr_ID_buf	}	<= {2{6'd0			}};
			{rs2_data_ID	, rs2_data_ID_buf	}	<= {2{32'h00000000	}};
			{rs3_rena_ID	, rs3_rena_ID_buf	}	<= {2{1'b0			}};
			{rs3_addr_ID	, rs3_addr_ID_buf	}	<= {2{6'd0			}};
			{rs3_data_ID	, rs3_data_ID_buf	}	<= {2{32'h00000000	}};
			{rd_wena_ID		, rd_wena_ID_buf	}	<= {2{1'b0			}};
			{rd_addr_ID		, rd_addr_ID_buf	}	<= {2{6'd0			}};
			{csr_addr_ID	, csr_addr_ID_buf	}	<= {2{12'h000		}};
			{csr_rena_ID	, csr_rena_ID_buf	}	<= {2{1'b0			}};
			{csr_wena_ID	, csr_wena_ID_buf	}	<= {2{1'b0			}};
			{sel_PC_ID		, sel_PC_ID_buf		}	<= {2{1'b0			}};
			{sel_IM_ID		, sel_IM_ID_buf		}	<= {2{1'b0			}};
			{wb_src_ID		, wb_src_ID_buf		}	<= {2{3'd0			}};
			{alu_op_ID		, alu_op_ID_buf		}	<= {2{4'd0			}};
			{mem_op_ID		, mem_op_ID_buf		}	<= {2{3'd0			}};
			{csr_op_ID		, csr_op_ID_buf		}	<= {2{2'd0			}};
			{mul_op_ID		, mul_op_ID_buf		}	<= {2{2'd0			}};
			{div_op_ID		, div_op_ID_buf		}	<= {2{2'd0			}};
			{fpu_op_ID		, fpu_op_ID_buf		}	<= {2{5'd0			}};
			{fpu_rm_ID		, fpu_rm_ID_buf		}	<= {2{3'd0			}};
			{jump_ena_ID	, jump_ena_ID_buf	}	<= {2{1'b0			}};
			{jump_ind_ID	, jump_ind_ID_buf	}	<= {2{1'b0			}};
			{jump_alw_ID	, jump_alw_ID_buf	}	<= {2{1'b0			}};
			{jump_pred_ID	, jump_pred_ID_buf	}	<= {2{1'b0			}};
			{trap_ret_ID	, trap_ret_ID_buf	}	<= {2{1'b0			}};
			{exc_pend_ID	, exc_pend_ID_buf	}	<= {2{1'b0			}};
			{exc_cause_ID	, exc_cause_ID_buf	}	<= {2{32'h00000000	}};
			{valid_out_mul	, valid_out_mul_buf	}	<= {2{1'b0			}};
			{valid_out_div	, valid_out_div_buf	}	<= {2{1'b0			}};
			{valid_out_fpu	, valid_out_fpu_buf	}	<= {2{1'b0			}};
			{valid_out		, valid_out_buf		}	<= {2{1'b0			}};
		end

		else if (!valid_out_buf) begin
			// input to output
			if (valid_in && (ready_in || !valid_out) && !stall) begin
				PC_ID				<= PC_IF;
				IR_ID				<= IR_IF;
				IM_ID				<= immediate;
				rs1_rena_ID			<= rs1_rena;
				rs1_addr_ID			<= rs1_addr;
				rs1_data_ID			<= rs1_data;
				rs2_rena_ID			<= rs2_rena;
				rs2_addr_ID			<= rs2_addr;
				rs2_data_ID			<= rs2_data;
				rs3_rena_ID			<= rs3_rena;
				rs3_addr_ID			<= rs3_addr;
				rs3_data_ID			<= rs3_data;
				rd_wena_ID			<= rd_wena;
				rd_addr_ID			<= rd_addr;
				csr_addr_ID			<= csr_addr;
				csr_rena_ID			<= csr_rena;
				csr_wena_ID			<= csr_wena;
				sel_PC_ID			<= sel_PC;
				sel_IM_ID			<= sel_IM;
				wb_src_ID			<= wb_src;
				alu_op_ID			<= alu_op;
				mem_op_ID			<= mem_op;
				csr_op_ID			<= csr_op;
				mul_op_ID			<= mul_op;
				div_op_ID			<= div_op;
				fpu_op_ID			<= fpu_op;
				fpu_rm_ID			<= fpu_rm;
				jump_ena_ID			<= jump_ena;
				jump_ind_ID			<= jump_ind;
				jump_alw_ID			<= jump_alw;
				jump_pred_ID		<= jump_pred_IF;
				trap_ret_ID			<= trap_ret;
				exc_pend_ID			<= exc_pend;
				exc_cause_ID		<= exc_cause;
				valid_out_mul		<= wb_src == SEL_MUL;
				valid_out_div		<= wb_src == SEL_DIV;
				valid_out_fpu		<= wb_src == SEL_FPU;
				valid_out			<= 1'b1;
			end
			// input to buffer
			else if (valid_in && !stall) begin
				PC_ID_buf			<= PC_IF;
				IR_ID_buf			<= IR_IF;
				IM_ID_buf			<= immediate;
				rs1_rena_ID_buf		<= rs1_rena;
				rs1_addr_ID_buf		<= rs1_addr;
				rs1_data_ID_buf		<= rs1_data;
				rs2_rena_ID_buf		<= rs2_rena;
				rs2_addr_ID_buf		<= rs2_addr;
				rs2_data_ID_buf		<= rs2_data;
				rs3_rena_ID_buf		<= rs3_rena;
				rs3_addr_ID_buf		<= rs3_addr;
				rs3_data_ID_buf		<= rs3_data;
				rd_wena_ID_buf		<= rd_wena;
				rd_addr_ID_buf		<= rd_addr;
				csr_addr_ID_buf		<= csr_addr;
				csr_rena_ID_buf		<= csr_rena;
				csr_wena_ID_buf		<= csr_wena;
				sel_PC_ID_buf		<= sel_PC;
				sel_IM_ID_buf		<= sel_IM;
				wb_src_ID_buf		<= wb_src;
				alu_op_ID_buf		<= alu_op;
				mem_op_ID_buf		<= mem_op;
				csr_op_ID_buf		<= csr_op;
				mul_op_ID_buf		<= mul_op;
				div_op_ID_buf		<= div_op;
				fpu_op_ID_buf		<= fpu_op;
				fpu_rm_ID_buf		<= fpu_rm;
				jump_ena_ID_buf		<= jump_ena;
				jump_ind_ID_buf		<= jump_ind;
				jump_alw_ID_buf		<= jump_alw;
				jump_pred_ID_buf	<= jump_pred_IF;
				trap_ret_ID_buf		<= trap_ret;
				exc_pend_ID_buf		<= exc_pend;
				exc_cause_ID_buf	<= exc_cause;
				valid_out_mul_buf	<= wb_src == SEL_MUL;
				valid_out_div_buf	<= wb_src == SEL_DIV;
				valid_out_fpu_buf	<= wb_src == SEL_FPU;
				valid_out_buf		<= 1'b1;
			end
			// bubble
			else if (valid_out && ready_in) begin
				PC_ID				<= 32'h00000000;
				IR_ID				<= 32'h00000000;
				IM_ID				<= 32'h00000000;
				rs1_rena_ID			<= 1'b0;
				rs1_addr_ID			<= 6'd0;
				rs1_data_ID			<= 32'h00000000;
				rs2_rena_ID			<= 1'b0;
				rs2_addr_ID			<= 6'd0;
				rs2_data_ID			<= 32'h00000000;
				rs3_rena_ID			<= 1'b0;
				rs3_addr_ID			<= 6'd0;
				rs3_data_ID			<= 32'h00000000;
				rd_wena_ID			<= 1'b0;
				rd_addr_ID			<= 6'd0;
				csr_addr_ID			<= 12'h000;
				csr_rena_ID			<= 1'b0;
				csr_wena_ID			<= 1'b0;
				sel_PC_ID			<= 1'b0;
				sel_IM_ID			<= 1'b0;
				wb_src_ID			<= 3'd0;
				alu_op_ID			<= 4'd0;
				mem_op_ID			<= 3'd0;
				csr_op_ID			<= 2'd0;
				mul_op_ID			<= 2'd0;
				div_op_ID			<= 2'd0;
				fpu_op_ID			<= 5'd0;
				fpu_rm_ID			<= 3'd0;
				jump_ena_ID			<= 1'b0;
				jump_ind_ID			<= 1'b0;
				jump_alw_ID			<= 1'b0;
				jump_pred_ID		<= 1'b0;
				trap_ret_ID			<= 1'b0;
				exc_pend_ID			<= 1'b0;
				exc_cause_ID		<= 32'h00000000;
				valid_out_mul		<= 1'b0;
				valid_out_div		<= 1'b0;
				valid_out_fpu		<= 1'b0;
				valid_out			<= 1'b0;
			end
		end
		// buffer to output
		else if (ready_in) begin
			{PC_ID			, PC_ID_buf			}	<= {PC_ID_buf			, 32'h00000000			};
			{IR_ID			, IR_ID_buf			}	<= {IR_ID_buf			, 32'h00000000			};
			{IM_ID			, IM_ID_buf			}	<= {IM_ID_buf			, 32'h00000000			};
			{rs1_rena_ID	, rs1_rena_ID_buf	}	<= {rs1_rena_ID_buf		, 1'b0					};
			{rs1_addr_ID	, rs1_addr_ID_buf	}	<= {rs1_addr_ID_buf		, 6'd0					};
			{rs1_data_ID	, rs1_data_ID_buf	}	<= {rs1_data_ID_buf		, 32'h00000000			};
			{rs2_rena_ID	, rs2_rena_ID_buf	}	<= {rs2_rena_ID_buf		, 1'b0					};
			{rs2_addr_ID	, rs2_addr_ID_buf	}	<= {rs2_addr_ID_buf		, 6'd0					};
			{rs2_data_ID	, rs2_data_ID_buf	}	<= {rs2_data_ID_buf		, 32'h00000000			};
			{rs3_rena_ID	, rs3_rena_ID_buf	}	<= {rs3_rena_ID_buf		, 1'b0					};
			{rs3_addr_ID	, rs3_addr_ID_buf	}	<= {rs3_addr_ID_buf		, 6'd0					};
			{rs3_data_ID	, rs3_data_ID_buf	}	<= {rs3_data_ID_buf		, 32'h00000000			};
			{rd_wena_ID		, rd_wena_ID_buf	}	<= {rd_wena_ID_buf		, 1'b0					};
			{rd_addr_ID		, rd_addr_ID_buf	}	<= {rd_addr_ID_buf		, 6'd0					};
			{csr_addr_ID	, csr_addr_ID_buf	}	<= {csr_addr_ID_buf		, 12'h000				};
			{csr_rena_ID	, csr_rena_ID_buf	}	<= {csr_rena_ID_buf		, 1'b0					};
			{csr_wena_ID	, csr_wena_ID_buf	}	<= {csr_wena_ID_buf		, 1'b0					};
			{sel_PC_ID		, sel_PC_ID_buf		}	<= {sel_PC_ID_buf		, 1'b0					};
			{sel_IM_ID		, sel_IM_ID_buf		}	<= {sel_IM_ID_buf		, 1'b0					};
			{wb_src_ID		, wb_src_ID_buf		}	<= {wb_src_ID_buf		, 3'd0					};
			{alu_op_ID		, alu_op_ID_buf		}	<= {alu_op_ID_buf		, 4'd0					};
			{mem_op_ID		, mem_op_ID_buf		}	<= {mem_op_ID_buf		, 3'd0					};
			{csr_op_ID		, csr_op_ID_buf		}	<= {csr_op_ID_buf		, 2'd0					};
			{mul_op_ID		, mul_op_ID_buf		}	<= {mul_op_ID_buf		, 2'd0					};
			{div_op_ID		, div_op_ID_buf		}	<= {div_op_ID_buf		, 2'd0					};
			{fpu_op_ID		, fpu_op_ID_buf		}	<= {fpu_op_ID_buf		, 5'd0					};
			{fpu_rm_ID		, fpu_rm_ID_buf		}	<= {fpu_rm_ID_buf		, 3'd0					};
			{jump_ena_ID	, jump_ena_ID_buf	}	<= {jump_ena_ID_buf		, 1'b0					};
			{jump_ind_ID	, jump_ind_ID_buf	}	<= {jump_ind_ID_buf		, 1'b0					};
			{jump_alw_ID	, jump_alw_ID_buf	}	<= {jump_alw_ID_buf		, 1'b0					};
			{jump_pred_ID	, jump_pred_ID_buf	}	<= {jump_pred_ID_buf	, 1'b0					};
			{trap_ret_ID	, trap_ret_ID_buf	}	<= {trap_ret_ID_buf		, 1'b0					};
			{exc_pend_ID	, exc_pend_ID_buf	}	<= {exc_pend_ID_buf		, 1'b0					};
			{exc_cause_ID	, exc_cause_ID_buf	}	<= {exc_cause_ID_buf	, 32'h00000000			};
			{valid_out_mul	, valid_out_mul_buf	}	<= {valid_out_mul_buf	, 1'b0					};
			{valid_out_div	, valid_out_div_buf	}	<= {valid_out_div_buf	, 1'b0					};
			{valid_out_fpu	, valid_out_fpu_buf	}	<= {valid_out_fpu_buf	, 1'b0					};
			{valid_out		, valid_out_buf		}	<= {1'b1				, 1'b0					};
		end

		else begin
			{rs1_data_ID	, rs1_data_ID_buf	}	<= {rs1_data_bypassed	, rs1_data_bypassed_buf	};
			{rs2_data_ID	, rs2_data_ID_buf	}	<= {rs2_data_bypassed	, rs2_data_bypassed_buf	};
			{rs3_data_ID	, rs3_data_ID_buf	}	<= {rs3_data_bypassed	, rs3_data_bypassed_buf	};

			if (valid_out_mul && ready_in_mul)
				valid_out_mul	<= 1'b0;

			if (valid_out_div && ready_in_div)
				valid_out_div	<= 1'b0;

			if (valid_out_fpu && ready_in_fpu)
				valid_out_fpu	<= 1'b0;
		end
	end

	bypass_logic bypass_logic_ID
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

		.rs1_data			(rs1_data_bypassed),
		.rs2_data			(rs2_data_bypassed),
		.rs3_data			(rs3_data_bypassed),
		.rd_after_ld_hazard	()
	);

	bypass_logic bypass_logic_ID_buf
	(
		.rs1_rena_ID		(rs1_rena_ID_buf),
		.rs1_addr_ID		(rs1_addr_ID_buf),
		.rs1_data_ID		(rs1_data_ID_buf),
		.rs2_rena_ID		(rs2_rena_ID_buf),
		.rs2_addr_ID		(rs2_addr_ID_buf),
		.rs2_data_ID		(rs2_data_ID_buf),
		.rs3_rena_ID		(rs3_rena_ID_buf),
		.rs3_addr_ID		(rs3_addr_ID_buf),
		.rs3_data_ID		(rs3_data_ID_buf),

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

		.rs1_data			(rs1_data_bypassed_buf),
		.rs2_data			(rs2_data_bypassed_buf),
		.rs3_data			(rs3_data_bypassed_buf),
		.rd_after_ld_hazard	()
	);

	inst_decoder inst_decoder_inst
	(
		.IR_IF				(IR_IF),

		.M_ena				(M_ena_csr),
		.F_ena				(F_ena_csr),

		.immediate			(immediate),
		.rs1_rena			(rs1_rena),
		.rs1_addr			(rs1_addr),
		.rs2_rena			(rs2_rena),
		.rs2_addr			(rs2_addr),
		.rs3_rena			(rs3_rena),
		.rs3_addr			(rs3_addr),
		.rd_wena			(rd_wena),
		.rd_addr			(rd_addr),
		.csr_addr			(csr_addr),
		.csr_rena			(csr_rena),
		.csr_wena			(csr_wena),
		.sel_PC				(sel_PC),
		.sel_IM				(sel_IM),
		.wb_src				(wb_src),
		.alu_op				(alu_op),
		.mem_op				(mem_op),
		.csr_op				(csr_op),
		.mul_op				(mul_op),
		.div_op				(div_op),
		.fpu_op				(fpu_op),
		.fpu_rm				(fpu_rm),
		.jump_ena			(jump_ena),
		.jump_ind			(jump_ind),
		.jump_alw			(jump_alw),
		.env_call			(env_call),
		.trap_ret			(trap_ret),
		.illegal_inst		(illegal_inst)
	);

	branch_predictor #(6, 1) branch_predictor_inst
	(
		.clk				(clk),
		.reset				(reset),

		.trap_raddr_csr		(trap_raddr_csr),

		.PC_IF				(PC_IF),
		.IM_IF				(immediate),
		.jump_ena_IF		(jump_ena),
		.jump_alw_IF		(jump_alw),
		.jump_ind_IF		(jump_ind),
		.trap_ret_IF		(trap_ret),
		.jump_pred_IF		(jump_pred_IF),
		.jump_addr_IF		(jump_addr_IF),

		.PC_EX				(PC_EX),
		.jump_ena_EX		(jump_ena_EX),
		.jump_alw_EX		(jump_alw_EX),
		.jump_taken_EX		(jump_taken_EX)
	);

	reg_file reg_file_inst
	(
		.clk				(clk),

		.rd_wena			(rd_wena_WB),
		.rd_addr			(rd_addr_WB),
		.rd_data			(rd_data_WB),

		.rs1_rena			(rs1_rena),
		.rs1_addr			(rs1_addr),
		.rs1_data			(rs1_data),

		.rs2_rena			(rs2_rena),
		.rs2_addr			(rs2_addr),
		.rs2_data			(rs2_data),

		.rs3_rena			(rs3_rena),
		.rs3_addr			(rs3_addr),
		.rs3_data			(rs3_data)
	);



endmodule