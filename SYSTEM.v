module SYSTEM (
	       input clk,
	       input reset
	       );

	wire [31:0] memory_address_bus1, memory_data_bus1, memory_address_bus2, memory_data_bus2;
	wire memory_write_enable2_w;

	MEMORY #(.NUM_BYTES(1024)) memory (.clk(clk),
					 .memory_address1(memory_address_bus1),
					 .memory_data1(memory_data_bus1),
					 .memory_write_enable2(memory_write_enable2_w),
					 .memory_address2(memory_address_bus2),
					 .memory_data2(memory_data_bus2));

	CPU cpu (.reset(reset), .clk(clk),
		 .memory_address_bus1(memory_address_bus1),
		 .memory_data_bus1(memory_data_bus1),

		 .memory_address_bus2(memory_address_bus2),
		 .memory_data_bus2(memory_data_bus2),
		 .memory_write_enable2(memory_write_enable2_w)
		 );


endmodule
