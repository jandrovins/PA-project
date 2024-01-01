
module WRITEBACK_STAGE (
			input clk,
			input reset,
			input enable,

			input is_dest_special,
			input [4:0] dest_register,
			input [31:0] result,

			output reg portD_enable,
			output reg [4:0] portD_key,
			output reg [31:0] portD_value
			);

`include "RISCV_constants.vinc"
`include "STD_constants.vinc"

	wire next_portD_enable;
	wire [4:0] next_portD_key;
	wire [31:0] next_portD_value;

	assign next_portD_enable = !enable ? FALSE :
				    is_dest_special && dest_register == 5'b0 ? TRUE : // Use register 0 from register file only if special requested
				   !is_dest_special && dest_register != 5'b0 ? TRUE : // Use register file if register 0 is not requested
				   FALSE;

	assign next_portD_key = dest_register;
	assign next_portD_value = result;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			portD_enable <= FALSE;
			portD_key <= x0;
			portD_value <= 32'b0;
		end else begin // if (reset)
			portD_enable <= next_portD_enable;
			portD_key <= next_portD_key;
			portD_value <= next_portD_value;
		end
	end // always @ (posedge clk, posedge reset)


endmodule
