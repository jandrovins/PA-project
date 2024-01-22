
module DECODE_STAGE (
			input [31:0]  d_in_instr,

			output [4:0]  d_out_r1_key,
			output [4:0]  d_out_r2_key,
			output [4:0]  d_out_rd_key,
			output        d_out_rd_we, // Write enable for destination register

			output        d_out_alu_src2_is_imm, // 1 if ALU should use immediate as src2

			output [1:0]  d_out_rd_sel, // Selects from where the desination register should take its data

			output [31:0] d_out_imm, // Immediate


			output        d_out_mem_we, // Write enable for data memory
			output        d_out_mem_data_size, // Write enable for data memory
			output        d_out_is_jmp,
			output        d_out_is_branch,
			output [4:0]  d_out_alu_op
			);

`include "RISCV_constants.vinc"

	wire [3:0]  d_funct3;
	wire        d_is_s_instr, d_is_j_instr, d_is_r_instr, d_is_i_instr, d_is_b_instr;
	wire [6:0]  d_opcode, d_funct7;
	wire [11:0] d_immI, d_immS;
	wire [31:0] d_effective_instr;
	wire [31:0] d_branch_offset;
    wire d_is_load_instr;

	//####################################################//
	//######### DECODE BASIC SEGMENTS TYPE BEGIN #########//
	assign d_effective_instr = d_in_instr;
	assign d_opcode = d_effective_instr[ 6: 0];
	assign d_funct7 = d_effective_instr[31:25];
	assign d_funct3 = d_effective_instr[14:12];
	//######### DECODE BASIC SEGMENTS TYPE END #########//
	//####################################################//

	//####################################################//
	//############ DECODE INSTRUCTION TYPE BEGIN #########//
    //assign d_is_u_instr = d_opcode[6:2] ==  5'b01101 ||
    //             		  d_opcode[6:2] ==  5'b00101 ; LUI and AUIPC will not be used
    assign d_is_s_instr = d_opcode[6:2] ==  5'b01000 ;
                          //d_opcode[6:2] ==  5'b01001 || RV32Q
                 		  
    assign d_is_load_instr = d_opcode[6:2] == 5'b00000;
    assign d_is_j_instr = d_opcode[6:2] ==  5'b11011;
    assign d_is_r_instr = d_opcode[6:2] ==  5'b01100; // add, sub, etc. reg-to-reg instructions. Will be used.
                 		  //d_opcode[6:2] ==  5'b10100;   Float, won't be used
                 		  //d_opcode[6:2] ==  5'b01110 || RV64i, won't be used
                 		  //d_opcode[6:2] ==  5'b01011 || Atomic instr. extension, won't be used
    assign d_is_i_instr = d_is_load_instr || // LW, LB
                 		  d_opcode[6:2] ==  5'b00100;   // ADDI, ORI, ANDI, XORI, etc.
                          //d_opcode[6:2] ==  5'b00001 ||  Not used
                 		  //d_opcode[6:2] ==  5'b00110 ||  RV64i, won't be used
                 		  //d_opcode[6:2] ==  5'b11001;    JALR, won't be used?
    assign d_is_b_instr = d_opcode[6:2] ==  5'b11000;

	assign d_out_r1_key    = d_effective_instr[19:15];
	assign d_out_r2_key    = d_effective_instr[24:20];
	assign d_out_rd_key    = d_effective_instr[11: 7];

	assign d_out_mem_we    = d_is_s_instr;
	assign d_out_is_branch = d_is_b_instr;
	assign d_out_is_jmp    = d_is_j_instr;

    assign d_out_mem_data_size = d_is_load_instr && d_funct3 == 3'b000 ? MEM_BYTE :
                                 d_is_s_instr    && d_funct3 == 3'b000 ? MEM_BYTE :
                                 d_is_load_instr && d_funct3 == 3'b010 ? MEM_WORD :
                                 d_is_s_instr    && d_funct3 == 3'b010 ? MEM_WORD :
                                 MEM_WORD;

	//############ DECODE INSTRUCTION TYPE END ###########//
	//####################################################//

	//################################################//
	//############ CONSTRUCT IMMEDIATE BEGIN #########//
	assign d_immI = d_effective_instr[31:20];
	assign d_immS = {d_effective_instr[31:25], d_effective_instr[11:7]};
	assign d_branch_offset = { {20{d_effective_instr[31]}},
		d_effective_instr[7],
		d_effective_instr[30:25],
		d_effective_instr[11:8],
		1'b0  };
	assign d_out_imm = d_is_b_instr ? d_branch_offset :
					   d_is_i_instr ? {{20{d_immI[11]}}, d_immI} : 
					   d_is_s_instr ? {{20{d_immS[11]}}, d_immS} :
					   32'b0;
	//############ CONSTRUCT IMMEDIATE END #########//
	//##############################################//

	//############################################//
	//######### DECODE ENABLES AND BEGIN #########//
	// Zero if ALU src2 should be taken from r2, 1 if imm to be used
	assign d_out_alu_src2_is_imm = d_is_r_instr ? 0 : // Register-register operation
								d_is_b_instr ? 0 : // Compare r1 with r2
								d_is_i_instr ? 1 : // Operate r1 with imm
								d_is_s_instr ? 1 : // Operate r1 with offset from imm
								1'bx;
	assign d_out_rd_sel = d_is_load_instr    ? 2'b01 :
						  d_is_j_instr ? 2'b10 :
						  2'b00;
	assign d_out_rd_we = d_is_i_instr || d_is_r_instr || d_is_j_instr;
	//######### DECODE ENABLES AND END #########//
	//##########################################//

	//##############################################//
	//######### DECODE ALU OPERATION BEGIN #########//
	assign d_out_alu_op = d_is_s_instr ? ALU_ADD : // SW and SB
						  d_is_load_instr ? ALU_ADD : // LW and LB
						  d_is_i_instr && d_funct3 == 3'b0      		            ? ALU_ADD : // ADDI
                          d_is_r_instr && d_funct3 == 3'b0   && d_funct7 == 7'h00	? ALU_ADD : // ADD
				          d_is_r_instr && d_funct3 == 3'b0   && d_funct7 == 7'h20	? ALU_SUB : // SUB
				          d_is_r_instr && d_funct3 == 3'b0   && d_funct7 == 7'h01	? ALU_MUL : // MUL
				          d_is_b_instr && d_funct3 == 3'b000 ? ALU_BEQ : // BEQ
				          d_is_b_instr && d_funct3 == 3'b001 ? ALU_BNE : // BNE
				          d_is_b_instr && d_funct3 == 3'b100 ? ALU_BLT : // BLT
				          d_is_b_instr && d_funct3 == 3'b101 ? ALU_BGE : // BGE
				          d_is_b_instr && d_funct3 == 3'b110 ? ALU_BLTU : // BLTU
				          d_is_b_instr && d_funct3 == 3'b111 ? ALU_BGEU : // BGEU
				          d_is_j_instr                       ? ALU_JAL : // JAL
				          ALU_UNDEFINED_OP;
	//######### DECODE ALU OPERATION END #########//
	//############################################//
endmodule
