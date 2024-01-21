module ALU_STAGE (
		  input [31:0] alu_in_src1,
		  input [31:0] alu_in_src2,
		  input [4:0]  alu_in_op,

		  output [31:0] alu_out_result,
		  output        alu_out_branch_en
		  );

`include "RISCV_constants.vinc"

	assign alu_out_result = alu_in_op == ALU_ADD    ? alu_in_src1 + alu_in_src2 :
				 			alu_in_op == ALU_SUB    ? alu_in_src1 - alu_in_src2 :
				 			alu_in_op == ALU_MUL    ? alu_in_src1 * alu_in_src2 :
				 			32'bx;

	assign alu_out_branch_en = alu_in_op == ALU_JAL ? TRUE :
                             alu_in_op == ALU_BEQ  && ( alu_in_src1 == alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BNE  && ( alu_in_src1 != alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BLTU && ( alu_in_src1 <  alu_in_src2) ? TRUE :
				             alu_in_op == ALU_BGEU && ( alu_in_src1 >= alu_in_src2) ? TRUE :
					         alu_in_op == ALU_BLT  && ((alu_in_src1 <  alu_in_src2) ^ (alu_in_src1[31] != alu_in_src2[31])) ? TRUE :
				             alu_in_op == ALU_BGE  && ((alu_in_src1 >= alu_in_src2) ^ (alu_in_src1[31] != alu_in_src2[31])) ? TRUE :
					         FALSE;
endmodule
