module CPU (
	    input clk,
	    input reset,

	    input [127:0] imemory_data_bus1,
	    output [31:0] imemory_address_bus1,
		input imem_read_rdy,
		output imem_read_start,


	    output memory_write_enable2,
	    inout [31:0] memory_data_bus2,
	    output [31:0] memory_address_bus2
	    );


`include "CPU_CONFIG.vinc"
`include "RISCV_constants.vinc"

	reg [31:0] cpu_cycle_counter;

	wire [31:0] rf_port1_data, rf_port2_data, operand1, operand2, alu_output;
	wire [31:0] wb_rf_rd_data;
	wire [ 4:0] wb_rf_rd_key;
	wire        wb_rf_rd_we;
	wire [4:0] rf_port1_key, rf_port2_key;

	REGISTER_FILE register_file (.clk(clk),
				     .rf_port1_key(rf_port1_key),
				     .rf_port2_key(rf_port2_key),
				     .rf_port1_value(rf_port1_data),
				     .rf_port2_value(rf_port2_data),
				     .rf_portD_enable(wb_rf_rd_we),
				     .rf_portD_key(wb_rf_rd_key),
				     .rf_portD_value(wb_rf_rd_data));
	

	//#########################################//
	//########### FETCH STAGE BEGIN ###########//
	//#########################################//

	reg e_rd_we, e_alu_src2_is_imm, e_mem_we, e_is_jmp, e_is_branch;
    reg [31:0] e_imm, e_pc_plus4, e_pc;
	wire [31:0] e_branch_target_pc;
	wire e_branch_taken_en;

	wire [31:0] f_pc_plus4;
	wire [31:0] next_f_pc;
	wire [31:0] f_instr;

	wire bp_f_predicted, bp_f_predicted_taken_en;
	wire [31:0] bp_predicted_pc;
	wire e_bp_mispredict_en;
    wire hu_stall_f_en, hu_stall_e_en;

	assign next_f_pc = !e_bp_predicted && e_branch_taken_en ? e_branch_target_pc :
					   e_bp_mispredict_en && e_branch_taken_en ? e_branch_target_pc :
					   e_bp_mispredict_en && !e_branch_taken_en ? e_pc_plus4 :
					   bp_f_predicted &&  bp_f_predicted_taken_en ? bp_predicted_pc :
					   hu_stall_f_en ? f_pc :
					   f_pc_plus4;

	reg [31:0] f_pc;
	always @(posedge clk, posedge reset) begin
		if (reset) begin
			cpu_cycle_counter <= 32'b0;
			f_pc <= INITIAL_PC;
		end else begin // if (reset)
			f_pc <= next_f_pc;
			cpu_cycle_counter <= cpu_cycle_counter + 1;
		end
	end // always @ (posedge clk, posedge reset)

	BRANCH_PREDICTOR branch_predictor (
		    .clk(clk),
            .reset(reset),

            // The following come from the F(fetch) stage
            .bp_in_f_pc(f_pc),

            // The following come from the E(execute) stage
		    .bp_in_e_pc(e_pc),
		    .bp_in_e_pc_branch_target(e_branch_target_pc),
		    .bp_in_e_branch_en(e_is_branch), // is branch?
		    .bp_in_e_branch_taken_en(e_branch_taken_en), // is taken branch?
		    .bp_in_e_branch_mispredict_en(e_bp_mispredict_en), // is mispredict?

            .bp_out_f_predicted_en(bp_f_predicted), // can we predict?
            .bp_out_f_predicted_taken_en(bp_f_predicted_taken_en),
		    .bp_out_f_predicted_pc(bp_predicted_pc));

	wire icache_hit;
	wire [31:0] icache_data;
	I_CACHE cache (.clk(clk),
		     .reset(reset),
		     .cs(1'b1),
		     .mem_bus_address(imemory_address_bus1),
		     .mem_bus_data(imemory_data_bus1),
		     .mem_read_rdy(imem_read_rdy),
			 .mem_read_start(imem_read_start),

		     .size(1'b1), // always word in icache
		     .address(f_pc),
		     .data(icache_data),
		     .hit(icache_hit)
		     );

	assign f_instr = icache_data;
	assign f_pc_plus4 = f_pc + 4;

	reg [31:0] d_pc;
	reg [31:0] d_pc_plus4;
	reg [31:0] d_instr;
	reg d_bp_predicted, d_bp_predicted_taken_en;

	wire 		hu_flush_d_en;
    wire        hu_stall_d_en;
	always @(posedge clk, posedge reset) begin
		if (reset) begin
			d_pc <= INITIAL_PC;
			d_pc_plus4 <= INITIAL_PC;
			d_instr <= NOP; // Send NOP
			d_bp_predicted <= 1'b0;
			d_bp_predicted_taken_en <= 1'b0;

		end else begin // if (reset)
			d_pc       <= hu_stall_d_en ? d_pc :
					      hu_flush_d_en ? INITIAL_PC :
						  f_pc;
			d_pc_plus4 <= hu_stall_d_en ? d_pc_plus4 :
						  hu_flush_d_en ? INITIAL_PC :
						  f_pc_plus4;
			d_instr    <= hu_stall_d_en ? d_instr    :
						  hu_flush_d_en ? NOP        :
						  f_instr;
			d_bp_predicted <= bp_f_predicted;
			d_bp_predicted_taken_en <= bp_f_predicted_taken_en;
		end
	end // always @ (posedge clk, posedge reset)

	//#########################################//
	//############ FETCH STAGE END ############//
	//############ DECODE STAGE BEGIN #########//
	//#########################################//

	wire dest_register_enable_DA, dest_register_enable_AW;
	wire [4:0] d_rd_key, d_r1_key, d_r2_key, d_alu_op;
	wire [31:0] next_program_counter_DA, branch_dest, source2_reg_value_DE;
	wire d_rd_we, d_mem_we, d_is_jmp, d_is_branch, d_alu_src2_is_imm, d_mem_data_size;
    wire [31:0] d_r1_data, d_r2_data, d_imm;
    wire [1:0] d_rd_sel;
	reg [4:0] e_r1_key, e_r2_key, e_rd_key, e_alu_op;

	DECODE_STAGE decode (
			     .d_in_instr(d_instr),
				 .e_in_r1_key(e_r1_key),
				 .e_in_r2_key(e_r2_key),
				 .e_in_alu_op(e_alu_op),

			     .d_out_r1_key(d_r1_key),
			     .d_out_r2_key(d_r2_key),
			     .d_out_rd_key(d_rd_key),
			     .d_out_rd_we(d_rd_we),
				 .d_out_alu_src2_is_imm(d_alu_src2_is_imm),
				 .d_out_rd_sel(d_rd_sel),
				 .d_out_imm(d_imm),
				 .d_out_mem_we(d_mem_we),
				 .d_out_mem_data_size(d_mem_data_size),
				 .d_out_is_jmp(d_is_jmp),
				 .d_out_is_branch(d_is_branch),
			     .d_out_alu_op(d_alu_op));

    assign rf_port1_key = d_r1_key;
    assign rf_port2_key = d_r2_key;
    assign d_r1_data = rf_port1_data;
    assign d_r2_data = rf_port2_data;
    wire        hu_flush_e_en;

	//#########################################//
	//############ DECODE  STAGE END ##########//
	//############ EXECUTE STAGE BEGIN ########//
	//#########################################//

	reg e_mem_data_size;
	reg [1:0] e_rd_sel;
    reg [31:0] e_r1_data, e_r2_data;
	reg e_bp_predicted, e_bp_predicted_taken_en;
	always @(posedge clk, posedge reset) begin
		if (reset) begin
            // Passthrough
            e_pc_plus4        <= INITIAL_PC;
            e_pc              <= INITIAL_PC;

            e_alu_src2_is_imm <= 1'b0;
			e_r1_key 		  <= 5'b0;
			e_r1_data 		  <= 5'b0;
			e_r2_key 		  <= 5'b0;
			e_r2_data 		  <= 5'b0;
			e_rd_key 		  <= 5'b0;
			e_alu_op 		  <= ALU_ADD;
			e_rd_we  		  <= 1'b0;
			e_alu_src2_is_imm <= 1'b0;
			e_mem_we          <= 1'b0;
			e_is_jmp          <= 1'b0;
			e_is_branch       <= 1'b0;
			e_rd_sel          <= 2'b0;
			e_imm             <= 32'b0;
            e_mem_data_size   <= MEM_WORD;
			e_bp_predicted <= 1'b0;
			e_bp_predicted_taken_en <= 1'b0;
		end else begin // if (reset)
            // Passthrough
            e_pc              <= hu_flush_e_en ? INITIAL_PC :
								 hu_stall_e_en ? e_pc :
								 d_pc;
            e_pc_plus4        <= hu_flush_e_en ? INITIAL_PC :
								 hu_stall_e_en ? e_pc_plus4 :
								 d_pc_plus4;

            e_alu_src2_is_imm <= hu_flush_e_en ? 1'b0      :
								 hu_stall_e_en ? e_alu_src2_is_imm :
								 d_alu_src2_is_imm;
			e_r1_key 		  <= hu_flush_e_en ? 5'b0      : 
								 hu_stall_e_en ? e_r1_key: 
								 d_r1_key;
			e_r1_data 		  <= hu_flush_e_en ? 5'b0      : 
								 hu_stall_e_en ? e_r1_data: 
								 d_r1_data;
			e_r2_key 		  <= hu_flush_e_en ? 5'b0      : 
								 hu_stall_e_en ? e_r2_key: 
								 d_r2_key;
			e_r2_data 		  <= hu_flush_e_en ? 5'b0      : 
								 hu_stall_e_en ? e_r2_data: 
								 d_r2_data;
			e_rd_key 		  <= hu_flush_e_en ? 5'b0      : 
								 hu_stall_e_en ? e_rd_key: 
								 d_rd_key;
			e_alu_op 		  <= hu_flush_e_en ? ALU_ADD   : 
								 hu_stall_e_en ? e_alu_op: 
								 d_alu_op;
			e_rd_we  		  <= hu_flush_e_en ? 1'b0      : 
								 hu_stall_e_en ? e_rd_we: 
								 d_rd_we;
			e_alu_src2_is_imm <= hu_flush_e_en ? 1'b0      : 
								 hu_stall_e_en ? e_alu_src2_is_imm: 
								 d_alu_src2_is_imm;
			e_mem_we          <= hu_flush_e_en ? 1'b0      : 
								 hu_stall_e_en ? e_mem_we: 
								 d_mem_we;
			e_is_jmp          <= hu_flush_e_en ? 1'b0      : 
								 hu_stall_e_en ? e_is_jmp: 
								 d_is_jmp;
			e_is_branch       <= hu_flush_e_en ? 1'b0      : 
								 hu_stall_e_en ? e_is_branch: 
								 d_is_branch;
			e_rd_sel          <= hu_flush_e_en ? 2'b0      : 
								 hu_stall_e_en ? e_rd_sel: 
								 d_rd_sel;
			e_imm             <= hu_flush_e_en ? 32'b0     : 
								 hu_stall_e_en ? e_imm : 
								 d_imm;
            e_mem_data_size   <= hu_flush_e_en ? MEM_WORD  : 
								 hu_stall_e_en ? e_mem_data_size: 
								 d_mem_data_size;
			e_bp_predicted <= hu_flush_e_en ? 1'b0 :
							  hu_stall_e_en ? e_bp_predicted:
							  d_bp_predicted;
			e_bp_predicted_taken_en <=  hu_flush_e_en ? 1'b0 :
										hu_stall_e_en ? e_bp_predicted_taken_en:
										d_bp_predicted_taken_en;
		end
	end // always @ (posedge clk, posedge reset)

    reg        m_rd_we;
    reg [4:0]  m_rd_key; // defined here for use in hazard unit
    reg [31:0] m_alu_result;
    reg        wb_rd_we;
    reg [4:0]  wb_rd_key;
    reg [31:0] wb_rd_data;

    wire [31:0] e_alu_result;

	wire [31:0] e_alu_src1, e_alu_src2;
    wire [31:0] e_r2_data_after_bypass; // To hold value after bypass
	wire [1:0]  hu_alu_src1_sel, hu_alu_src2_sel;
	wire e_alu_busy;
	wire e_alu_reset;

	HAZARD_UNIT hu (
		.icache_hit(icache_hit),

        .d_in_r1_key(d_r1_key),
        .d_in_r2_key(d_r2_key),
        .d_in_is_branch(d_is_branch),

        .e_in_r1_key(e_r1_key),
        .e_in_r2_key(e_r2_key),

        .e_in_rd_key(e_rd_key),
        .e_in_rd_is_load_en(e_rd_sel[0]), // if e_rd_sel == 0, then is LW (load word)
		.e_in_is_branch(e_is_branch),
		.e_in_bp_predicted_en(e_bp_predicted),
        .e_in_bp_mispredict_en(e_bp_mispredict_en),
        .e_in_branch_taken_en(e_branch_taken_en),
		.e_in_alu_busy(e_alu_busy),
        .m_in_rd_key(m_rd_key),
        .m_in_rd_we (m_rd_we),

        .wb_in_rd_key(wb_rf_rd_key),
        .wb_in_rd_we (wb_rf_rd_we), 

        .hu_out_alu_src1_sel(hu_alu_src1_sel),
        .hu_out_alu_src2_sel(hu_alu_src2_sel),

        .hu_out_stall_f_en(hu_stall_f_en),
        .hu_out_stall_d_en(hu_stall_d_en),
		.hu_out_stall_e_en(hu_stall_e_en),
        .hu_out_flush_e_en(hu_flush_e_en),
		.hu_out_flush_d_en(hu_flush_d_en)

	);

	assign e_alu_src1 = hu_alu_src1_sel == 2'b00 ? e_r1_data :   // no bypass
					    hu_alu_src1_sel == 2'b01 ? wb_rf_rd_data:   // bypass from WB
					    hu_alu_src1_sel == 2'b10 ? m_alu_result: // bypass from memory
					    2'bxx;
	assign e_r2_data_after_bypass  = hu_alu_src2_sel == 2'b00 ? e_r2_data :   // no bypass
					                 hu_alu_src2_sel == 2'b01 ? wb_rf_rd_data:   // bypass from WB
					                 hu_alu_src2_sel == 2'b10 ? m_alu_result: // bypass from memory
					                 2'bxx;

	assign e_alu_src2 = e_alu_src2_is_imm ? e_imm :
                        e_r2_data_after_bypass;

	assign e_branch_target_pc = e_pc + e_imm;
	
	assign e_alu_reset = hu_flush_e_en | reset;

	ALU_STAGE alu (
		.clk(clk),
		.reset(e_alu_reset),
              .alu_in_src1(e_alu_src1),
              .alu_in_src2(e_alu_src2),
              .alu_in_op(e_alu_op),

              .alu_out_result(e_alu_result),
              .alu_out_branch_en(e_branch_taken_en),
			  .alu_out_busy(e_alu_busy)
              );

	assign e_bp_mispredict_en = e_is_branch && e_bp_predicted && (e_branch_taken_en != e_bp_predicted_taken_en);

	//#########################################//
	//############ EXECUTE STAGE END ##########//
	//############ MEMORY  STAGE BEGIN ########//
	//#########################################//

    reg [31:0] m_mem_write_data, m_pc_plus4, m_r2_data;
    reg [1:0]  m_rd_sel;
    reg        m_mem_we, m_mem_data_size;
	always @(posedge clk, posedge reset) begin
		if (reset) begin
            // Passthrough
            m_pc_plus4      <= INITIAL_PC;
            m_rd_key        <= 5'b0;
            m_rd_sel        <= 2'b0;
            m_rd_we         <= 1'b0;
            m_mem_we        <= 1'b0;
            m_r2_data       <= 32'b0;
            m_mem_data_size <= 32'b0;

            m_alu_result     <= 32'b0;
            m_mem_write_data <= 32'b0;
		end else begin // if (reset)
            // Passthrough
            m_pc_plus4      <= e_alu_busy ? e_pc : e_pc_plus4;
            m_rd_key        <= e_rd_key;
            m_rd_sel        <= e_rd_sel;
            m_rd_we         <= e_alu_busy ? 1'b0 : e_rd_we;
            m_mem_we        <= e_alu_busy ? 1'b0 : e_mem_we;
            m_r2_data       <= e_r2_data_after_bypass;
            m_mem_data_size <= e_mem_data_size;

            m_alu_result     <= e_alu_result;
            m_mem_write_data <= e_r2_data_after_bypass;
		end
	end // always @ (posedge clk, posedge reset)

    wire [31:0] m_mem_data_out;

    assign memory_write_enable2 = m_mem_we;
    assign memory_address_bus2  = m_alu_result;
    assign memory_data_bus2     = m_mem_we ? m_r2_data :
                                  32'bz;
	assign m_mem_data_out = m_mem_data_size == MEM_WORD ? memory_data_bus2 :
					        m_mem_data_size == MEM_BYTE ? {{24{memory_data_bus2[7]}}, memory_data_bus2[7:0]}:
                            32'bx;

	//###########################################//
	//############ MEMORY    STAGE END   ########//
	//############ WRITEBACK STAGE BEGIN ########//
	//###########################################//

    reg [31:0] wb_alu_result, wb_pc_plus4, wb_mem_out_data;
    reg [1:0]  wb_rd_sel;
	always @(posedge clk, posedge reset) begin
		if (reset) begin
            // Passthrough
            wb_pc_plus4     <= INITIAL_PC;
            wb_rd_key       <= 5'b0;
            wb_rd_sel       <= 2'b0;
            wb_rd_we        <= 1'b0;
            wb_alu_result   <= 32'b0;
            wb_mem_out_data <= 32'b0;
		end else begin // if (reset)
            // Passthrough
            wb_pc_plus4   <= m_pc_plus4;
            wb_rd_key     <= m_rd_key;
            wb_rd_sel     <= m_rd_sel;
            wb_rd_we      <= m_rd_we;
            wb_alu_result <= m_alu_result;
            wb_mem_out_data     <= m_mem_data_out;
		end
	end // always @ (posedge clk, posedge reset)

	assign wb_rf_rd_we     = wb_rd_we && wb_rd_key != 5'b0;
	assign wb_rf_rd_key    = wb_rd_key;
	assign wb_rf_rd_data   = wb_rd_sel == 2'b01 ? wb_mem_out_data :
						     wb_rd_sel == 2'b00 ? wb_alu_result :
						     wb_rd_sel == 2'b10 ? wb_pc_plus4 :
						     32'bx;

	//###########################################//
	//############ WRITEBACK STAGE END ##########//
	//############ FUN       STAGE BEGIN ########//
	//###########################################//

endmodule
