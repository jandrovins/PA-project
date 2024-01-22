`include "MEMORY.v"

module I_CACHE_tb();
	reg clk=0;
	always #1 clk = ~clk;  // Create clock with period=2


	reg reset, size, ERROR;

	reg [31:0] address;
	wire [31:0] data;
	wire hit;

	wire [127:0] mem_data;
	wire [31:0] mem_address;

	reg mem_read_rdy;

	MEMORY #(.WORD_SIZE_BYTES(16)) mem (.clk(clk),

					    .memory_address1(mem_address),
					    .memory_data1(mem_data),

					    .memory_write_enable2(1'b0));

	I_CACHE dut (.clk(clk),
		     .reset(reset),
		     .cs(1'b1),
		     .mem_bus_address(mem_address),
		     .mem_bus_data(mem_data),
		     .mem_read_rdy(mem_read_rdy),
		     .size(size),
		     .address(address),
		     .data(data),
		     .hit(hit)
		     );

	wire [31:5] address_part;

	assign address_part = address[31:5];

	initial begin
		$dumpvars(0, I_CACHE_tb);

		ERROR = 1'b0;
		reset = 1'b1;

		size = 1'b0;
		mem_read_rdy = 1'b0;

		// hit set 0, line 0
		//            tttt_tttt_ttts_bbbb
		address = 32'b0000_0000_0010_1111;

		#2 reset = 1'b0;

		#5 mem_read_rdy = 1'b1;

		@(negedge clk) if(data != 32'h0000_0000 || hit != 1'b1) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end

		$finish;

		// hit set 1, line 0
		//            tttt_tttt_ttts_bbbb
		address = 32'b0010_0011_0101_1111;
		@(negedge clk) if(data != 32'h0000_0011 || hit != 1'b1) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end

		// no hit, tag exists but in another set
		//            tttt_tttt_ttts_bbbb
		address = 32'b0100_0100_1001_1100;
		@(negedge clk) if(hit != 1'b0) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end

		// hit: set 0, line 1
		//            tttt_tttt_ttts_bbbb
		address = 32'b0100_0100_1000_1100;
		@(negedge clk) if(data != 32'h0000_0010 || hit != 1'b1) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end

		// Same as before, but with whole word
		size = 1'b1;
		//            tttt_tttt_ttts_bbbb
		address = 32'b0100_0100_1000_1100;
		@(negedge clk) if(data != 32'h1010_1010 || hit != 1'b1) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end


		// Same as before, but with some part of the word outsde the line
		size = 1'b1;
		//            tttt_tttt_ttts_bbbb
		address = 32'b0100_0100_1000_1110;
		@(negedge clk) if(data != 32'h0000_1010 || hit != 1'b1) begin
			$write("ERROR\n");
			ERROR = 1'b1;
			#1 ERROR = 1'b0;
		end else begin
			ERROR = 1'b0;
			#1 ERROR = 1'b0;
		end


		$finish;
	end
endmodule // FETCH_STAGE_tb
