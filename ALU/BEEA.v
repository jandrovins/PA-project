

module BEEA(
	input clk,
	input reset,
	input start,
	input [31:0] k,
	input [31:0] p,
	output signed [31:0] outC,
	output rdy);

	reg signed [32:0] curU, curV, curA, curC, curP;
	wire [32:0] newU, newA, newV, newC, nextCurU, nextCurV, nextCurA, nextCurC, nextCurP;
	reg signed [32:0] outCReg;
	wire [32:0] nextOutCReg;
	reg processing, pifSelect;
	wire nextProcessing, nextPifSelect;
	wire pifRdyA, pifRdyB;

	processIfEven instA (.clk(clk), .reset(reset), .start(pifSelect), .u(curU), .a(curA), .p(curP),
			     .outU(newU), .outA(newA), .rdy(pifRdyA));
	processIfEven instB (.clk(clk), .reset(reset), .start(pifSelect), .u(curV), .a(curC), .p(curP),
			     .outU(newV), .outA(newC), .rdy(pifRdyB));

	assign rdy = ~processing;
	assign outC = {outCReg[32], outCReg[30:0]};

	assign nextCurU = start ? {k[31], k} :
			  pifRdyA && pifRdyB && newU >= newV ? newU - newV :
			  pifRdyA && pifRdyB ? newU :
			  curU;

	assign nextCurV = start ? {p[31], p} :
			  pifRdyA && pifRdyB && newU >= newV ? newV :
			  pifRdyA && pifRdyB ? newV - newU :
			  curV;

	assign nextCurA = start ? 33'b1 :
			  pifRdyA && pifRdyB && newU >= newV ? newA - newC :
			  pifRdyA && pifRdyB ? newA :
			  curA;

	assign nextCurC = start ? 33'b0 :
			  pifRdyA && pifRdyB && newU >= newV ? newC :
			  pifRdyA && pifRdyB ? newC - newA :
			  curC;

	assign nextCurP = start ? {p[31], p} : curP;

	assign nextProcessing = start ? 1 :
				pifRdyA && pifRdyB && nextCurU == 32'b0 ? 0 : processing;

	assign nextOutCReg = processing && pifRdyA && pifRdyB && nextCurU == 32'b0 ?
			     (nextCurC[31] == 1 ? nextCurC + nextCurP : nextCurC) :
			     outCReg;

	assign nextPifSelect = start ? 1 :
			       processing == 0 ? 0 :
			       pifSelect == 1'b1 ? 1'b0 :
			       pifRdyA && pifRdyB && nextCurU != 32'b0;


	always @(posedge clk, posedge reset) begin
		if (reset) begin
			processing = 1'b0;
			pifSelect = 1'b0;
		end else begin
			curU <= nextCurU;
			curV <= nextCurV;
			curA <= nextCurA;
			curC <= nextCurC;
			curP <= nextCurP;
			processing <= nextProcessing;
			outCReg <= nextOutCReg;
			pifSelect <= nextPifSelect;
		end
	end // always @ (posedge clk, posedge start)
endmodule


// TUDU: Okay tener 2 módulos en el mismo fichero??
module processIfEven(
	input clk,
	input reset,
	input start,
	input signed [32:0] u,
	input signed [32:0] a,
	input [32:0] p,
	output signed [32:0] outU,
	output signed [32:0] outA,
	output rdy);

	reg processing;
	// 33 bits to prevent overflows that change the result
	reg signed [32:0] curU, curA, curP;
	wire [32:0] procU, nextU, fstA, procA, nextA, nextP;
	wire nextProcessing;

	assign outU = curU;
	assign outA = curA;
	assign rdy = !nextProcessing;

	// Compute the next U
	assign procU = curU[0] == 1'b0 ? curU >>> 1 : curU;
	assign nextU = processing == 1'b1 ? procU :
		       start == 1'b1 ? u :
		       curU; // Latch the last result

	// Compute the next A
	assign fstA  = curA[0] == 1'b0 ? curA >>> 1 : (curA + curP) >>> 1;
	assign procA = curU[0] == 1'b0 ? fstA : curA;
	assign nextA = processing == 1'b1 ? procA :
		       start == 1'b1 ? a :
		       curA; // Latch the last result

	assign nextP = start == 1'b1 ? p : curP;

	assign nextProcessing = start == 1'b1 ? 1'b1 :
				processing == 1'b1 ? curU[0] != 1'b1 :
				1'b0;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			processing = 1'b0;
		end else begin
			curU <= nextU;
			curA <= nextA;
			curP <= nextP;
			processing <= nextProcessing;
		end
	end
endmodule
