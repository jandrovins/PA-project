module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=10

	reg opselect;
	reg [30:0] a, b;
	wire [30:0] outDiv;
        wire rdy;
	reg [31:0] testNumber;
	reg ERROR;

	div inst (.clk(clk), .opselect(opselect), .a(a), .b(b), ._div(outDiv), ._rdy(rdy));

	initial begin
		$dumpvars(0, a);
		$dumpvars(0, b);
		$dumpvars(0, outDiv);
		$dumpvars(0, rdy);
		$dumpvars(0, opselect);
		$dumpvars(0, clk);
		$dumpvars(0, ERROR);
		$dumpvars(0, testNumber);
		testNumber = 32'd0;
		ERROR = 0;
	end // initial begin

	always @(posedge rdy) begin
		$display("Hola");
		case(testNumber)
		  0: begin
			  testNumber = testNumber+1;
			  a = 31'd8;
			  b = 31'd4;
			  opselect = 1;
			  #1 opselect = 0;
		  end
		  1: begin
			  if(outDiv != 31'd2) begin
				  ERROR = 1;
				  #1 ERROR = 0;
			  end
			  testNumber = testNumber+1;
			  a = 31'd32;
			  b = 31'd2;
			  opselect = 1;
			  #1 opselect = 0;
		  end
		  2: begin
			  if(outDiv != 31'd16) begin
				  ERROR = 1;
				  #1 ERROR = 0;
			  end
			  testNumber = testNumber+1;
			  a = 31'd7;
			  b = 31'd2;
			  opselect = 1;
			  #1 opselect = 0;
		  end
		  3: begin
			  if(outDiv != 31'd1073741827) begin
				  ERROR = 1;
				  #1 ERROR = 0;
			  end
			  testNumber = testNumber+1;
			  a = 31'd10000;
			  b = 31'd99999;
			  opselect = 1;
			  #1 opselect = 0;
		  end
		  4: begin
			  if(outDiv != 31'd1466552723) begin
				  ERROR = 1;
				  #1 ERROR = 0;
			  end
			  #2 $finish;
		  end
		endcase
	end // always @ (posedge rdy)
endmodule // top_module
