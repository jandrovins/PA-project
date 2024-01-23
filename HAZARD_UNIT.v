module HAZARD_UNIT (
		input       icache_hit,

        input [4:0] d_in_r1_key,
        input [4:0] d_in_r2_key,
		input       d_in_is_branch,

		input [4:0] e_in_r1_key,
		input [4:0] e_in_r2_key,
        input [4:0] e_in_rd_key,
        input       e_in_rd_is_load_en, // enabled if it is a lw instr - i.e., if it will write in regfile from the mem
		input       e_in_is_branch,
		input       e_in_bp_predicted_en,
		input       e_in_bp_mispredict_en,
		input       e_in_branch_taken_en,

		input [4:0] m_in_rd_key,
		input       m_in_rd_we, // enabled if it will write from register

		input [4:0] wb_in_rd_key,
		input       wb_in_rd_we, // enabled if it will write from register

		output [1:0] hu_out_alu_src1_sel, // 00 if no bypass. 01 if bypass from wb, 10 if from memory
		output [1:0] hu_out_alu_src2_sel, // 00 if no bypass. 01 if bypass from wb, 10 if from memory

        output       hu_out_stall_f_en,
        output       hu_out_stall_d_en,
        output       hu_out_flush_e_en,
        output       hu_out_flush_d_en
        );
		// TODO: Bypass from memory out to memory in, to optimize LW x5, 0(x10), ST x5, 0(x11) which is a memcpy gg

    wire hu_tmp_load_causes_stall, hu_tmp_e_have_to_correct_branch;

 	// memory has priority because is earliear in the pipeline
	assign hu_out_alu_src1_sel = ((e_in_r1_key == m_in_rd_key)  && m_in_rd_we)  && (e_in_r1_key != 0) ? 2'b10 :
								 ((e_in_r1_key == wb_in_rd_key) && wb_in_rd_we) && (e_in_r1_key != 0) ? 2'b01 :
								 2'b00;

 	// memory has priority because is earliear in the pipeline
	assign hu_out_alu_src2_sel = ((e_in_r2_key == m_in_rd_key)  && m_in_rd_we)  && (e_in_r2_key != 0) ? 2'b10 :
								 ((e_in_r2_key == wb_in_rd_key) && wb_in_rd_we) && (e_in_r2_key != 0) ? 2'b01 :
								 2'b00;

    assign hu_tmp_load_causes_stall = e_in_rd_is_load_en & ((e_in_rd_key == d_in_r1_key) | (e_in_rd_key == d_in_r2_key));

	assign hu_tmp_e_have_to_correct_branch = e_in_bp_mispredict_en | (!e_in_bp_predicted_en && e_in_branch_taken_en);

    assign hu_out_stall_f_en = hu_tmp_load_causes_stall | (!icache_hit & !hu_tmp_e_have_to_correct_branch);
    assign hu_out_stall_d_en = hu_tmp_load_causes_stall;
    assign hu_out_flush_e_en = hu_tmp_load_causes_stall | hu_tmp_e_have_to_correct_branch;
	assign hu_out_flush_d_en = (!icache_hit & !hu_tmp_e_have_to_correct_branch) | hu_tmp_e_have_to_correct_branch;
endmodule

//// If cache-miss, flush decode, Except if decode instr. is branch, then stall decode.
//// Otherwise, branch might get lost (not jump)
//    assign hu_out_stall_f_en = hu_tmp_load_causes_stall | !icache_hit;
//    assign hu_out_stall_d_en = hu_tmp_load_causes_stall | (!icache_hit && (d_is_branch | e_is_branch));
//    assign hu_out_flush_e_en = hu_tmp_load_causes_stall | hu_tmp_e_have_to_correct_branch;
//	assign hu_out_flush_d_en = (!icache_hit && (!d_is_branch && !e_is_branch)) | hu_tmp_e_have_to_correct_branch; 
//