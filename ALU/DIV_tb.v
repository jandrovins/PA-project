module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2

	reg divStart, reset, signedness;
	reg signed [31:0] a, b;
	wire signed [31:0] outDiv, outRem;
        wire rdy;
	reg [31:0] testNumber;
	reg ERROR;

	DIV inst (.clk(clk), .reset(reset), .start(divStart), .signedness(signedness), .a(a), .b(b), .q(outDiv), .r(outRem), .rdy(rdy));

	integer numTests, remainingTests, lastRemainingTestsReported;
	integer testDataFd, bytesRead, exitLoop, expectedDiv, expectedRem;
	reg[8*1000:0] comment;
	initial begin
		$dumpvars(0, top_module);
		divStart = 1'b0;
		reset = 1;
		ERROR = 0;
		#1 reset = 0;

		$write("Loading test data file: DIV_td.csv\n");
		testDataFd = $fopen("DIV_td.csv", "r");
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
				#2 divStart = 0;
				@(posedge rdy) if(outDiv == expectedDiv && outRem == expectedRem) begin
					$write("OK.\n");
				end else begin
					$write("ERROR. Actual a/b = %0d, a%%b = %0d\n", outDiv, outRem);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end // else: !if(bytesRead == 0)
		end
		$fclose(testDataFd);
		//$finish;




		numTests = 2000;
		$write("Start fuzzying. Will run %0d tests\n", numTests);
		remainingTests = numTests;
		lastRemainingTestsReported = remainingTests;
		$write("%f%%\n", 0.0);
		signedness = 1'b1;
		while (remainingTests > numTests/2) begin
			a = $random;
			a = a % (2 ** 16);
			b = $random;
			// TODO: Como divStart se levanta junto con clock, si el pulso es corto
			// el módulo no pilla esta señal. Alguna solución mejor?
			@(posedge clk) divStart = 1;
			#3 divStart = 0;
			@(posedge rdy) if(b == 32'b0) begin
				// These 2 ifs cannot be merged into 1, because is b is zero, we don't want the
				// (outDiv * b + outRem != a) evaluated
				if(outDiv != -1) begin
					$write("ERROR test: a = %0d, b = 0. Expected quotient: -1, output quotient: %0d\n", a, outDiv);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end else if (outDiv * b + outRem != a) begin
				$write("ERROR test: a = %0d, b = %0d. Expected quotient & remainder: %0d, %0d, output quotient & remainder: %0d, %0d\n", a, b, a/b, a-(a/b)*b, outDiv, outRem);
				ERROR = 1;
				#1 ERROR = 0;
			end
			if (lastRemainingTestsReported - remainingTests >= 100) begin
				lastRemainingTestsReported = remainingTests;
				$write("%f%%\n", (numTests-remainingTests)*100.0/numTests);
			end
			remainingTests = remainingTests-1;
		end // while (remainingTests > numTests/2)
		while (remainingTests > 0) begin
			a = $random;
			b = $random;
			b = b % (2 ** 23);
			// TODO: Como divStart se levanta junto con clock, si el pulso es corto
			// el módulo no pilla esta señal. Alguna solución mejor?
			divStart = 1;
			#3 divStart = 0;
			@(posedge rdy) if(b == 32'b0) begin
				// These 2 ifs cannot be merged into 1, because is b is zero, we don't want the
				// (outDiv * b + outRem != a) evaluated
				if(outDiv != -1) begin
					$write("ERROR test: a = %0d, b = 0. Expected quotient: -1, output quotient: %0d\n", a, outDiv);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end else if (outDiv * b + outRem != a) begin
				$write("ERROR test: a = %0d, b = %0d. Expected quotient & remainder: %0d, %0d, output quotient & remainder: %0d, %0d\n", a, b, a/b, a-(a/b)*b, outDiv, outRem);
				ERROR = 1;
				#1 ERROR = 0;
			end
			if (lastRemainingTestsReported - remainingTests >= 100) begin
				lastRemainingTestsReported = remainingTests;
				$write("%f%%\n", (numTests-remainingTests)*100.0/numTests);
			end
			remainingTests = remainingTests-1;
		end // while (numTests > 0)
		$write("%f%%\n", 100.0);
		$write("Done.\n");
		$finish;
	end // initial begin

endmodule // top_module
