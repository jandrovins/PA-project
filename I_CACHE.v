

module I_CACHE (
		input clk,
		input reset,

		// The cache will still output data, but it wont
		// go to memory or other costly operations if cs = 0
		input cs,

		// Memory interface
		output reg [31:0] mem_bus_address,
		output reg mem_read_start,
		input [127:0] mem_bus_data,
		input mem_read_rdy,

		// CPU interface
		input size, // 0 -> byte, 1 -> word
		input [31:0] address,
		output hit,
		output [31:0] data);

	// Memory and tags of the cache, all lines
	reg [127:0] line0set0, line0set1, line1set0, line1set1;
	reg [31:5] tag0set0, tag0set1, tag1set0, tag1set1;
	reg  valid0set0, valid0set1, valid1set0, valid1set1;

	wire [127:0] line;

	assign line = address[4] == 1'b0 && address[31:5] == tag0set0 ? line0set0 :
		      address[4] == 1'b1 && address[31:5] == tag0set1 ? line0set1 :
		      address[4] == 1'b0 && address[31:5] == tag1set0 ? line1set0 :
		      address[4] == 1'b1 && address[31:5] == tag1set1 ? line1set1 :
		      128'bx;

	assign hit = valid0set0 && address[4] == 1'b0 && address[31:5] == tag0set0 ? 1'b1 :
		     valid0set1 && address[4] == 1'b1 && address[31:5] == tag0set1 ? 1'b1 :
		     valid1set0 && address[4] == 1'b0 && address[31:5] == tag1set0 ? 1'b1 :
		     valid1set1 && address[4] == 1'b1 && address[31:5] == tag1set1 ? 1'b1 :
		     1'b0;

	// Indicates the "byte in line" where the request data starts
	wire [3:0] startByteInLine;
	assign startByteInLine = address[3:0];

	assign data[31:24] = startByteInLine == 4'd0 ? line[127:120] :
			     startByteInLine == 4'd1 ? line[119:112] :
			     startByteInLine == 4'd2 ? line[111:104] :
			     startByteInLine == 4'd3 ? line[103:96] :
			     startByteInLine == 4'd4 ? line[95:88] :
			     startByteInLine == 4'd5 ? line[87:80] :
			     startByteInLine == 4'd6 ? line[79:72] :
			     startByteInLine == 4'd7 ? line[71:64] :
			     startByteInLine == 4'd8 ? line[63:56] :
			     startByteInLine == 4'd9 ? line[55:48] :
			     startByteInLine == 4'd10 ? line[47:40] :
			     startByteInLine == 4'd11 ? line[39:32] :
			     startByteInLine == 4'd12 ? line[31:24] :
			     startByteInLine == 4'd13 ? line[23:16] :
			     startByteInLine == 4'd14 ? line[15:8] :
			     line[7:0];


	assign data[23:16] = (startByteInLine+1) == 4'd1 && size ? line[119:112] :
			     (startByteInLine+1) == 4'd2 && size ? line[111:104] :
			     (startByteInLine+1) == 4'd3 && size ? line[103:96] :
			     (startByteInLine+1) == 4'd4 && size ? line[95:88] :
			     (startByteInLine+1) == 4'd5 && size ? line[87:80] :
			     (startByteInLine+1) == 4'd6 && size ? line[79:72] :
			     (startByteInLine+1) == 4'd7 && size ? line[71:64] :
			     (startByteInLine+1) == 4'd8 && size ? line[63:56] :
			     (startByteInLine+1) == 4'd9 && size ? line[55:48] :
			     (startByteInLine+1) == 4'd10 && size ? line[47:40] :
			     (startByteInLine+1) == 4'd11 && size ? line[39:32] :
			     (startByteInLine+1) == 4'd12 && size ? line[31:24] :
			     (startByteInLine+1) == 4'd13 && size ? line[23:16] :
			     (startByteInLine+1) == 4'd14 && size ? line[15:8] :
			     (startByteInLine+1) == 4'd15 && size ? line[7:0] :
			     8'b0;

	assign data[15: 8] = (startByteInLine+2) == 4'd2 && size ? line[111:104] :
			     (startByteInLine+2) == 4'd3 && size ? line[103:96] :
			     (startByteInLine+2) == 4'd4 && size ? line[95:88] :
			     (startByteInLine+2) == 4'd5 && size ? line[87:80] :
			     (startByteInLine+2) == 4'd6 && size ? line[79:72] :
			     (startByteInLine+2) == 4'd7 && size ? line[71:64] :
			     (startByteInLine+2) == 4'd8 && size ? line[63:56] :
			     (startByteInLine+2) == 4'd9 && size ? line[55:48] :
			     (startByteInLine+2) == 4'd10 && size ? line[47:40] :
			     (startByteInLine+2) == 4'd11 && size ? line[39:32] :
			     (startByteInLine+2) == 4'd12 && size ? line[31:24] :
			     (startByteInLine+2) == 4'd13 && size ? line[23:16] :
			     (startByteInLine+2) == 4'd14 && size ? line[15:8] :
			     (startByteInLine+2) == 4'd15 && size ? line[7:0] :
			     8'b0;

	assign data[ 7: 0] = (startByteInLine+3) == 4'd3 && size ? line[103:96] :
			     (startByteInLine+3) == 4'd4 && size ? line[95:88] :
			     (startByteInLine+3) == 4'd5 && size ? line[87:80] :
			     (startByteInLine+3) == 4'd6 && size ? line[79:72] :
			     (startByteInLine+3) == 4'd7 && size ? line[71:64] :
			     (startByteInLine+3) == 4'd8 && size ? line[63:56] :
			     (startByteInLine+3) == 4'd9 && size ? line[55:48] :
			     (startByteInLine+3) == 4'd10 && size ? line[47:40] :
			     (startByteInLine+3) == 4'd11 && size ? line[39:32] :
			     (startByteInLine+3) == 4'd12 && size ? line[31:24] :
			     (startByteInLine+3) == 4'd13 && size ? line[23:16] :
			     (startByteInLine+3) == 4'd14 && size ? line[15:8] :
			     (startByteInLine+3) == 4'd15 && size ? line[7:0] :
			     8'b0;


	// FSM for reading from memory
	localparam [2:0] I_CACHE_FILLED = 3'b000,
			 I_CACHE_WAITING_FROM_MEMORY = 3'b001;

	reg [2:0] status;
	wire [2:0] next_status;
	assign next_status = status == I_CACHE_FILLED && cs && !hit ? I_CACHE_WAITING_FROM_MEMORY :
			     status == I_CACHE_WAITING_FROM_MEMORY && mem_read_start ? I_CACHE_WAITING_FROM_MEMORY :
			     status == I_CACHE_WAITING_FROM_MEMORY && !mem_read_rdy ? I_CACHE_WAITING_FROM_MEMORY :
			     I_CACHE_FILLED;

	// "start" signal will be up for the whole transaction. Bring it down when
	// the read is over, and keep it down if not reading from memory
	wire next_mem_read_start;
	assign next_mem_read_start = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && mem_read_start ? 1'b1 :
								 status == I_CACHE_WAITING_FROM_MEMORY && !mem_read_rdy && mem_read_start ? 1'b0 :
								 status == I_CACHE_FILLED && !hit ? 1'b1 :
				                 1'b0;

	// Keep the requested address in the mem bus, in case the CPU changes it
	wire [31:0] next_mem_bus_address;
	assign next_mem_bus_address = status == I_CACHE_FILLED ? {address[31:4], 4'b0} :
				      mem_bus_address;

	// Which line from each set must be evicted next.
	// We use a simple LRU replacement policy
	reg replaceset0, replaceset1;
	wire next_replaceset0, next_replaceset1;
	assign next_replaceset0 = hit && address[4] == 1'b0 && address[31:5] == tag0set0 ? 1'b1 : // If there has been a hit to the line 0 of set 0, then next line to replace is 1
				  hit && address[4] == 1'b0 && address[31:5] == tag1set0 ? 1'b0 :
				  replaceset0;
	assign next_replaceset1 = hit && address[4] == 1'b1 && address[31:5] == tag0set1 ? 1'b1 :
				  hit && address[4] == 1'b1 && address[31:5] == tag1set1 ? 1'b0 :
				  replaceset0;

	wire next_valid0set0, next_valid0set1, next_valid1set0, next_valid1set1;
	assign next_valid0set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 0 ? 1'b1 : valid0set0;
	assign next_valid1set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 1 ? 1'b1 : valid1set0;
	assign next_valid0set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 0 ? 1'b1 : valid0set1;
	assign next_valid1set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 1 ? 1'b1 : valid1set1;

	wire [31:5] next_tag0set0, next_tag0set1, next_tag1set0, next_tag1set1;
	assign next_tag0set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 0 ? mem_bus_address[31:5] : tag0set0;
	assign next_tag1set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 1 ? mem_bus_address[31:5] : tag1set0;
	assign next_tag0set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 0 ? mem_bus_address[31:5] : tag0set1;
	assign next_tag1set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 1 ? mem_bus_address[31:5] : tag1set1;

	wire [127:0] next_line0set0, next_line0set1, next_line1set0, next_line1set1;
	assign next_line0set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 0 ? mem_bus_data : line0set0;
	assign next_line1set0 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 0 && replaceset0 == 1 ? mem_bus_data : line1set0;
	assign next_line0set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 0 ? mem_bus_data : line0set1;
	assign next_line1set1 = status == I_CACHE_WAITING_FROM_MEMORY && mem_read_rdy && !mem_read_start && mem_bus_address[4] == 1 && replaceset1 == 1 ? mem_bus_data : line1set1;

	always @(posedge clk, posedge reset) begin
		if(reset) begin
			status <= I_CACHE_FILLED;
			mem_read_start <= 1'b0;
			mem_bus_address <= 32'b0;

			replaceset0 <= 1'b0;
			replaceset1 <= 1'b0;

			valid0set0 <= 1'b0;
			valid0set1 <= 1'b0;
			valid1set0 <= 1'b0;
			valid1set1 <= 1'b0;

			line0set0 <= 128'b0;
			line0set1 <= 128'b0;
			line1set0 <= 128'b0;
			line1set1 <= 128'b0;

			tag0set0 <= 11'b0;
			tag0set1 <= 11'b0;
			tag1set0 <= 11'b0;
			tag1set1 <= 11'b0;
		end else begin // if (reset)
			status <= next_status;
			mem_read_start <= next_mem_read_start;
			mem_bus_address <= next_mem_bus_address;

			replaceset0 <= next_replaceset0;
			replaceset1 <= next_replaceset1;

			valid0set0 <= next_valid0set0;
			valid0set1 <= next_valid0set1;
			valid1set0 <= next_valid1set0;
			valid1set1 <= next_valid1set1;

			line0set0 <= next_line0set0;
			line0set1 <= next_line0set1;
			line1set0 <= next_line1set0;
			line1set1 <= next_line1set1;

			tag0set0 <= next_tag0set0;
			tag0set1 <= next_tag0set1;
			tag1set0 <= next_tag1set0;
			tag1set1 <= next_tag1set1;
		end
	end


endmodule
