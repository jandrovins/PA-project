module SYSTEM (
	       input clk,
	       input reset
	       );

	wire [127:0] memory_data_bus1;
	wire [31:0] memory_address_bus1, memory_address_bus2, memory_data_bus2;
	wire memory_write_enable2_w, imem_read_start, imem_read_rdy;

	MEMORY #(.NUM_BYTES(4096), .INITIAL_MEMORY_FILE("mem_data.txt")) dmemory (.clk(clk),
					 .memory_address1(32'bx),
					 .memory_write_enable2(memory_write_enable2_w),
					 .memory_address2(memory_address_bus2),
					 .memory_data2(memory_data_bus2));
	
	SLOW_MEMORY #(.DATA_SIZE_BYTES(16), .NUM_BYTES(1024), .INITIAL_MEMORY_FILE("mem_programs.txt")) imemory (.clk(clk),
			     .reset(reset),

			     .memory_address(memory_address_bus1),
			     .memory_data(memory_data_bus1),
			     .memory_start(imem_read_start),
			     .memory_rdy(imem_read_rdy),
			     .memory_write_enable(1'b0));

	CPU cpu (.reset(reset), .clk(clk),
		 .imemory_address_bus1(memory_address_bus1),
		 .imemory_data_bus1(memory_data_bus1),
	     .imem_read_rdy(imem_read_rdy),
		 .imem_read_start(imem_read_start),


		 .memory_address_bus2(memory_address_bus2),
		 .memory_data_bus2(memory_data_bus2),
		 .memory_write_enable2(memory_write_enable2_w)
		 
		 );


endmodule
