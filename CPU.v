
module CPU (
	    input clk,
	    input reset,

	    input [31:0] memory_data_bus,
	    output [31:0] memory_address_bus
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

	wire [31:0] current_program_counter, next_program_counter, branch_address;
	wire branch_address_enable;

	FETCH_STAGE #(.INITIAL_PROGRAM_COUNTER(32'h10))
	fetch (.clk(clk), .reset(reset),
	       .branch_address(branch_address),
	       .branch_address_enable(branch_address_enable),
	       .memory_data(memory_data_bus),
	       .memory_address(memory_address_bus),
	       .instruction_register(instruction_register),
	       .next_program_counter(next_program_counter),
	       .current_program_counter(current_program_counter));

	wire dest_register_enable_DA, dest_register_enable_AW;
	wire [4:0] dest_register_number_DA, dest_register_number_AW;
	wire [3:0] bypass1, bypass2;
	wire [31:0] next_program_counter_DA, branch_dest;

	DECODE_STAGE decode (.clk(clk), .reset(reset),
			     .instruction_register(instruction_register),
			     .kill_instr(branch_address_enable),
			     .source1_register_key(port1_key),
			     .source2_register_key(port2_key),
			     .source1_register_value(port1_data),
			     .source2_register_value(port2_data),
			     .operand1(operand1),
			     .operand2(operand2),
			     .alu_operation(alu_operation),
			     .bypass1(bypass1),
			     .bypass2(bypass2),
			     .dest_register_enable(dest_register_enable_DA),
			     .dest_register_number(dest_register_number_DA),
			     .in_passthrough_next_program_counter(next_program_counter),
			     .out_passthrough_next_program_counter(next_program_counter_DA),
			     .current_program_counter(current_program_counter),
			     .branch_dest(branch_dest));

	ALU_STAGE alu (.clk(clk), .reset(reset),
		       .input1(operand1), .input2(operand2),
		       .next_program_counter(next_program_counter_DA),
		       .branch_dest(branch_dest),
		       .alu_operation(alu_operation),
		       .bypass1(bypass1),
		       .bypass2(bypass2),
		       .alu_output(alu_output),
		       .branch_address_enable(branch_address_enable),
		       .branch_address(branch_address),
		       .in_dest_register_enable(dest_register_enable_DA),
		       .in_passthrough_dest_register_number(dest_register_number_DA),
		       .out_dest_register_enable(dest_register_enable_AW),
		       .out_passthrough_dest_register_number(dest_register_number_AW));

	WRITEBACK_STAGE wb (.clk(clk), .reset(reset),
			    .enable(dest_register_enable_AW),
			    .is_dest_special(FALSE),
			    .dest_register(dest_register_number_AW),
			    .result(alu_output),

			    .portD_enable(portD_enable),
			    .portD_key(portD_key),
			    .portD_value(portD_data));

endmodule
