module SYSTEM (
	       input clk,
	       input reset
	       );

	wire [31:0] memory_address_bus, memory_data_bus;

	MEMORY #(.NUM_WORDS(64)) memory (.reset(reset), .memory_address(memory_address_bus), .memory_data(memory_data_bus));

	CPU cpu (.reset(reset), .clk(clk), .memory_address_bus(memory_address_bus), .memory_data_bus(memory_data_bus));


endmodule
