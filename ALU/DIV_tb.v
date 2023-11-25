module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	reg divStart, reset;
	reg [30:0] a, b;
	wire [30:0] outDiv;
        wire rdy;
	reg [31:0] testNumber;
	reg ERROR;

	DIV inst (.clk(clk), .reset(reset), .start(divStart), .a(a), .b(b), ._div(outDiv), ._rdy(rdy));

	integer numTests;
	initial begin
		$dumpvars(0, top_module);
		divStart = 1'b0;
		reset = 1;
		ERROR = 0;
		#1 reset = 0;
		$write("Starting fuzzying...\n");
		numTests = 10000;
		while (numTests > 0) begin
			a = $random;
			a = a % (2**8);
			b = $random;
			b = b % (2**8);
			while (b == 31'b0) begin
				b = $random;
				b = b % (2**8);
			end
			// TODO: Como divStart se levanta junto con clock a veces
			// el módulo BEEA no pilla esta señal. Alguna solución mejor?
			divStart = 1;
			#3 divStart = 0;
			@(posedge rdy) if(((outDiv * b) % 2147483647) != a) begin
				$write("ERROR test: a = %0d, b = %0d. Output: %0d\n", a, b, outDiv);
				ERROR = 1;
				#1 ERROR = 0;
			end
			numTests = numTests-1;
		end // while (numTests > 0)
		$write("Done.\n");
		$finish;
	end // initial begin

endmodule // top_module
