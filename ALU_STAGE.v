
module ALU_STAGE (
		  input clk,
		  input reset,

		  input [31:0] input1,
		  input [31:0] input2,
		  input [4:0] alu_operation,

		  input [3:0] bypass1,
		  input [3:0] bypass2,

		  output reg [31:0] alu_output,

		  input in_dest_register_enable,
		  input [4:0] in_passthrough_dest_register_number,

		  output reg out_dest_register_enable,
		  output reg [4:0] out_passthrough_dest_register_number,

		  input [31:0] branch_dest, // The destination of BEQ

		  input [31:0] next_program_counter,
		  output reg branch_address_enable,
		  output reg [31:0] branch_address);

`include "STD_constants.vinc"
`include "ALU_constants.vinc"
`include "RISCV_constants.vinc"

	wire [31:0] next_alu_output;

	wire [31:0] effective_input1, effective_input2;

	assign effective_input1 = bypass1 == NO_BYPASS ? input1 :
				  bypass1 == BYPASS_FROM_ALU ? alu_output :
				  input1;

	assign effective_input2 = bypass2 == NO_BYPASS ? input2 :
				  bypass2 == BYPASS_FROM_ALU ? alu_output :
				  input2;

	assign next_alu_output = alu_operation == ADDITION ? effective_input1 + effective_input2 :
				 alu_operation == SUBTRACTION ? effective_input1 - effective_input2 :
				 alu_operation == MULTIPLICATION ? effective_input1 * effective_input2 :
				 alu_operation == UNCOND_JUMP ? next_program_counter :
				 32'b0;

	wire next_branch_address_enable;
	wire [31:0] next_branch_address;

	assign next_branch_address_enable = alu_operation == UNCOND_JUMP ? TRUE :
					    alu_operation == COND_EQ_JUMP && effective_input1 == effective_input2 ? TRUE :
					    FALSE;

	assign next_branch_address = alu_operation == UNCOND_JUMP ? effective_input1 + effective_input2 :
				     alu_operation == COND_EQ_JUMP ? branch_dest :
				     32'b0;

	wire next_out_dest_register_enable;
	// To kill the instruction: don't write in the register file
	assign next_out_dest_register_enable = branch_address_enable == TRUE ? FALSE :
					       in_dest_register_enable;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			alu_output <= 32'b0;
			out_dest_register_enable <= FALSE;
			out_passthrough_dest_register_number <= x0;
			branch_address_enable <= FALSE;
			branch_address <= 32'b0;
		end else begin // if (reset)
			alu_output <= next_alu_output;
			out_dest_register_enable <= next_out_dest_register_enable;
			out_passthrough_dest_register_number <= in_passthrough_dest_register_number;
			branch_address_enable <= next_branch_address_enable;
			branch_address <= next_branch_address;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
