

module div(
	input clk,
	input opselect,
	input [30:0] a,
	input [30:0] b,
	output [30:0] _div,
	output _rdy);

	reg processing, beeaSelect;
	reg [30:0] _divReg;
	reg [31:0] F;
	wire [31:0] outInv;
	wire rdyInv;
	reg [63:0] mult;
	reg [31:0] u2, u3, u4;

	assign _rdy = ~processing;
	assign _div = _divReg;

	beea inst (.clk(clk), .opselect(beeaSelect), .k({1'b0, b}), .p(F), .outC(outInv), .rdy(rdyInv));

	initial begin
		$dumpvars(0, mult);
		$dumpvars(0, u2);
		$dumpvars(0, u3);
		$dumpvars(0, u4);
		$dumpvars(0, outInv);
		$dumpvars(0, rdyInv);
		F = 32'h7fffffff;
		processing = 1'b0;
	end

	always @(posedge rdyInv) begin
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
	end // always @ (posedge rdyInv)

	always @(posedge clk) begin
		// if(rdyInv) begin
		// 	mult <= mult * { {32{outInv[31]}}, outInv};
		// 	u2 <= {1'b0, mult[30:0]};
		// 	u3 <= {1'b0, mult[61:31]};
		// 	u4 <= u2 + u3;
		// 	if(u4 > 32'h7fffffff) begin
		// 		u4[31] <= 1'b0;
		// 		u4 <= u4 + 1;
		// 	end
		// 	if(u4 == 32'h7fffffff) begin
		// 		u4 <= 32'b0;
		// 	end
		// 	_divReg <= u4[30:0];
		// 	processing <= 1'b0;
		// end else
		  if(!processing) begin
			processing <= 1'b1;
			beeaSelect <= 1'b1;
			#1 beeaSelect <= 1'b0;
			mult <= {{33{a[30]}},a};
		end
	end // always @(posedge opselect)

endmodule
