

module beea(
	input clk,
	input opselect,
	input [31:0] k,
	input [31:0] p,
	output signed [31:0] outC,
	output rdy);

	reg signed [31:0] curU, curV, curA, curC, curP;
	wire [31:0] newU, newA, newV, newC;
	reg signed [31:0] outCReg;
	reg processing;
	reg pifSelect, pifNotified;
	wire pifRdyA, pifRdyB;

	assign rdy = ~processing;
	assign outC = outCReg;

	processIfEven instA (/*Inputs:*/ .clk(clk), .opselect(pifSelect), .u(curU), .a(curA), .p(curP), /*Outputs:*/ .outU(newU), .outA(newA), .rdy(pifRdyA));
	processIfEven instB (/*Inputs:*/ .clk(clk), .opselect(pifSelect), .u(curV), .a(curC), .p(curP), /*Outputs:*/ .outU(newV), .outA(newC), .rdy(pifRdyB));

	initial begin
		$dumpvars(0, opselect);
		$dumpvars(0, pifSelect);
		$dumpvars(0, curU);
		$dumpvars(0, curV);
		$dumpvars(0, curA);
		$dumpvars(0, curC);
		$dumpvars(0, pifRdyA);
		$dumpvars(0, pifRdyB);
		$dumpvars(0, outCReg);
		processing = 1'b0;
		pifSelect = 1'b0;
		pifNotified = 1'b0;
	end

	always @(posedge pifRdyA or posedge pifRdyB) begin
		if(pifRdyA && pifRdyB) begin
			pifNotified = 1'b0;
			if(newU >= newV) begin
				curU <= newU - newV;
				curV <= newV;
				curA <= newA - newC;
				curC <= newC;
			end else begin
				curU <= newU;
				curV <= newV - newU;
				curA <= newA;
				curC <= newC - newA;
			end
		end
	end // always @ (posedge pifRdyA or posedge pifRdyB)

	always @(posedge opselect) begin
		if(!processing) begin
			curU <= k;
			curV <= p;
			curA <= 32'b1;
			curC <= 32'b0;
			curP <= p;
			processing = 1'b1;
		end
	end // always @(posedge opselect)

	always @(posedge clk) begin
		if(processing) begin
			if(curU == 32'b0) begin
				outCReg = curC[31] == 1 ? curC + curP : curC;
				processing = 1'b0;
			end else if(!pifNotified) begin
				pifNotified = 1'b1;
				pifSelect = 1'b1;
				#1 pifSelect <= 1'b0;
			end
		end
	end // always @(posedge clk)
endmodule



module processIfEven(
	input clk,
	input opselect,
	input [31:0] u,
	input [31:0] a,
	input [31:0] p,
	output [31:0] outU,
	output [31:0] outA,
	output rdy);

	reg processing;
	reg signed [32:0] curU, curA, curP; // 33 bits to prevent overflows that change the result
	reg [31:0] outUReg, outAReg;

	assign outU = outUReg;
	assign outA = outAReg;
	assign rdy = !processing;

	initial begin
		$dumpvars(0, curU);
		$dumpvars(0, curA);
		processing = 1'b0;
	end

	// If the opselect signal goes high, we are requested to start computation,
	// if we are not processing. If we are, ignore the request.
	// When it starts, copy data into intermediate registers
	// and update the processing signal
	always @(posedge opselect) begin
		if(!processing) begin
			processing <= 1'b1;
			curU <= {u[31], u}; // Sign-extensions
			curA <= {a[31], a};
			curP <= {p[31], p};
		end
	end // always @(posedge opselect)

	always @(posedge clk) begin
		// If we are in the middle of a computation, work with the
		// intermediate registers only, and update output and rdy when done
		if(processing) begin
			if(curU[0] == 1'b0 && curA[0] == 1'b0) begin
				curU <= curU >>> 1;
				curA <= curA >>> 1;
			end else if(curU[0] == 1'b0) begin
				curU <= curU >>> 1;
				curA <= (curA + curP) >>> 1;
			end else begin
				outUReg <= curU[31:0];
				outAReg <= curA[31:0];
				processing <= 1'b0;
			end
		end // if (processing)
	end // always @ (posedge clk)
endmodule
