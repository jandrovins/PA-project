

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
		$dumpvars(0, memory[0]);
		$dumpvars(0, memory[1]);
		$dumpvars(0, memory[2]);
		$dumpvars(0, memory[3]);
		$dumpvars(0, memory[4]);
		$dumpvars(0, memory[5]);
		$dumpvars(0, memory[6]);
		$dumpvars(0, memory[7]);
		$dumpvars(0, memory[8]);
		$dumpvars(0, memory[9]);
		$dumpvars(0, memory[10]);
		$dumpvars(0, memory[11]);
		$dumpvars(0, memory[12]);
		$dumpvars(0, memory[13]);
		$dumpvars(0, memory[14]);
		$dumpvars(0, memory[15]);
		$dumpvars(0, memory[16]);
		$dumpvars(0, memory[17]);
		$dumpvars(0, memory[18]);
		$dumpvars(0, memory[19]);
		$dumpvars(0, memory[20]);
		$dumpvars(0, memory[21]);
	end

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
