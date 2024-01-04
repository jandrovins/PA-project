
module HAZARD_UNIT (
		input clk,
		input reset,

        input [4:0] if_in_rs1_key_l,
        input [4:0] if_in_rs2_key_l,

		input [4:0] id_in_rs1_key_l,
		input [4:0] id_in_rs2_key_l,
        input [4:0] id_in_rd_key_l,
        input       id_in_rd_is_lw_en_l, // enabled if it is a lw instr - i.e., if it will write in regfile from the mem

		input [4:0] mem_in_rd_key_l,
		input       mem_in_rd_en_l, // enabled if it will write

		input [4:0] wb_in_rd_key_l,
		input       wb_in_rd_en_l, // enabled if it will write

		output [1:0] hu_out_alu_rs1_sel_w,
		output [1:0] hu_out_alu_rs2_sel_w,

        output       hu_out_stall_if_en_w,
        output       hu_out_stall_id_en_w,
        output       hu_out_flush_ex_en_w
        );

    wire hu_lw_causes_stall;

 	// memory has priority because is earliear in the pipeline
	assign hu_out_alu_rs1_sel_w = ((id_in_rs1_key_l == mem_in_rd_key_l) && mem_in_rd_en_l) && (id_in_rs1_key_l != 0) ? 2'b10 :
								 	 ((id_in_rs1_key_l == wb_in_rd_key_l) && wb_in_rd_en_l) && (id_in_rs1_key_l != 0) ? 2'b01 :
									 2'b00;

 	// memory has priority because is earliear in the pipeline
	assign hu_out_alu_rs2_sel_w = ((id_in_rs2_key_l == mem_in_rd_key_l) && mem_in_rd_en_l) && (id_in_rs2_key_l != 0) ? 2'b10 :
								 	 ((id_in_rs2_key_l == wb_in_rd_key_l) && wb_in_rd_en_l) && (id_in_rs2_key_l != 0) ? 2'b01 :
									 2'b00;

    assign hu_lw_causes_stall_w = id_in_rd_is_lw_en_l & ((id_in_rd_key_l == if_in_rs1_key_l) | (id_in_rd_key_l == if_in_rs2_key_l));

    assign hu_out_stall_if_en_w = hu_lw_causes_stall_w;
    assign hu_out_stall_id_en_w = hu_lw_causes_stall_w;
    assign hu_out_flush_ex_en_w = hu_lw_causes_stall_w;

endmodule
