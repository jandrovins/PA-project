module ALU_STAGE (
	input clk,
	input reset,

		  input [31:0] alu_in_src1,
		  input [31:0] alu_in_src2,
		  input [4:0]  alu_in_op,

		  output [31:0] alu_out_result,
		  output        alu_out_branch_en,
		  output        alu_out_busy
		  );
	wire [31:0] alu_div_result_q, alu_div_result_r;
	wire alu_start, alu_div_ended;
	reg  [1:0] alu_status;
	wire  [1:0] next_alu_status;
	reg alu_last_div_busy;
	wire alu_div_busy, alu_op_is_slow;
`include "RISCV_constants.vinc"

DIV div (
	   .clk(clk),
	   .reset(reset),
	   .start(alu_start),
	   .signedness(1'b1),
	   .a(alu_in_src1),
	   .b(alu_in_src2),
		
	   .busy(alu_div_busy),
	   .q(alu_div_result_q),
	   .r(alu_div_result_r));

	assign alu_op_is_slow = (alu_in_op == ALU_DIV_SLOW || alu_in_op == ALU_REM_SLOW);

	assign next_alu_status = !alu_op_is_slow ? 2'b00 :
							 alu_op_is_slow && alu_status == 2'b00 ? 2'b01 :
							 alu_status == 2'b01 && alu_div_busy ? 2'b01 :
							 alu_status == 2'b01 && !alu_div_busy ? 2'b10 :
							 alu_status == 2'b10 ? 2'b00 :
							 2'b00;
	assign alu_out_busy = (alu_start | alu_status != 2'b00) && alu_status != 2'b10;

	assign alu_start = alu_status == 2'b00 && alu_op_is_slow ? 1'b1 :
					   1'b0;

	assign alu_out_result = alu_in_op == ALU_ADD    ? alu_in_src1 + alu_in_src2 :
				 			alu_in_op == ALU_SUB    ? alu_in_src1 - alu_in_src2 :
				 			alu_in_op == ALU_DIV_FAST || alu_in_op == ALU_DIV_SLOW ? alu_div_result_q :
				 			alu_in_op == ALU_REM_FAST || alu_in_op == ALU_REM_SLOW ? alu_div_result_r :
				 			32'bx;

	assign alu_out_branch_en = alu_in_op == ALU_JAL ? TRUE :
                             alu_in_op == ALU_BEQ  && ( alu_in_src1 == alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BNE  && ( alu_in_src1 != alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BLTU && ( alu_in_src1 <  alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BGEU && ( alu_in_src1 >= alu_in_src2) ? TRUE :
					         alu_in_op == ALU_BLT  && ((alu_in_src1 <  alu_in_src2) ^ (alu_in_src1[31] != alu_in_src2[31])) ? TRUE :
				             alu_in_op == ALU_BGE  && ((alu_in_src1 >= alu_in_src2) ^ (alu_in_src1[31] != alu_in_src2[31])) ? TRUE :
					         FALSE;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			alu_last_div_busy <= 1'b0;
			alu_status <= 2'b00;
		end else begin // if (reset)
			alu_last_div_busy <= alu_div_busy;
			alu_status <= next_alu_status;
		end
	end
endmodule
