
module FETCH_STAGE_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	wire [31:0] memory_address_bus, memory_data_bus;
	reg reset, branch_address_enable;

	MEMORY #(.NUM_WORDS(64)) memory (.reset(reset), .memory_address(memory_address_bus), .memory_data(memory_data_bus));

	FETCH_STAGE #(.INITIAL_PC(32'h10)) dut (.clk(clk), .reset(reset),
	 		.fst_in_branch_address(32'b0),
			.fst_in_branch_enable(branch_address_enable),
			.fst_in_instr(memory_data_bus),
			.fst_out_instr_address(memory_address_bus));
	
	initial begin
		$dumpvars(0, FETCH_STAGE_tb);
		reset = 1;
		branch_address_enable = 1'b0;
		#11 reset = 0;

		#10 branch_address_enable = 1'b1;
		#2 branch_address_enable = 1'b0;
		#7 $finish;
	end
endmodule // FETCH_STAGE_tb

