
module CPU_tb();
	reg clk=1;
	always #1 clk = ~clk;  // Create clock with period=2

	reg reset;

	CPU cpu (.clk(clk), .reset(reset));

	initial begin
		$dumpvars(0, CPU_tb);
		reset = 1;
		#11 reset = 0;

		#99 $finish;
	end
endmodule // CPU_tb

