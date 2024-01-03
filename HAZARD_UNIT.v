
module HAZARD_UNIT (
		input clk,
		input reset,

		input [4:0] instr_src1_key,
		input [4:0] instr_src2_key,

		input [4:0] mst_rd_key,
		input       mst_rd_en, // enabled if if will write

		input [4:0] wst_rd_key,
		input       wst_rd_en, // enabled if if will write

		// when we have Memory stage input [3:0] mst_rd_key,
		// when we have Memory stage input       mst_rd_enable,

		output [1:0] alu_src1_sel,
		output [1:0] alu_src2_sel);


 	// memory has priority because is earliear in the pipeline
	assign alu_src1_sel = ((instr_src1_key == mst_rd_key) && mst_rd_en) && (instr_src1_key != 0) ? 2'b10 :
								 	 ((instr_src1_key == wst_rd_key) && wst_rd_en) && (instr_src1_key != 0) ? 2'b01 :
									 2'b00;

 	// memory has priority because is earliear in the pipeline
	assign alu_src2_sel = ((instr_src2_key == mst_rd_key) && mst_rd_en) && (instr_src2_key != 0) ? 2'b10 :
								 	 ((instr_src2_key == wst_rd_key) && wst_rd_en) && (instr_src2_key != 0) ? 2'b01 :
									 2'b00;

endmodule
