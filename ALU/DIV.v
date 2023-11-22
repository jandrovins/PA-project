

module div(
	input clk,
	input opselect,
	input [30:0] a,
	input [30:0] b,
	output [30:0] _div,
	output _rdy);

	reg processing, beeaSelect, waitAnotherClk;
	reg [30:0] _divReg;
	reg [31:0] F;
	wire [31:0] outInv;
	wire rdyInv;
	reg [63:0] mult;
	reg [31:0] u2, u3, u4;

	assign _rdy = ~processing;
	assign _div = _divReg;

	beea inst (.clk(clk), .opselect(beeaSelect), .k({1'b0, b}), .p(/*F*/32'h7fffffff), .outC(outInv), .rdy(rdyInv));

	initial begin
		//$dumpvars(0, mult);
		//$dumpvars(0, u2);
		//$dumpvars(0, u3);
		//$dumpvars(0, u4);
		$dumpvars(0, outInv);
		$dumpvars(0, rdyInv);
		$dumpvars(0, processing);
		$dumpvars(0, opselect);
		$dumpvars(0, clk);
		//F = 32'h7fffffff;
		processing = 1'b0;
		beeaSelect = 1'b0;
		waitAnotherClk = 1'b0;
	end

	always @(posedge clk) begin
		if(!processing) begin
			if(opselect) begin
				// Requested to start, and no operation is being executed.
				// Start the computation
				processing <= 1'b1;
				beeaSelect <= 1'b1;
				#2 beeaSelect <= 1'b0;
				mult <= {{33{a[30]}},a};
				waitAnotherClk = 1'b1;
			end
		end else if(waitAnotherClk) begin // if (!processing)
			waitAnotherClk = 1'b0;
		end else if(rdyInv) begin
			mult = mult * { {32{outInv[31]}}, outInv};
			u2 = {1'b0, mult[30:0]};
			u3 = {1'b0, mult[61:31]};
			u4 = u2 + u3;
			if(u4 > 32'h7fffffff) begin
				u4[31] = 1'b0;
				u4 = u4 + 1;
			end
			if(u4 == 32'h7fffffff) begin
				u4 = 32'b0;
			end
			_divReg = u4[30:0];
			processing = 1'b0;
		end
	end // always @(posedge opselect)

endmodule
