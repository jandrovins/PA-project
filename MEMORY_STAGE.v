module MEMORY_STAGE(
            input [ 4:0] ex_in_operation_l,
		    input [31:0] ex_in_alu_output_l,
		    input        ex_in_rd_en_l,
		    input [ 4:0] ex_in_rd_key_l,
		    input [31:0] ex_in_store_register_w,

		    output reg [31:0] mem_out_rd_value_l,
		    output reg        mem_out_rd_en_l,
		    output reg [ 4:0] mem_out_rd_key_l,

		    output reg        mem_out_memory_we2_l,
		    output reg [31:0] mem_out_memory_address_l,
		    inout      [31:0] mem_out_memory_data_l
		    );
`include "RISCV_constants.vinc"

	wire [4:0] next_mem_out_rd_key_l;
	assign next_mem_out_rd_key_l = ex_in_rd_key_l;

	wire next_mem_out_rd_en_l;
	assign next_mem_out_rd_en_l = ex_in_rd_en_l;

	wire [31:0] next_mem_out_memory_address_l;
	assign next_mem_out_memory_address_l = ex_in_alu_output_l;

	wire [31:0] next_mem_out_rd_value_l;
	assign next_mem_out_rd_value_l = ex_in_operation_l == MEM_WORD && ex_in_rd_en_l == TRUE ? mem_out_memory_data_l :
					  				 ex_in_operation_l == MEM_BYTE && ex_in_rd_en_l == TRUE ? {{24{mem_out_memory_data_l[7]}}, mem_out_memory_data_l[7:0]} :
					  				 ex_in_alu_output_l;

	wire next_mem_out_memory_we2_l;
	assign next_mem_out_memory_we2_l = !ex_in_rd_en_l;

	assign mem_out_memory_data_l = ex_in_rd_en_l == FALSE ? ex_in_store_register_w :
								   32'bz;


	always @(posedge clk, posedge reset) begin
		if (reset) begin
			mem_out_rd_value_l <= 32'b0;
			mem_out_rd_en_l <= FALSE;
			mem_out_rd_key_l <= x0;
			mem_out_memory_we2_l <= FALSE;
			mem_out_memory_address_l <= 32'b0;
		end else begin // if (reset)
			mem_out_rd_value_l <= next_mem_out_rd_value_l;
			mem_out_rd_en_l <= next_mem_out_rd_en_l;
			mem_out_rd_key_l <= next_mem_out_rd_key_l;
			mem_out_memory_we2_l <= next_mem_out_memory_we2_l;
			mem_out_memory_address_l <= next_mem_out_memory_address_l;
		end
	end // always @ (posedge clk, posedge reset)


endmodule // FETCH_STAGE
