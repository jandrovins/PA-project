module top_module ();
	reg clk=0;
	always #1 clk = ~clk;

	reg beeaStart, reset;
	reg [31:0] u, a;
	wire [31:0] outU;
        wire rdy;
	reg ERROR;

	BEEA dut (.clk(clk), .start(beeaStart), .reset(reset), .k(u), .p(a), .outC(outU), .rdy(rdy));

	integer testDataFd, bytesRead, exitLoop;
	reg [31:0] expected;
	initial begin
		$dumpvars(0, top_module);
		beeaStart = 1'b0;
		reset = 1'b1;
		ERROR = 0;
		#2 reset = 1'b0;
		$write("Loading test data file: BEEA_td.csv\n");
		testDataFd = $fopen("BEEA_td.csv", "r");
		if (testDataFd == 0) begin
			$write("ERROR. Data file not found\n");
			$finish;
		end
		exitLoop = 0;
		while (!exitLoop && ! $feof(testDataFd)) begin
			bytesRead = $fscanf(testDataFd, "%d,%d,%d\n", u, a, expected);
			#2 if (bytesRead == 0) begin
				exitLoop = 1;
			end else begin
				$write("Starting test: u = %0d, a = %0d, expected = %0d... ", u, a, expected);
				// TODO: Como beeaStart se levanta junto con clock a veces
				// el módulo BEEA no pilla esta señal. Alguna solución mejor?
				beeaStart = 1;
				#3 beeaStart = 0;
				@(posedge rdy) if(outU == expected) begin
					$write("OK.\n");
				end else begin
					$write("ERROR. Expected: %0d, actual: %0d\n", expected, outU);
					ERROR = 1;
					#1 ERROR = 0;
				end
			end // else: !if(bytesRead == 0)
		end
		$fclose(testDataFd);
		$finish;
	end // initial begin

endmodule
