
module SLOW_MEMORY_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2


	reg reset, ERROR;

	reg [31:0] mem_address;

	wire [31:0] mem_data;

	reg mem_read_start;
	wire mem_read_rdy;

	SLOW_MEMORY #() dut (.clk(clk),
			     .reset(reset),

			     .memory_address(mem_address),
			     .memory_data(mem_data),
			     .memory_start(mem_read_start),
			     .memory_rdy(mem_read_rdy),
			     .memory_write_enable(1'b0));

	initial begin
		$dumpvars(0, SLOW_MEMORY_tb);

		ERROR = 1'b0;
		mem_address = 32'h00000000;
		reset = 1'b1;
		mem_read_start = 1'b0;
		#2 reset = 1'b0;

		mem_address = 32'h00000020;
		mem_read_start = 1'b1;
		#3 mem_read_start = 1'b0;

		@(posedge mem_read_rdy) if(mem_data != 32'h00168693) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end

		#10 $finish;
	end
endmodule // FETCH_STAGE_tb
