

module DIV(
	   input clk,
	   input reset,
	   input start,
	   input signedness,
	   input [31:0] a,
	   input [31:0] b,

	   output reg busy,
	   output [31:0] q,
	   output [31:0] r);

	localparam [31:0] INITIAL_DIVISOR = 32'b1,
			  INITIAL_DIVIDEND = 32'b0;

	wire nextBusy;

	reg      quotientSign,     remainingSign,     curSignedness;
	wire nextQuotientSign, nextRemainingSign, nextCurSignedness;

	reg [31:0]      dividend,     divisor,     quotient,     remainder;
	wire [31:0] nextDividend, nextDivisor, nextQuotient, nextRemainder;

	reg [3:0] status;
	wire [3:0] nextStatus;
	localparam [3:0] STATUS_IDLE = 3'b000,
			 STATUS_LATCHING = 3'b001,
			 STATUS_REDUCING = 3'b010,
			 STATUS_COMPUTING = 3'b011,
			 STATUS_ERROR = 3'b111;


	assign q = quotientSign && curSignedness ? -quotient : quotient;
	assign r = remainingSign && curSignedness ? -remainder : remainder;

	assign nextQuotientSign  = status == STATUS_LATCHING ? (a[31] == 1) ^ (b[31] == 1) : quotientSign;
	assign nextRemainingSign = status == STATUS_LATCHING ? a[31] : remainingSign;
	assign nextCurSignedness = status == STATUS_LATCHING ? signedness : curSignedness;

	// REDUCING PHASE DISABLED: If reducing optimization is done, the remainder must be corrected:
	// shifted left as much times as the operands have been shifted right
	assign nextStatus = status == STATUS_IDLE && start && b == 32'b0 ? STATUS_ERROR :
			    status == STATUS_IDLE && start && b != 32'b0 ? STATUS_LATCHING :

			    status == STATUS_LATCHING && nextDivisor <= nextDividend ? STATUS_COMPUTING :
			    status == STATUS_LATCHING && nextDivisor > nextDividend ? STATUS_IDLE :
			    // status == STATUS_LATCHING && (           a[0] == 0 &&           b[0] == 0) ? STATUS_REDUCING :
			    // status == STATUS_LATCHING && (           a[0] == 1 ||           b[0] == 1) && nextDivisor <= nextDividend ? STATUS_COMPUTING :
			    // status == STATUS_LATCHING && (           a[0] == 1 ||           b[0] == 1) && nextDivisor > nextDividend ? STATUS_IDLE :

			    //status == STATUS_REDUCING && (nextDividend[0] == 0 && nextDivisor[0] == 0) ? STATUS_REDUCING :
			    //status == STATUS_REDUCING && (nextDividend[0] == 1 || nextDivisor[0] == 1) && nextDivisor <= nextDividend ? STATUS_COMPUTING :
			    //status == STATUS_REDUCING && (nextDividend[0] == 1 || nextDivisor[0] == 1) && nextDivisor > nextDividend ? STATUS_IDLE :
			    status == STATUS_COMPUTING && nextDivisor <= nextDividend ? STATUS_COMPUTING :
			    STATUS_IDLE;

	assign nextDividend = status == STATUS_LATCHING ? (curSignedness && a[31] == 1 ? -a : a) :
			      status == STATUS_REDUCING ? dividend >>> 1 :
			      status == STATUS_COMPUTING ? dividend - divisor :
			      status == STATUS_ERROR ? 0 :
			      dividend;

	assign nextDivisor = status == STATUS_LATCHING ? (curSignedness && b[31] == 1 ? -b : b) :
			     status == STATUS_REDUCING ? divisor >>> 1:
			     divisor;

	assign nextQuotient = status == STATUS_IDLE && start ? 0 :
			      status == STATUS_LATCHING ? 0 :
			      status == STATUS_ERROR ? -1 :
			      status == STATUS_REDUCING ? quotient :
			      status == STATUS_COMPUTING ? quotient + 1 :
			      quotient;

	assign nextRemainder = dividend;

	assign nextBusy = status != STATUS_IDLE;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			busy <= 1'b0;
			dividend <= INITIAL_DIVIDEND;
			divisor <= INITIAL_DIVISOR;
			quotient <= 32'b0;
			remainder <= 32'b0;
			quotientSign <= 1'b0;
			remainingSign <= 1'b0;
			curSignedness <= 1'b0;
			status <= STATUS_IDLE;
		end else begin // if (reset)
			dividend <= nextDividend;
			divisor <= nextDivisor;
			quotient <= nextQuotient;
			remainder <= nextDividend;
			busy <= nextBusy;
			quotientSign <= nextQuotientSign;
			remainingSign <= nextRemainingSign;
			curSignedness <= nextCurSignedness;
			status <= nextStatus;
		end
	end


endmodule // DIV

