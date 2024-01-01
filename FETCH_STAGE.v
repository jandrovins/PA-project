

module FETCH_STAGE #(
		     parameter INITIAL_PROGRAM_COUNTER = 32'h1000
		    ) (
		       input clk,
		       input reset,
		       input [31:0] branch_address,
		       input branch_address_enable,
		       input [31:0] memory_data,

		       output [31:0] memory_address,
		       output reg [31:0] instruction_register,
		       output reg [31:0] current_program_counter,
		       output reg [31:0] next_program_counter);

`include "RISCV_constants.vinc"

	wire [31:0] next_next_program_counter, next_instruction_register, next_memory_address;

	assign next_next_program_counter = branch_address_enable == 1'b1 ? branch_address + 32'd4 :
					   next_program_counter + 32'd4;

	assign next_instruction_register = memory_data;

	assign memory_address = branch_address_enable == 1'b1 ? branch_address :
				next_program_counter;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			next_program_counter <= INITIAL_PROGRAM_COUNTER;
			current_program_counter <= INITIAL_PROGRAM_COUNTER;
			instruction_register <= NOP; // Send NOP
		end else begin // if (reset)
			next_program_counter <= next_next_program_counter;
			instruction_register <= next_instruction_register;
			current_program_counter <= next_program_counter;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
