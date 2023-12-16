module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	localparam testDataFileName = "DIV_td.csv",
		   numTests = 2000;

	reg divStart, reset, signedness;
	reg signed [31:0] a, b;
	wire signed [31:0] outDiv, outRem;
        wire busy;
	reg [31:0] testNumber;
	reg ERROR;

	DIV dut (.clk(clk), .reset(reset), .start(divStart), .signedness(signedness), .a(a), .b(b), .q(outDiv), .r(outRem), .busy(busy));

	integer remainingTests, lastRemainingTestsReported;
	integer testDataFd, bytesRead, exitLoop, expectedDiv, expectedRem;
	//reg [8*1000:0] null;

	initial begin
		$dumpvars(0, top_module);
		divStart = 1'b0;
		reset = 1;
		ERROR = 0;
		#1 reset = 0;

		$write("Loading test data file: %s\n", testDataFileName);
		testDataFd = $fopen(testDataFileName, "r");
		if (testDataFd == 0) begin
			$write("ERROR. Data file not found\n");
			$finish;
		end
		exitLoop = 0;
		while (!exitLoop && ! $feof(testDataFd)) begin
			#20 bytesRead = $fscanf(testDataFd, "%d,%d,%d,%d,%d\n", a, b, signedness, expectedDiv, expectedRem);
			if (bytesRead > 0) begin
				$write("Starting test: a = %0d, b = %0d, signedness = %0d. Expected a/b = %0d, a%%b = %0d... ", a, b, signedness, expectedDiv, expectedRem);
				// TODO: Como divStart se levanta junto con clock, si el pulso es corto
				// el módulo no pilla esta señal. Alguna solución mejor?
				@(negedge clk) divStart = 1;
				@(posedge busy) divStart = 0;
				@(negedge busy) if(outDiv == expectedDiv && outRem == expectedRem) begin
					$write("OK.\n");
				end else begin
					$write("ERROR. Actual a/b = %0d, a%%b = %0d\n", outDiv, outRem);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end // else: !if(bytesRead > 0)
		end
		$fclose(testDataFd);

		/* End of tests cases, begin fuzzying */

		$write("Start fuzzying. Will run %0d tests\n", numTests);
		remainingTests = numTests;
		lastRemainingTestsReported = remainingTests;
		$write("%f%%\n", 0.0);
		signedness = 1'b1;
		while (remainingTests > 0) begin
			a = $random;
			a = (remainingTests > numTests/2) ? a % (2 ** 16) : a;
			b = $random;
			b = !(remainingTests > numTests/2) ? b % (2 ** 23) : b;
			// TODO: Como divStart se levanta junto con clock, si el pulso es corto
			// el módulo no pilla esta señal. Alguna solución mejor?
			@(posedge clk) divStart = 1;
			@(posedge busy) divStart = 0;
			@(negedge busy) if(b == 32'b0) begin
				// These 2 ifs cannot be merged into 1, because is b is zero, we don't want the
				// (outDiv * b + outRem != a) evaluated
				if(outDiv != -1) begin
					$write("ERROR test: a = %0d, b = 0. Expected quotient: -1, output quotient: %0d\n", a, outDiv);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end else if (outDiv != a/b) begin
				$write("ERROR test: a = %0d, b = %0d. Expected quotient: %0d, output quotient: %0d\n", a, b, a/b, outDiv);
				ERROR = 1;
				#1 ERROR = 0;
			end else if (outRem != a-(a/b)*b) begin
				$write("ERROR test: a = %0d, b = %0d. Expected remainder: %0d, output remainder: %0d\n", a, b, a-(a/b)*b, outRem);
				ERROR = 1;
				#1 ERROR = 0;
			end
			if (lastRemainingTestsReported - remainingTests >= 100) begin
				lastRemainingTestsReported = remainingTests;
				$write("%f%%\n", (numTests-remainingTests)*100.0/numTests);
			end
			remainingTests = remainingTests-1;
		end

		$write("%f%%\n", 100.0);
		$write("Done.\n");
		$finish;
	end // initial begin

endmodule // top_module
