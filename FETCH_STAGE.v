

module FETCH_STAGE #(
		     parameter INITIAL_PC = 32'h1000
		    ) (
			   // fst = Fetch stage
		       input clk,
		       input reset,

			   // Wires from ALU
		       input [31:0] fst_in_branch_address,
		       input fst_in_branch_enable,

			   // Wires to/from Register File
		       output [31:0] fst_out_instr_address,
		       input [31:0] fst_in_instr,

			   // Out wires for decode
		       output reg [31:0] fst_out_instr,
		       output reg [31:0] fst_out_pc,
		       output reg [31:0] fst_out_pc_next);

`include "RISCV_constants.vinc"

	wire [31:0] next_pc_next; // Beware when branch_address_enable is 1, this should hold the fst_in_branch_address + 4 bytes
    wire [31:0] next_instr; // taken from memory, using rf_mem (output) and memory_data (input from memory). This assumes 1 clock memory, so shuold change eventually

	// Calculate next pc, taking into account if this is branch
	assign next_pc_next = fst_in_branch_enable == 1'b1 ? fst_in_branch_address + 32'd4 :
					   fst_out_pc_next + 32'd4;

    // To take instruction register from memory
	assign fst_out_instr_address = fst_in_branch_enable == 1'b1 ? fst_in_branch_address :
				fst_out_pc_next;

    // Taken from memory
	assign next_instr = fst_in_instr;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			fst_out_pc_next <= INITIAL_PC;
			fst_out_pc <= INITIAL_PC;
			fst_out_instr <= NOP; // Send NOP
		end else begin // if (reset)
			fst_out_pc_next <= next_pc_next;
			fst_out_instr <= next_instr;
			fst_out_pc <= fst_out_pc_next;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
