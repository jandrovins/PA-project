

module DIV(
	input clk,
	input reset,
	input start,
	input [30:0] a,
	input [30:0] b,
	output [30:0] _div,
	output _rdy);

	reg processing;
	wire nextProcessing;
	reg [30:0] _divReg, latchedA;
	wire [30:0] next_divReg, nextLatchedA;
	wire [31:0] outInv;
	wire rdyInv;
	reg [63:0] mult;
	wire [63:0] nextMult, newMult;
	wire [31:0] newU2, newU3, newU4, newU41, newU42;

	assign _rdy = processing == 0 ? ~nextProcessing : ~processing;
	assign _div = _divReg;

	BEEA inst (.clk(clk), .reset(reset), .start(start), .k({1'b0, b}), .p(32'h7fffffff), .outC(outInv), .rdy(rdyInv));

	assign newMult = mult * { {32{outInv[31]}}, outInv};
	assign newU2 = {1'b0, newMult[30:0]};
	assign newU3 = {1'b0, newMult[61:31]};
	assign newU41 = newU2 + newU3;
	assign newU42 = {1'b0, newU41[30:0]} + 1;
	assign newU4 = newU42 == 32'h7fffffff ? 32'b0 :
		       (newU41 > 32'h7fffffff ? newU42 : newU41 );

	assign nextProcessing = start ? 1 :
				processing && rdyInv ? 0 : processing;

	assign nextLatchedA = start ? a : latchedA;

	assign nextMult = start ? {{33{a[30]}},a} : mult;

	assign next_divReg = start ? _divReg :
			     processing && rdyInv ? newU4[30:0] : _divReg;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			processing <= 1'b0;
		end else begin
			latchedA <= nextLatchedA;
			mult <= nextMult;
			_divReg <= next_divReg;
			processing <= nextProcessing;
		end
	end

endmodule
