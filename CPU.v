
module CPU (
	    input clk,
	    input reset,

	    input [31:0] memory_data_bus1,
	    output [31:0] memory_address_bus1,

	    input memory_write_enable2,
	    inout [31:0] memory_data_bus2,
	    output [31:0] memory_address_bus2
	    );


`include "STD_constants.vinc"

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

	wire [31:0] current_program_counter, next_program_counter;
	
	wire [31:0] alu_branch_address_w;
	wire alu_branch_enable_w;

	FETCH_STAGE #(.INITIAL_PC(32'h10))
	fetch (.clk(clk), .reset(reset),
	       .fst_in_branch_address(alu_branch_address_w),
	       .fst_in_branch_enable(alu_branch_enable_w),
	       .fst_out_instr_address(memory_address_bus1),
	       .fst_in_instr(memory_data_bus1),
	       .fst_out_instr(instruction_register),
	       .fst_out_pc(current_program_counter),
	       .fst_out_pc_next(next_program_counter));

	wire dest_register_enable_DA, dest_register_enable_AW;
	wire [4:0] dest_register_number_DA, dest_register_number_AW;
	wire [31:0] next_program_counter_DA, branch_dest;
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
			     .branch_dest(branch_dest));

	wire [31:0] alu_src1, alu_src2;
	wire [1:0] hu_src1_sel, hu_src2_sel;

	HAZARD_UNIT hu (
		.clk(clk),
		.reset(reset),

		.instr_src1_key(operand1_key),
		.instr_src2_key(operand2_key),
		.mst_rd_key(dest_register_number_AW),
		.mst_rd_en(dest_register_enable_AW),
		.wst_rd_key(portD_key),
		.wst_rd_en(portD_enable),

		.alu_src1_sel(hu_src1_sel),
		.alu_src2_sel(hu_src2_sel)
	);

	assign alu_src1 = hu_src1_sel == 2'b00 ? operand1 :
					  hu_src1_sel == 2'b01 ? portD_data:
					  hu_src1_sel == 2'b10 ? alu_output:
					  2'dx;
	assign alu_src2 = hu_src2_sel == 2'b00 ? operand2 :
					  hu_src2_sel == 2'b01 ? portD_data:
					  hu_src2_sel == 2'b10 ? alu_output:
					  2'dx; // NOT TESTED

	wire [4:0] alu_mem_control_EX_MEM;

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
		       .out_passthrough_operation(alu_mem_control_EX_MEM));

	wire [31:0] dest_register_value_MEM_WB;
	wire dest_register_write_enable_MEM_WB;
	wire [4:0] dest_register_key_MEM_WB;

	MEMORY_STAGE mem (.clk(clk), .reset(reset),
			  .ex_in_operation_l(alu_mem_control_EX_MEM),

			  .ex_in_alu_output_l(alu_output),
			  .ex_in_rd_en_l(dest_register_enable_AW),
			  .ex_in_rd_key_l(dest_register_number_AW),

			  .ex_in_store_register_w(), // TODO

			  .mem_out_rd_value_l(dest_register_value_MEM_WB),
			  .mem_out_rd_en_l(dest_register_write_enable_MEM_WB),
			  .mem_out_rd_key_l(dest_register_key_MEM),

			  .mem_out_memory_we2_l(memory_write_enable2),
			  .mem_out_memory_address_l(memory_address_bus2),
			  .mem_out_memory_data_l(memory_data_bus2),

	WRITEBACK_STAGE wb (.clk(clk), .reset(reset),
			    .enable(dest_register_write_enable_MEM_WB),
			    .is_dest_special(FALSE),
			    .dest_register(dest_register_key_MEM),
			    .result(dest_register_value_MEM_WB),

			    .portD_enable(portD_enable),
			    .portD_key(portD_key),
			    .portD_value(portD_data));

endmodule
