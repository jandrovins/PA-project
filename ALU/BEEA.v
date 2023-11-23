

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
	reg [1:0] status;
	reg pifSelect;
	wire pifRdyA, pifRdyB;

	assign rdy = status == 2'b00;
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
		$dumpvars(0, newU);
		$dumpvars(0, newV);
		$dumpvars(0, newA);
		$dumpvars(0, newC);
		$dumpvars(0, status);
		$dumpvars(0, rdy);
		$dumpvars(0, pifRdyA);
		$dumpvars(0, pifRdyB);
		$dumpvars(0, outCReg);
		status = 2'b00;
		pifSelect = 1'b0;
	end

	always @(posedge clk) begin
		if(status == 2'b00) begin // Not operating
			if(opselect) begin // Requested to operate, start operation
				curU = k;
				curV = p;
				curA = 32'b1;
				curC = 32'b0;
				curP = p;
				status = 2'b01;
			end
			// If there's no request to operate, do nothing.
		end else if(status == 2'b01) begin // Operating, phase 1: working
			if(curU == 32'b0) begin // Stop condition
				outCReg = curC[31] == 1 ? curC + curP : curC;
				status = 2'b00;
			end else begin
				pifSelect = 1'b1;
				//#2 pifSelect <= 1'b0;
				#1 pifSelect = 1'b0;
				status = 2'b10;
			end
		end else if(status == 2'b10) begin // Operating, phase 2: Waiting for PIF
			if(pifRdyA && pifRdyB) begin
				status = 2'b01;
				if(newU >= newV) begin
					curU = newU - newV;
					curV = newV;
					curA = newA - newC;
					curC = newC;
				end else begin
					curU = newU;
					curV = newV - newU;
					curA = newA;
					curC = newC - newA;
				end
			end // if (pifRdyA && pifRdyB)
		end // if (status == 2'b10)
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
	wire [32:0] procU, procA, newA;

	assign outU = curU;
	assign outA = curA;
	assign rdy = !processing;

	// Compute the next U
	assign procU = curU[0] == 1'b0 ? curU >>> 1 : curU;

	// Compute the next A
	assign newA  = curA[0] == 1'b0 ? curA >>> 1 : (curA + curP) >>> 1;
	assign procA = curU[0] == 1'b0 ? newA : curA;


	initial begin
		$dumpvars(0, clk);
		$dumpvars(0, opselect);
		$dumpvars(0, u);
		$dumpvars(0, a);
		$dumpvars(0, p);
		$dumpvars(0, curU);
		$dumpvars(0, curA);
		$dumpvars(0, processing);
		processing = 1'b0;
	end // initial begin


	always @(posedge opselect) begin
		curU <= {u[31], u};
		curA <= {a[31], a};
		curP <= {p[31], p};
		processing <= 1'b1;
	end

	always @(posedge clk) begin
		curP <= curP;
		if(processing) begin
			curU <= procU;
			curA <= procA;
			processing <= curU[0] != 1'b1;
		end else begin
			curU <= curU;
			curA <= curA;
			processing <= 0;
		end
	end
endmodule
