
module ALU_STAGE (
		  input clk,
		  input reset,

		  input [31:0] input1,
		  input [31:0] input2,
		  input [4:0] alu_operation,

		  output reg [31:0] alu_output,

		  input in_dest_register_enable,
		  input [4:0] in_passthrough_dest_register_number,

		  output reg out_dest_register_enable,
		  output reg [4:0] out_passthrough_dest_register_number,

		  input [31:0] branch_dest, // The destination of BEQ

		  input [31:0] next_program_counter,
		  output reg alu_out_branch_enable,
		  output reg [31:0] alu_out_branch_address);

`include "STD_constants.vinc"
`include "ALU_constants.vinc"
`include "RISCV_constants.vinc"

	wire [31:0] next_alu_output;

	assign next_alu_output = alu_operation == ADDITION ? input1 + input2 :
				 			 alu_operation == SUBTRACTION ? input1 - input2 :
				 			 alu_operation == MULTIPLICATION ? input1 * input2 :
				 			 alu_operation == ALU_JALR ? next_program_counter :
				 			 32'b0;

	wire next_branch_enable;
	wire [31:0] next_branch_address;

	assign next_branch_enable = alu_operation == ALU_JALR                                                      ? TRUE :
					    		alu_operation == ALU_BEQ  && ( input1 == input2                              ) ? TRUE :
				        		alu_operation == ALU_BNE  && ( input1 != input2                              ) ? TRUE :
					    		alu_operation == ALU_BLT  && ((input1 <  input2) ^ (input1[31] != input2[31])) ? TRUE :
				        		alu_operation == ALU_BGE  && ((input1 >= input2) ^ (input1[31] != input2[31])) ? TRUE :
				        		alu_operation == ALU_BLTU && ( input1 <  input2                              ) ? TRUE :
				        		alu_operation == ALU_BGEU && ( input1 >= input2                              ) ? TRUE :
					    		FALSE;

	assign next_branch_address = alu_operation == ALU_JALR ? input1 + input2 :
				     			 alu_operation == ALU_BEQ  ? branch_dest :
				     			 alu_operation == ALU_BLT  ? branch_dest :
				     			 alu_operation == ALU_BNE  ? branch_dest :
				     			 alu_operation == ALU_BGE  ? branch_dest :
				     			 alu_operation == ALU_BLTU ? branch_dest :
				     			 alu_operation == ALU_BGEU ? branch_dest :
				     			 32'b0;

	wire next_out_dest_register_enable;
	// To kill the instruction: don't write in the register file
	assign next_out_dest_register_enable = alu_out_branch_enable == TRUE ? FALSE :
					       in_dest_register_enable;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			alu_output <= 32'b0;
			out_dest_register_enable <= FALSE;
			out_passthrough_dest_register_number <= x0;
			alu_out_branch_enable <= FALSE;
			alu_out_branch_address <= 32'b0;
		end else begin // if (reset)
			alu_output <= next_alu_output;
			out_dest_register_enable <= next_out_dest_register_enable;
			out_passthrough_dest_register_number <= in_passthrough_dest_register_number;
			alu_out_branch_enable <= next_branch_enable;
			alu_out_branch_address <= next_branch_address;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
