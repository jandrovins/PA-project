

/*
 * An async-read, sync-write memory emulator. It has a size of NUM_BYTES bytes,
 * which can be easily set at instantiation time, and outputs a word
 * composed of WORD_SIZE_BYTES bytes. For emulation purposes, it is
 * initialized with the contents of the INITIAL_MEMORY_FILE file.
 */

module MEMORY #(
		parameter INITIAL_MEMORY_FILE = "mem32b.txt",
		parameter WORD_SIZE_BYTES = 4,
		parameter NUM_BYTES = 1024
		) (
		   input clk,

		   // Read-only asynchronous port 1, suitable for the fetch stage
		   input [(WORD_SIZE_BYTES*8)-1:0] memory_address1,
		   output [(WORD_SIZE_BYTES*8)-1:0] memory_data1,

		   // Read-write port 2, suitable for memory stage
		   // This port can be read asynchronously, but writes
		   // are done synchronously at clk posedge.
		   input memory_write_enable2,
		   input [(WORD_SIZE_BYTES*8)-1:0] memory_address2,
		   inout [(WORD_SIZE_BYTES*8)-1:0] memory_data2
		   );

	initial begin
		$readmemh(INITIAL_MEMORY_FILE, memory);
	end
	genvar memoryaddress;
	generate for(memoryaddress = 512; memoryaddress <= 550; memoryaddress = memoryaddress + 1)
		initial $dumpvars(0, memory[memoryaddress]);		
	endgenerate
	generate for(memoryaddress = 1270; memoryaddress <= 1290; memoryaddress = memoryaddress + 1)
		initial $dumpvars(0, memory[memoryaddress]);	
	endgenerate

	reg [7:0] memory [0:NUM_BYTES-1];

	genvar bytenumber;
	generate for(bytenumber = 0; bytenumber < WORD_SIZE_BYTES; bytenumber = bytenumber + 1)
		assign memory_data1[(bytenumber+1)*8-1 : bytenumber*8] = memory[memory_address1 + (WORD_SIZE_BYTES - 1 - bytenumber)];
	endgenerate

	generate for(bytenumber = 0; bytenumber < WORD_SIZE_BYTES; bytenumber = bytenumber + 1)
		assign memory_data2[(bytenumber+1)*8-1 : bytenumber*8] = memory_write_enable2 ? 8'bz : memory[memory_address2 + (WORD_SIZE_BYTES - 1 - bytenumber)];
	endgenerate

	wire [31:0] next_memory_value;
	assign next_memory_value = memory_write_enable2 ? memory_data2 : {memory[memory_address2+0], memory[memory_address2+1], memory[memory_address2+2], memory[memory_address2+3]};

	always @(posedge clk) begin
		memory[memory_address2+0] <= next_memory_value[31:24];
		memory[memory_address2+1] <= next_memory_value[23:16];
		memory[memory_address2+2] <= next_memory_value[15: 8];
		memory[memory_address2+3] <= next_memory_value[ 7: 0];
	end // always @ (posedge clk)

endmodule
