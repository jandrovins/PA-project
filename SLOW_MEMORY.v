/*
 * An sync-read, sync-write, 5 cycle latency memory emulator. It has a size of NUM_BYTES bytes,
 * which can be easily set at instantiation time, and outputs a word
 * composed of DATA_SIZE_BYTES bytes. For emulation purposes, it is
 * initialized with the contents of the INITIAL_MEMORY_FILE file.
 * Neither address or data is latched, so it must be kept in the bus for
 * the 5 cycles. Start signal can be reset at any time before starting and rdy.
 */

module SLOW_MEMORY #(
		parameter INITIAL_MEMORY_FILE = "mem32b.txt",
		parameter DATA_SIZE_BYTES = 4,
		parameter NUM_BYTES = 1024
		) (
		   input clk,
		   input reset,

		   // Read-write port
		   input memory_start,
		   output memory_rdy,
		   input memory_write_enable,
		   input [31:0] memory_address,
		   inout [(DATA_SIZE_BYTES*8)-1:0] memory_data
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

	// Every operation will keep mem busy for 5 cycles. This
	// counter will keep track of that emulated latency
	reg[2:0] cycle_counter;

	wire [2:0] next_cycle_counter;
	assign next_cycle_counter = cycle_counter == 3'b111 && memory_start == 1'b0 ? cycle_counter :
				    cycle_counter == 3'b111 && memory_start == 1'b1 ? 3'b000 :
				    cycle_counter == 3'd4 ? 3'b111 :
				    cycle_counter + 1;

	reg [(DATA_SIZE_BYTES*8)-1:0] data_out;
	wire [(DATA_SIZE_BYTES*8)-1:0] next_data_out;

	genvar bytenumber;
	generate for(bytenumber = 0; bytenumber < DATA_SIZE_BYTES; bytenumber = bytenumber + 1)
		assign next_data_out[(bytenumber+1)*8-1 : bytenumber*8] = cycle_counter == 3'd4 && memory_write_enable ? 8'bz :
									  cycle_counter == 3'd4 && !memory_write_enable ? memory[memory_address + (DATA_SIZE_BYTES - 1 - bytenumber)] :
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
