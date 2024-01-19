
module DECODE_STAGE (
			input [31:0] d_in_instr,

			output [31:0] d_out_r1_data,
			output [31:0] d_out_r1_key,
			output [31:0] d_out_r2_data,
			output [31:0] d_out_r2_key,
			output [31:0] d_out_rd_key,
			output d_out_rd_we,
			output [1:0] d_out_rd_sel,

			output [31:0] d_out_imm,


			output d_out_mem_we,
			output d_out_is_jmp,
			output d_out_is_branch,

			output [4:0] d_out_alu_op,

			output d_out_alu_src2_sel			
			);

`include "RISCV_constants.vinc"
`include "ALU_constants.vinc"
`include "STD_constants.vinc"

	wire [6:0] opcode, funct7;
	wire [4:0] rs1, rs2, rd;
	wire [3:0] funct3;

	wire [11:0] immI, immS;

	wire [31:0] next_operand1, next_operand2;
	wire [4:0] next_alu_operation;

	wire [31:0] effective_instr;

	wire [31:0] debug;

	assign effective_instr = kill_instr == TRUE ? NOP :
						instr;

	assign opcode = effective_instr[ 6: 0];
	wire [4:0] is_u_instr, is_s_instr, is_j_instr, is_r_instr, is_i_instr, is_b_instr;


    assign is_u_instr = opcode[6:2] ==  5'b01101 ||
                 		opcode[6:2] ==  5'b00101 ;
    assign is_s_instr = opcode[6:2] ==  5'b01001 ||
                 		opcode[6:2] ==  5'b01000 ;
    assign is_j_instr = opcode[6:2] ==  5'b11011;
    assign is_r_instr = opcode[6:2] ==  5'b01100 ||
                 		opcode[6:2] ==  5'b01011 ||
                 		opcode[6:2] ==  5'b01110 ||
                 		opcode[6:2] ==  5'b10100;
    assign is_i_instr = opcode[6:2] ==  5'b00001 ||
                 		opcode[6:2] ==  5'b00000 ||
                 		opcode[6:2] ==  5'b00110 ||
                 		opcode[6:2] ==  5'b00100 ||
                 		opcode[6:2] ==  5'b11001;
    assign is_b_instr = opcode[6:2] ==  5'b11000;

	assign rd     = effective_instr[11: 7];
	assign rs1    = effective_instr[19:15];
	assign rs2    = effective_instr[24:20];
	assign funct7 = effective_instr[31:25];
	assign funct3 = effective_instr[14:12];

	assign immI = effective_instr[31:20];
	assign immS = {effective_instr[31:25], effective_instr[11:7]};

	wire [31:0] branch_offset;
	assign branch_offset = { {20{effective_instr[31]}},
		effective_instr[7],
		effective_instr[30:25],
		effective_instr[11:8],
		1'b0  };

	assign d_out_imm = is_b_instr ? branch_offset :
					   is_i_instr ? {{20{immI[11]}}, immI} : 
					   is_s_instr ? {{20{immS[11]}}, immS} :
					   32'b0;

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
				    opcode == JALR && funct3 == 3'b0			? ALU_JALR : // JALR
				    opcode == BRANCH && funct3 == 3'b000			? ALU_BEQ : // BEQ
				    opcode == BRANCH && funct3 == 3'b100			? ALU_BLT : // BLT
				    opcode == BRANCH && funct3 == 3'b101			? ALU_BGE : // BGE
				    opcode == BRANCH && funct3 == 3'b110			? ALU_BLTU : // BLTU
				    opcode == BRANCH && funct3 == 3'b111			? ALU_BGEU : // BGEU
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


	wire [31:0] next_branch_dest;
	assign next_branch_dest = current_program_counter + branch_offset;

	//always @(posedge clk, posedge reset) begin
	//	if (reset) begin
	//	    operand1_key <= 32'b0;
	//	    operand2_key <= 32'b0;
	//		operand1 <= 32'b0;
	//		operand2 <= 32'b0;
	//		alu_operation <= ADDITION;
	//		dest_register_enable <= FALSE;
	//		dest_register_number <= x0;
	//		out_passthrough_next_program_counter <= 32'b0;
	//		branch_dest <= 32'b0;
	//		source2_reg_value <= 32'b0;
	//	end else begin // if (reset)
	//	    operand1_key <= source1_register_key;
	//	    operand2_key <= source2_register_key;
	//		operand1 <= next_operand1;
	//		operand2 <= next_operand2;
	//		alu_operation <= next_alu_operation;
	//		dest_register_enable <= next_dest_register_enable;
	//		dest_register_number <= next_dest_register_number;
	//		out_passthrough_next_program_counter <= in_passthrough_next_program_counter;
	//		branch_dest <= next_branch_dest;
	//		source2_reg_value <= source2_register_value;
	//	end
	//end // always @ (posedge clk, posedge reset)

endmodule
