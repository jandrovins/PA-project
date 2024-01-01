module SYSTEM_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	reg reset;

	SYSTEM cpu (.clk(clk), .reset(reset));

	initial begin
		$dumpvars(0, SYSTEM_tb);
		reset = 1;
		#11 reset = 0;

		#25 $finish;
	end
endmodule // FETCH_STAGE_tb
