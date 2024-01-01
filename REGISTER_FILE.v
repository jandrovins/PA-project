

module REGISTER_FILE(
		     input clk,
		     input [4:0] port1_key,
		     input [4:0] port2_key,

		     input portD_enable,
		     input [4:0] portD_key,
		     input [31:0] portD_value,

		     output [31:0] port1_value,
		     output [31:0] port2_value);

	genvar i;

	generate for(i = 0; i < 32; i = i + 1)
	  initial $dumpvars(0, registers[i]);
	endgenerate

	// When reading x0 a constant is returned. At position 0
	// the content of a special register is stored
	reg [31:0] registers [31:0];

	wire [31:0] next_portD_value, port1_value_wire;

	function [31:0] port_value(input portD_enable,
				   input [4:0] portD_key,
				   input [31:0] portD_value,
				   input [31:0] value_in_register_file,
				   input [4:0] port_key);
		port_value = port_key == 5'b0 ? 32'b0 : // If requested x0
			     portD_enable && portD_key == port_key ? portD_value : // If requested a value that is being written
			     value_in_register_file; // Any other case is a "normal" access
	endfunction // port_value


	assign port1_value = port_value(portD_enable, portD_key, portD_value, registers[port1_key], port1_key);
	assign port2_value = port_value(portD_enable, portD_key, portD_value, registers[port2_key], port2_key);

	assign next_portD_value = portD_enable && portD_key != 5'b0 ? portD_value :
				  registers[portD_key];

	always @(posedge clk) begin
		registers[portD_key] <= next_portD_value;
		registers[0] <= 32'b0;
	end // always @ (posedge clk, posedge reset)

endmodule
