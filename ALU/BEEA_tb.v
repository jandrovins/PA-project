module top_module ();
	reg clk=0;
	always #1 clk = ~clk;

	reg opselect;
	reg [31:0] u, a;
	wire [31:0] outU;
	reg [63:0]  mult;
        wire rdy;
	reg [31:0] testNumber;
	reg ERROR;

	beea inst (.clk(clk), .opselect(opselect), .k(u), .p(a), .outC(outU), .rdy(rdy));

	initial begin
		$dumpvars(0, u);
		$dumpvars(0, a);
		$dumpvars(0, outU);
		$dumpvars(0, rdy);
		$dumpvars(0, opselect);
		$dumpvars(0, clk);
		$dumpvars(0, ERROR);
		$dumpvars(0, testNumber);
		testNumber = 32'd0;
		opselect = 1'b0;
		ERROR = 0;
	end // initial begin

	always @(posedge clk) begin
		if(rdy) begin
			$display("posedge rdy");
			case(testNumber)
			  0: begin
				  $display("launching test 1");
				  testNumber = 32'd1;
				  u = 32'd4;
				  a = 32'd9;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  1: begin
				  if(outU != 32'd7) begin
					  $display("ERROR in test 1");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 2");
				  testNumber = 32'd2;
				  u = 32'd8;
				  a = 32'd49;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  2: begin
				  if(outU != 32'd43) begin
					  $display("ERROR in test 2");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 3");
				  testNumber = 32'd3;
				  u = 32'd10;
				  a = 32'd81;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  3: begin
				  if(outU != 32'd73) begin
					  $display("ERROR in test 3");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 4");
				  testNumber = 32'd4;
				  u = 32'd12;
				  a = 32'd121;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  4: begin
				  if(outU != 32'd111) begin
					  $display("ERROR in test 4");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 5");
				  testNumber = 32'd5;
				  u = 32'd16;
				  a = 32'd225;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  5: begin
				  if(outU != 32'd211) begin
					  $display("ERROR in test 5");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 6");
				  testNumber = 32'd6;
				  u = 32'd20;
				  a = 32'd361;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  6: begin
				  if(outU != 32'd343) begin
					  $display("ERROR in test 6");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 7");
				  testNumber = 32'd7;
				  u = 32'd400;
				  a = 32'd159201;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  7: begin
				  if(outU != 32'd158803) begin
					  $display("ERROR in test 7");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 8");
				  testNumber = 32'd8;
				  u = 32'd1154;
				  a = 32'd1329409;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  8: begin
				  if(outU != 32'd1328257) begin
					  $display("ERROR in test 8");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 9");
				  testNumber = testNumber + 1;
				  u = 32'd1154;
				  a = 32'h7fffffff; // From now on, fixed at this value
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  9: begin
				  if(outU != 32'd154455063) begin
					  $display("ERROR in test 9");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 10");
				  testNumber = testNumber + 1;
				  u = 32'd897940;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  10: begin
				  if(outU != 32'd1229258249) begin
					  $display("ERROR in test 10");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 11");
				  testNumber = testNumber + 1;
				  u = 32'd873241;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  11: begin
				  if(outU != 32'd1451116319) begin
					  $display("ERROR in test 11");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 12");
				  testNumber = testNumber + 1;
				  u = 32'd1000;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  12: begin
				  if(outU != 32'd36507222) begin
					  $display("ERROR in test 12");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 13");
				  testNumber = testNumber + 1;
				  u = 32'd7;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  13: begin
				  if(outU != 32'd1840700269) begin
					  $display("ERROR in test 13");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  $display("launching test 14");
				  testNumber = testNumber + 1;
				  u = 32'd12865783;
				  opselect = 1;
				  #1 opselect = 0;
			  end
			  14: begin
				  if(outU != 32'd224318682) begin
					  $display("ERROR in test 14");
					  ERROR = 1;
					  #1 ERROR = 0;
				  end
				  #2 $finish;
			  end
			endcase // case (testNumber)
		end // if (rdy)
	end


endmodule

