

module DIV(
	   input clk,
	   input reset,
	   input start,
	   input signedness,
	   input [31:0] a,
	   input [31:0] b,
	   output [31:0] q,
	   output [31:0] r,
	   output rdy);

	reg processing, error, qSign, rSign;
	wire nextProcessing, nextError, stopCondition, nextQSign, nextRSign;

	reg [31:0]      dividend,     divisor,     quotient,     remainder;
	wire [31:0] nextDividend, nextDivisor, nextQuotient, nextRemainder;



	assign q = qSign && signedness ? -quotient : quotient;
	assign r = rSign && signedness ? -remainder : remainder;
	assign rdy = ~processing;

	assign nextQSign = start ? (a[31] == 1) ^ (b[31] == 1) : qSign;
	assign nextRSign = start ? a[31] : rSign;

	assign nextSameStart = !start && !processing ? 0 : 1;


	assign nextDividend = start && !signedness ? a :
			      start && signedness ? (a[31] == 1 ? -a : a) :
			      processing && !stopCondition ? dividend - divisor :
			      dividend;
	assign nextDivisor = start && !signedness ? b :
			     start && signedness ? (b[31] == 1 ? -b : b) :
			     divisor;
	assign nextQuotient = start ? 0 :
			      error ? -1 :
			      processing && !stopCondition ? quotient + 1 :
			      quotient;
	assign nextRemainder = error ? 0 :
			       processing && stopCondition ? dividend :
			       remainder;

	assign stopCondition = processing && error ? 1 :
			       !processing ? 0 :
			       divisor > dividend;
	assign nextProcessing = start || (error || stopCondition ? 0 : processing);
	assign nextError = start ? nextDivisor == 32'b0 :
			   error;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			processing <= 1'b0;
			error <= 1'b0;
			dividend <= 32'b0;
			divisor <= 32'b1;
			quotient <= 32'b0;
			remainder <= 32'b0;
			qSign <= 1'b0;
			rSign <= 1'b0;
		end else begin
			dividend <= nextDividend;
			divisor <= nextDivisor;
			quotient <= nextQuotient;
			remainder <= nextRemainder;
			processing <= nextProcessing;
			error <= nextError;
			qSign <= nextQSign;
			rSign <= nextRSign;
		end
	end


endmodule // DIV

