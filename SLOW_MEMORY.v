

/*
 * An sync-read, sync-write, 5 cycle latency memory emulator. It has a size of NUM_BYTES bytes,
 * which can be easily set at instantiation time, and outputs a word
 * composed of WORD_SIZE_BYTES bytes. For emulation purposes, it is
 * initialized with the contents of the INITIAL_MEMORY_FILE file.
 * Neither address or data is latched, so it must be kept in the bus for
 * the 5 cycles. Start signal can be reset at any time before starting and rdy.
 */

module SLOW_MEMORY #(
		parameter INITIAL_MEMORY_FILE = "mem32b.txt",
		parameter WORD_SIZE_BYTES = 4,
		parameter NUM_BYTES = 1024
		) (
		   input clk,
		   input reset,

		   // Read-write port
		   input memory_start,
		   output memory_rdy,
		   input memory_write_enable,
		   input [(WORD_SIZE_BYTES*8)-1:0] memory_address,
		   inout [(WORD_SIZE_BYTES*8)-1:0] memory_data
		   );

	initial begin
		$readmemh(INITIAL_MEMORY_FILE, memory);
	end

	reg [7:0] memory [0:NUM_BYTES-1];

	// Every operation will keep mem busy for 5 cycles. This
	// counter will keep track of that emulated latency
	reg[2:0] cycle_counter;

	wire [2:0] next_cycle_counter;
	assign next_cycle_counter = cycle_counter == 3'b111 && memory_start == 1'b0 ? cycle_counter :
				    cycle_counter == 3'b111 && memory_start == 1'b1 ? 3'b000 :
				    cycle_counter == 3'd4 ? 3'b111 :
				    cycle_counter + 1;

	reg [31:0] data_out;
	wire [31:0] next_data_out;

	genvar bytenumber;
	generate for(bytenumber = 0; bytenumber < WORD_SIZE_BYTES; bytenumber = bytenumber + 1)
		assign next_data_out[(bytenumber+1)*8-1 : bytenumber*8] = cycle_counter == 3'd4 && memory_write_enable ? 8'bz :
									  cycle_counter == 3'd4 && !memory_write_enable ? memory[memory_address + (WORD_SIZE_BYTES - 1 - bytenumber)] :
									  data_out[(bytenumber+1)*8-1 : bytenumber*8];
	endgenerate

	assign memory_data = data_out;

	wire [31:0] next_memory_value;
	assign next_memory_value = cycle_counter == 3'd4 && memory_write_enable ? memory_data : {memory[memory_address+0], memory[memory_address+1], memory[memory_address+2], memory[memory_address+3]};

	assign memory_rdy = cycle_counter == 3'b111;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			cycle_counter <= 3'b111;
			data_out <= 32'b0;
		end else begin
			cycle_counter <= next_cycle_counter;
			data_out <= next_data_out;
			memory[memory_address+0] <= next_memory_value[31:24];
			memory[memory_address+1] <= next_memory_value[23:16];
			memory[memory_address+2] <= next_memory_value[15: 8];
			memory[memory_address+3] <= next_memory_value[ 7: 0];
		end
	end // always @ (posedge clk)

endmodule
