

module FETCH_STAGE (
			   // Beware, this PC has already branched (if there was a branch)
		       input [31:0] f_in_pc,

			   // Wires to/from Memory
		       input [31:0] f_in_mem_instr,
		       output [31:0] f_out_mem_instr_address,

			   // Out wires for decode
		       output [31:0] f_out_instr,
		       output [31:0] f_out_pc_plus4);

	assign f_out_mem_instr_address = f_in_pc;
	assign f_out_instr = f_in_mem_instr;

	assign f_out_pc_plus4 = f_in_pc + 4;

endmodule
