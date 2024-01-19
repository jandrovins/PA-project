
module CPU (
	    input clk,
	    input reset,

	    input [31:0] memory_data_bus1,
	    output [31:0] memory_address_bus1,

	    output memory_write_enable2,
	    inout [31:0] memory_data_bus2,
	    output [31:0] memory_address_bus2
	    );


`include "STD_constants.vinc"
`include "CPU_CONFIG.vinc"

	wire [31:0] instruction_register, port1_data, port2_data, portD_data, operand1, operand2, alu_output;

	wire [4:0] port1_key, port2_key, portD_key;

	wire [4:0] alu_operation;

	wire portD_enable;

	REGISTER_FILE register_file (.clk(clk),
				     .port1_key(port1_key),
				     .port2_key(port2_key),
				     .port1_value(port1_data),
				     .port2_value(port2_data),
				     .portD_enable(portD_enable),
				     .portD_key(portD_key),
				     .portD_value(portD_data));
	

	//#########################################//
	//########### FETCH STAGE BEGIN ###########//
	//#########################################//

	wire [31:0] alu_branch_address_w;
	wire alu_branch_enable_w;

	reg [31:0] f_pc;
	wire [31:0] f_pc_plus4;
	wire [31:0] next_f_pc;
	wire [31:0] f_instr;

	assign next_f_pc = alu_branch_enable_w ? alu_branch_address_w :
						f_pc_plus_4;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			f_pc <= INITIAL_PC;
		end else begin // if (reset)
			f_pc <= next_f_pc;
		end
	end // always @ (posedge clk, posedge reset)

	FETCH_STAGE fetch (.f_in_pc(f_pc),
	       .f_in_mem_instr(memory_data_bus1),
	       .f_out_mem_instr_address(memory_address_bus1),
	       .f_out_instr(f_instr),
	       .f_out_pc_plus4(f_pc_plus4));

	reg [31:0] d_pc;
	reg [31:0] d_pc_plus4;
	reg [31:0] d_instr;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			d_pc <= INITIAL_PC;
			d_next_pc <= INITIAL_PC;
			d_instr <= NOP; // Send NOP
		end else begin // if (reset)
			d_pc <= f_pc;
			d_pc_plus4 <= f_pc_plus4;
			d_instr <= f_instr;
		end
	end // always @ (posedge clk, posedge reset)

	//#########################################//
	//############ FETCH STAGE END ############//
	//############ DECODE STAGE BEGIN #########//
	//#########################################//

	wire dest_register_enable_DA, dest_register_enable_AW;
	wire [4:0] dest_register_number_DA, dest_register_number_AW;
	wire [31:0] next_program_counter_DA, branch_dest, source2_reg_value_DE;
	wire [4:0] operand1_key, operand2_key;

	DECODE_STAGE decode (.clk(clk), .reset(reset),
			     .instr(instruction_register),
			     .kill_instr(alu_branch_enable_w),
			     .source1_register_key(port1_key),
			     .source2_register_key(port2_key),
			     .source1_register_value(port1_data),
			     .source2_register_value(port2_data),
			     .operand1_key(operand1_key),
			     .operand2_key(operand2_key),
			     .operand1(operand1),
			     .operand2(operand2),
			     .alu_operation(alu_operation),
			     .dest_register_enable(dest_register_enable_DA),
			     .dest_register_number(dest_register_number_DA),
			     .in_passthrough_next_program_counter(next_program_counter),
			     .out_passthrough_next_program_counter(next_program_counter_DA),
			     .current_program_counter(current_program_counter),
			     .branch_dest(branch_dest),
			     .source2_reg_value(source2_reg_value_DE));

    wire [4:0]  if_instr_rs1_key_w;
    wire [4:0]  if_instr_rs2_key_w;
	wire [31:0] alu_src1, alu_src2, alu_src3;
	wire [1:0]  hu_alu_src1_sel, hu_alu_src2_sel;
    wire [4:0]  ex_from_id_rd_key_l;
    wire        ex_from_id_rd_en_l;
    wire        hu_stall_if_en_w;
    wire        hu_stall_id_en_w;
    wire        hu_flush_ex_en_w;

    assign if_instr_rs1_key_w = instruction_register;
    assign if_instr_rs2_key_w = instruction_register;

	HAZARD_UNIT hu (
		.clk(clk),
		.reset(reset),

        .if_in_rs1_key_l(if_instr_rs1_key_w),
        .if_in_rs2_key_l(if_instr_rs2_key_w),


        .id_in_rs1_key_l(operand1_key),
        .id_in_rs2_key_l(operand2_key),
        .id_in_rd_key_l   (dest_register_number_DA),
        .id_in_rd_is_lw_en_l(dest_register_enable_DA),

        .mem_in_rd_key_l(dest_register_number_AW),
        .mem_in_rd_en_l (dest_register_enable_AW),

        .wb_in_rd_key_l(portD_key),
        .wb_in_rd_en_l (portD_enable), 

        .hu_out_alu_rs1_sel_w(hu_alu_src1_sel),
        .hu_out_alu_rs2_sel_w(hu_alu_src2_sel),

        .hu_out_stall_if_en_w(hu_stall_if_en_w),
        .hu_out_stall_id_en_w(hu_stall_id_en_w),
        .hu_out_flush_ex_en_w(hu_flush_ex_en_w)
	);

	assign alu_src1 = hu_alu_src1_sel == 2'b00 ? operand1 :
					  hu_alu_src1_sel == 2'b01 ? portD_data:
					  hu_alu_src1_sel == 2'b10 ? alu_output:
					  2'dx;
	assign alu_src2 = hu_alu_src2_sel == 2'b00 ? operand2 :
					  hu_alu_src2_sel == 2'b01 ? portD_data:
					  hu_alu_src2_sel == 2'b10 ? alu_output:
					  2'dx; // NOT TESTED
	assign alu_src3 = hu_alu_src2_sel == 2'b00 ? source2_reg_value_DE :
					  hu_alu_src2_sel == 2'b01 ? portD_data:
					  hu_alu_src2_sel == 2'b10 ? alu_output:
					  2'dx; // NOT TESTED

	wire [4:0] alu_mem_control_EX_MEM;
	wire [31:0] source2_reg_value_EM;

	ALU_STAGE alu (.clk(clk), .reset(reset),
		       .input1(alu_src1), .input2(alu_src2),
		       .next_program_counter(next_program_counter_DA),
		       .branch_dest(branch_dest),
		       .alu_operation(alu_operation),
		       .alu_output(alu_output),
		       .alu_out_branch_enable(alu_branch_enable_w),
		       .alu_out_branch_address(alu_branch_address_w),
		       .in_dest_register_enable(dest_register_enable_DA),
		       .in_passthrough_dest_register_number(dest_register_number_DA),
		       .out_dest_register_enable(dest_register_enable_AW),
		       .out_passthrough_dest_register_number(dest_register_number_AW),
		       .out_passthrough_operation(alu_mem_control_EX_MEM),
		       .in_passthrough_source2_reg_value(alu_src3),
		       .out_passthrough_source2_reg_value(source2_reg_value_EM));

	wire [31:0] dest_register_value_MEM_WB;
	wire dest_register_write_enable_MEM_WB;
	wire [4:0] dest_register_key_MEM_WB;

	MEMORY_STAGE mem (.clk(clk), .reset(reset),
			  .ex_in_operation_l(alu_mem_control_EX_MEM),

			  .ex_in_alu_output_l(alu_output),
			  .ex_in_rd_en_l(dest_register_enable_AW),
			  .ex_in_rd_key_l(dest_register_number_AW),

			  .ex_in_store_register_w(source2_reg_value_EM),

			  .mem_out_rd_value_l(dest_register_value_MEM_WB),
			  .mem_out_rd_en_l(dest_register_write_enable_MEM_WB),
			  .mem_out_rd_key_l(dest_register_key_MEM_WB),

			  .mem_out_memory_we2_l(memory_write_enable2),
			  .mem_out_memory_address_l(memory_address_bus2),
			  .mem_out_memory_data_l(memory_data_bus2));

	WRITEBACK_STAGE wb (.clk(clk), .reset(reset),
			    .enable(dest_register_write_enable_MEM_WB),
			    .is_dest_special(FALSE),
			    .dest_register(dest_register_key_MEM_WB),
			    .result(dest_register_value_MEM_WB),

			    .portD_enable(portD_enable),
			    .portD_key(portD_key),
			    .portD_value(portD_data));

endmodule
