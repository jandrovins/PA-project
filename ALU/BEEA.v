module top_module ();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=10
	// initial `probe_start;   // Start the timing diagram

	// `probe(clk);        // Probe signal "clk"

	reg opselect = 0;
	reg [31:0] u, a;
	wire [31:0] outU;
        wire rdy;

	// `probe(rdy);
	// `probe(outU);
	// `probe(opselect);

	beea inst (.clk(clk), .opselect(opselect), .k(u), .p(a), .outC(outU), .rdy(rdy));

	initial begin
		u = 32'd4;
		a = 32'd9; // Compute the inverse of 4 mod 9
		opselect = 1; // Send signal to start computation
		#2 opselect = 0; // Clear signal so that the computation is done only once
		#30 $finish;	// Quit the simulation
	end
endmodule



module beea(
		input clk,
		input opselect,
		input [31:0] k,
		input [31:0] p,
		output [31:0] outC,
		output rdy);

	reg [31:0] curU, curV, curA, curC, curP;
	reg [31:0] newU, newA, newV, newC;
	reg [31:0] outCReg;
	reg processing;
	reg pifSelect, pifNotified, pifRdyA, pifRdyB;

	// `probe(curU);
	// `probe(curV);
	// `probe(curA);
	// `probe(curC);
	// `probe(pifSelect);
	// `probe(pifRdyA);
	// `probe(pifRdyB);


	assign rdy = ~processing;
	assign outC = outCReg;

	processIfEven instA (.clk(clk), .opselect(pifSelect), .u(curU), .a(curA), .p(curP), .outU(newU), .outA(newA), .rdy(pifRdyA));
	processIfEven instB (.clk(clk), .opselect(pifSelect), .u(curV), .a(curC), .p(curP), .outU(newV), .outA(newC), .rdy(pifRdyB));

	initial begin
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
	end

	always @(posedge clk) begin
		if(processing) begin
			if(curU == 32'b0) begin
				outCReg = curC;
				processing = 1'b0;
			end else if(!pifNotified) begin
				pifNotified = 1'b1;
				pifSelect = 1'b1;
				#2 pifSelect <= 1'b0;
			end
		end else begin
			if(opselect) begin
				curU <= k;
				curV <= p;
				curA <= 32'b1;
				curC <= 32'b0;
				curP <= p;
				processing = 1'b1;
			end
		end
	end
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

	reg processing, rdyReg; // TODO: rdy is just the inverted processing. Change??
	reg [31:0] curU, curA, curP;
	reg [31:0] outUReg, outAReg;

	// `probe(curU);
	// `probe(curA);
	// `probe(curP);

	assign outU = outUReg;
	assign outA = outAReg;
	assign rdy = rdyReg;

	initial processing = 1'b0;

	always @(posedge clk) begin
		// If we are in the middle of a computation, work with the
		// intermediate registers only, and update output and rdy when done
		if(processing) begin
			if(curU[0] == 1'b0 && curA[0] == 1'b0) begin
				curU <= curU >> 1;
				curA <= curA >> 1;
			end else if(curU[0] == 1'b0) begin
				curU <= curU >> 1;
				curA <= (curA + curP) >> 1;
			end else begin
				outUReg <= curU;
				outAReg <= curA;
				rdyReg <= 1'b1;
				processing <= 1'b0;
			end
		// If we aro net processing, then we are waiting for a opselect signal high
		// to start the computation. When it starts, copy data into intermediate registers
		// and update the rdy and processing signals
		end else begin
 		   if(opselect) begin
			   rdyReg <= 1'b0;
			   processing <= 1'b1;
			   curU <= u;
			   curA <= a;
			   curP <= p;
			end
		end
	end
endmodule
