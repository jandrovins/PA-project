

module MEMORY #(
		parameter INITIAL_MEMORY_FILE = "mem32b.txt",
		parameter WORD_SIZE_BYTES = 4,
		parameter NUM_WORDS = 1024
		) (
		   input reset,
		   input [(WORD_SIZE_BYTES*8)-1:0] memory_address,

		   output [(WORD_SIZE_BYTES*8)-1:0] memory_data);

	initial begin
		$readmemh(INITIAL_MEMORY_FILE, memory);
	end

	reg [7:0] memory [0:NUM_WORDS-1];

	genvar bytenumber;

	generate for(bytenumber = 0; bytenumber < WORD_SIZE_BYTES; bytenumber = bytenumber + 1)
		assign memory_data[(bytenumber+1)*8-1 : bytenumber*8] = memory[memory_address + (WORD_SIZE_BYTES - 1 - bytenumber)];
	endgenerate

endmodule
