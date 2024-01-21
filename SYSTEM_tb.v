module SYSTEM_tb();
	reg clk=1;
	always #1 clk = ~clk;  // Create clock with period=2

	reg reset;

	SYSTEM cpu (.clk(clk), .reset(reset));

	initial begin
		$dumpvars(0, SYSTEM_tb);
		reset = 1;
		#10 reset = 0;

		#2000 $finish;
	end
endmodule // FETCH_STAGE_tb
