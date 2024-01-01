
module MEMORY_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	reg [31:0] memory_address_bus;
	wire [31:0] memory_data_bus;

	integer curAddress;

	MEMORY #(.INITIAL_MEMORY_FILE("mem32b.txt"), .NUM_WORDS(64)) dut (.reset(1'b0), .memory_address(memory_address_bus), .memory_data(memory_data_bus));

	initial begin
		$dumpvars(0, MEMORY_tb);

		curAddress = 32'h0;

		while (curAddress != 32'd64) begin
			@(negedge clk) memory_address_bus = curAddress;
			#2 if(memory_data_bus != curAddress << 16 | curAddress) $write("ERROR\n");
			curAddress = curAddress + 1;
		end


		$finish;
	end
endmodule // FETCH_STAGE_tb
