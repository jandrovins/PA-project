

module REGISTER_FILE(
		     input clk,
		     input [4:0] rf_port1_key,
		     input [4:0] rf_port2_key,

		     input rf_portD_enable,
		     input [4:0] rf_portD_key,
		     input [31:0] rf_portD_value,

		     output [31:0] rf_port1_value,
		     output [31:0] rf_port2_value);

	genvar i;

	generate for(i = 0; i < 32; i = i + 1)
	  initial $dumpvars(0, registers[i]);
	endgenerate



	// When reading x0 a constant is returned. At position 0
	// the content of a special register is stored
	reg [31:0] registers [31:0];
	initial registers[3] = 32'b0;
	wire [31:0] next_rf_portD_value, rf_port1_value_wire;

	function [31:0] rf_port_value(input rf_portD_enable,
				   input [4:0] rf_portD_key,
				   input [31:0] rf_portD_value,
				   input [31:0] value_in_register_file,
				   input [4:0] rf_port_key);
		rf_port_value = rf_port_key == 5'b0 ? 32'b0 : // If requested x0
			     rf_portD_enable && rf_portD_key == rf_port_key ? rf_portD_value : // If requested a value that is being written
			     value_in_register_file; // Any other case is a "normal" access
	endfunction // rf_port_value


	assign rf_port1_value = rf_port_value(rf_portD_enable, rf_portD_key, rf_portD_value, registers[rf_port1_key], rf_port1_key);
	assign rf_port2_value = rf_port_value(rf_portD_enable, rf_portD_key, rf_portD_value, registers[rf_port2_key], rf_port2_key);

	assign next_rf_portD_value = rf_portD_enable && rf_portD_key != 5'b0 ? rf_portD_value :
				  registers[rf_portD_key];

	always @(posedge clk) begin
		registers[rf_portD_key] <= next_rf_portD_value;
		registers[0] <= 32'b0;
	end // always @ (posedge clk, posedge reset)

endmodule
