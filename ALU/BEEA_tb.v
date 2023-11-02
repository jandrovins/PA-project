module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=10
	// initial `probe_start;   // Start the timing diagram

	// `probe(clk);        // Probe signal "clk"

	reg opselect = 0;
	reg [31:0] u, a;
	wire [31:0] outU;
        wire rdy;

	// `probe(rdy);
	// `probe(outU);
	// `probe(opselect);

	beea inst (.clk(clk), .opselect(opselect), .k(u), .p(a), .outC(outU), .rdy(rdy));

	initial begin
		$dumpvars(0, u);
		$dumpvars(0, outU);
		$dumpvars(0, rdy);
		$dumpvars(0, opselect);
		u = 32'd4;
		a = 32'd9; // Compute the inverse of 4 mod 9
		opselect = 1; // Send signal to start computation
		#2 opselect = 0; // Clear signal so that the computation is done only once
		#30 $finish;	// Quit the simulation
	end
endmodule

