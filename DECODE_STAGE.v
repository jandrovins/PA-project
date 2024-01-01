
module DECODE_STAGE (
		     input clk,
		     input reset,
		     input [31:0] instruction_register,
		     input kill_instr,

		     input [31:0] source1_register_value,
		     input [31:0] source2_register_value,

		     output [4:0] source1_register_key,
		     output [4:0] source2_register_key,

		     output reg [31:0] operand1,
		     output reg [31:0] operand2,
		     output reg [4:0] alu_operation,

		     output reg [3:0] bypass1,
		     output reg [3:0] bypass2,

		     output reg dest_register_enable,
		     output reg [4:0] dest_register_number,

		     input [31:0] in_passthrough_next_program_counter,
		     output reg [31:0] out_passthrough_next_program_counter,
		     input [31:0] current_program_counter,
		     output reg [31:0] branch_dest);

`include "RISCV_constants.vinc"
`include "ALU_constants.vinc"
`include "STD_constants.vinc"

	wire [6:0] opcode, funct7;
	wire [4:0] rs1, rs2, rd, next_dest_register_number;
	wire [3:0] funct3;
	wire next_dest_register_enable;

	wire [11:0] immI, immS, immB;

	wire [31:0] next_operand1, next_operand2;
	wire [3:0] next_bypass1, next_bypass2;
	wire [4:0] next_alu_operation;

	wire [31:0] effective_instruction_register;

	wire [31:0] debug;

	assign effective_instruction_register = kill_instr == TRUE ? NOP :
						instruction_register;

	assign opcode = effective_instruction_register[ 6: 0];

	assign rd     = effective_instruction_register[11: 7];
	assign rs1    = effective_instruction_register[19:15];
	assign rs2    = effective_instruction_register[24:20];
	assign funct7 = effective_instruction_register[31:25];
	assign funct3 = effective_instruction_register[14:12];

	assign immI = effective_instruction_register[31:20];
	assign immS = {effective_instruction_register[31:25], effective_instruction_register[11:7]};
	assign immB = {effective_instruction_register[31], effective_instruction_register[7], effective_instruction_register[30:25], effective_instruction_register[11:8], 1'b0};

	wire [31:0] branch_offset;
	assign branch_offset = {{20{immB[11]}}, immB};

	assign source1_register_key = rs1;
	assign source2_register_key = rs2;

	assign next_operand1 = source1_register_value;
	assign next_operand2 = opcode == OP     ? source2_register_value :
			       opcode == OP_IMM ? {{20{immI[11]}}, immI} :
			       opcode == LOAD   ? {{20{immI[11]}}, immI} :
			       opcode == STORE  ? {{20{immS[11]}}, immS} :
			       opcode == BRANCH ? source2_register_value :
			       opcode == JALR   ? {{20{immI[11]}}, immI[11:1], 1'b0} :
			       32'b0;

	assign next_alu_operation = opcode == OP && funct3 == 3'b0 && funct7 == 7'h00	? ADDITION : // ADD
				    opcode == OP_IMM && funct3 == 3'b0			? ADDITION : // ADDI
				    opcode == OP && funct3 == 3'b0 && funct7 == 7'h20	? SUBTRACTION : // SUB
				    opcode == OP && funct3 == 3'b0 && funct7 == 7'h01	? MULTIPLICATION : // MUL
				    opcode == JALR && funct3 == 3'b0			? UNCOND_JUMP : // JALR
				    opcode == BRANCH && funct3 == 3'b0			? COND_EQ_JUMP : // BEQ
				    ADDITION;

	assign next_dest_register_enable = opcode == OP     ? TRUE  :
					   opcode == OP_IMM ? TRUE  :
					   opcode == LOAD   ? TRUE  :
					   opcode == STORE  ? FALSE :
					   opcode == BRANCH ? FALSE :
					   opcode == JALR   ? TRUE  :
					   FALSE;

	assign next_dest_register_number = opcode == OP     ? rd :
					   opcode == OP_IMM ? rd :
					   opcode == LOAD   ? rd :
					   opcode == STORE  ? x0 :
					   opcode == BRANCH ? x0 :
					   opcode == JALR   ? rd :
					   x0;

	assign next_bypass1 = dest_register_enable && dest_register_number == source1_register_key ? BYPASS_FROM_ALU :
			      NO_BYPASS;

	assign next_bypass2 = dest_register_enable && dest_register_number == source2_register_key ? BYPASS_FROM_ALU :
			      NO_BYPASS;

	wire [31:0] next_branch_dest;
	assign next_branch_dest = current_program_counter + branch_offset;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			operand1 <= 32'b0;
			operand2 <= 32'b0;
			alu_operation <= ADDITION;
			dest_register_enable <= FALSE;
			dest_register_number <= x0;
			bypass1 <= NO_BYPASS;
			bypass2 <= NO_BYPASS;
			out_passthrough_next_program_counter <= 32'b0;
			branch_dest <= 32'b0;
		end else begin // if (reset)
			operand1 <= next_operand1;
			operand2 <= next_operand2;
			alu_operation <= next_alu_operation;
			dest_register_enable <= next_dest_register_enable;
			dest_register_number <= next_dest_register_number;
			bypass1 <= next_bypass1;
			bypass2 <= next_bypass2;
			out_passthrough_next_program_counter <= in_passthrough_next_program_counter;
			branch_dest <= next_branch_dest;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
