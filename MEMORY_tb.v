
module MEMORY_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	reg [31:0] memory_address_bus1;
	wire [31:0] memory_data_bus1;

	reg memory_write_enable2;
	reg [31:0] memory_address_bus2;
	wire [31:0] memory_data_bus2;
	reg [31:0] memory_data_bus2_latch;

	integer curAddress;

	MEMORY #(.INITIAL_MEMORY_FILE("mem32b.txt"),
		 .NUM_BYTES(64)
		 ) dut (.clk(clk),
			.memory_address1(memory_address_bus1),
			.memory_data1(memory_data_bus1),

			.memory_write_enable2(memory_write_enable2),
			.memory_address2(memory_address_bus2),
			.memory_data2(memory_data_bus2)
			);

	assign memory_data_bus2 = memory_write_enable2 == 1'b0 ? 32'bz :  memory_data_bus2_latch;


	initial begin
		$dumpvars(0, MEMORY_tb);

		// curAddress = 32'h0;

		// while (curAddress != 32'd64) begin
		// 	@(negedge clk) memory_address_bus = curAddress;
		// 	#2 if(memory_data_bus != curAddress << 16 | curAddress) $write("ERROR\n");
		// 	curAddress = curAddress + 1;
		// end

		memory_write_enable2 = 1'b0;
		memory_address_bus2 = 32'd0;

		@(negedge clk) if(memory_data_bus2 != 32'h00000000) $write("ERROR\n");


		memory_write_enable2 = 1'b0;
		memory_address_bus2 = 32'd4;

		@(negedge clk) if(memory_data_bus2 != 32'h00010001) $write("ERROR\n");


		memory_write_enable2 = 1'b0;
		memory_address_bus2 = 32'd8;

		@(negedge clk) if(memory_data_bus2 != 32'h00020002) $write("ERROR\n");


		memory_write_enable2 = 1'b1;
		memory_address_bus2 = 32'd4;
		memory_data_bus2_latch = 32'h01234567;

		@(negedge clk) if(memory_data_bus2 != 32'h01234567) $write("ERROR\n");

		memory_write_enable2 = 1'b0;
		memory_address_bus2 = 32'd8;

		@(negedge clk) if(memory_data_bus2 != 32'h00020002) $write("ERROR\n");

		memory_write_enable2 = 1'b0;
		memory_address_bus2 = 32'd4;

		@(negedge clk) if(memory_data_bus2 != 32'h01234567) $write("ERROR\n");



		$finish;
	end
endmodule // FETCH_STAGE_tb
