module BRANCH_PREDICTOR(
		    input clk,
            input reset,

            // The following come from the F(fetch) stage
            input [31:0]  bp_in_f_pc,

            // The following come from the E(execute) stage
		    input [31:0] bp_in_e_pc,
		    input [31:0] bp_in_e_pc_branch_target,
		    input        bp_in_e_branch_en, // is branch?
		    input        bp_in_e_branch_taken_en, // is taken branch?
		    input        bp_in_e_branch_mispredict_en, // is mispredict?

            output        bp_out_f_predicted_en, // can we predict?
            output        bp_out_f_predicted_taken_en,
		    output [31:0] bp_out_f_predicted_pc);

    localparam  STATE_STRONGLY_TAKEN      = 2'b11,
	            STATE_WEAKLY_TAKEN        = 2'b10,
	            STATE_WEAKLY_NOT_TAKEN    = 2'b01,
	            STATE_STRONGLY_NOT_TAKEN  = 2'b00;

	reg [31:0] bp_mem_tags [0:3];
	reg [31:0] bp_mem_target_pcs [0:3];
	reg        bp_mem_target_valid [0:3];
	reg [1:0]  bp_mem_taken_state [0:3];
    reg [1:0]  bp_mem_iterator;
	wire [31:0] next_bp_mem_tags;
	wire [31:0] next_bp_mem_target_pcs;
	wire        next_bp_mem_target_valid;
	wire [1:0]  next_bp_mem_taken_state;
    wire [1:0]  next_bp_mem_iterator;

    wire [2:0] bp_e_was_hit;
    wire [1:0] bp_mem_idx;

    assign bp_e_was_hit = bp_mem_target_valid[0] == 1'b1 && bp_in_e_pc == bp_mem_tags[0] ? 3'd0 :
                          bp_mem_target_valid[1] == 1'b1 && bp_in_e_pc == bp_mem_tags[1] ? 3'd1 :
                          bp_mem_target_valid[2] == 1'b1 && bp_in_e_pc == bp_mem_tags[2] ? 3'd2 :
                          bp_mem_target_valid[3] == 1'b1 && bp_in_e_pc == bp_mem_tags[3] ? 3'd3 :
                          3'd7;

    assign bp_mem_idx = bp_e_was_hit != 3'd7 ? bp_e_was_hit[1:0] :
                        bp_e_was_hit == 3'd7 && bp_in_e_branch_en ? bp_mem_iterator :
                        2'b0;

    assign next_bp_mem_iterator = bp_e_was_hit == 3'd7 && bp_in_e_branch_en ? bp_mem_iterator + 1 :
                                  bp_mem_iterator;

    assign next_bp_mem_taken_state = bp_e_was_hit != 3'd7 && bp_in_e_branch_mispredict_en && bp_mem_taken_state[bp_e_was_hit] != 2'b0 ? bp_mem_taken_state[bp_e_was_hit] -1 :
                                     bp_e_was_hit != 3'd7 && bp_in_e_branch_mispredict_en && bp_mem_taken_state[bp_e_was_hit] == 2'b0 ? bp_mem_taken_state[bp_e_was_hit]:
                                     bp_e_was_hit != 3'd7 && !bp_in_e_branch_mispredict_en && bp_mem_taken_state[bp_e_was_hit] != 2'b11 ? bp_mem_taken_state[bp_e_was_hit] +1 :
                                     bp_e_was_hit != 3'd7 && !bp_in_e_branch_mispredict_en && bp_mem_taken_state[bp_e_was_hit] == 2'b11 ? bp_mem_taken_state[bp_e_was_hit]:
                                     bp_e_was_hit == 3'd7 && bp_in_e_branch_en && bp_in_e_branch_taken_en ? STATE_WEAKLY_TAKEN :
                                     bp_e_was_hit == 3'd7 && bp_in_e_branch_en && !bp_in_e_branch_taken_en ? STATE_WEAKLY_NOT_TAKEN :
                                     bp_mem_taken_state[0];
    assign next_bp_mem_target_valid = bp_e_was_hit == 3'd7 && bp_in_e_branch_en ?  1'b1 : 
                                      bp_e_was_hit != 3'd7 ? bp_mem_target_valid[bp_e_was_hit]:
                                      bp_mem_target_valid[0];
    assign next_bp_mem_tags = bp_e_was_hit == 3'd7 && bp_in_e_branch_en ?  bp_in_e_pc : 
                                      bp_e_was_hit != 3'd7 ? bp_mem_tags[bp_e_was_hit]:
                                      bp_mem_tags[0];
    assign next_bp_mem_target_pcs = bp_e_was_hit == 3'd7 && bp_in_e_branch_en ?  bp_in_e_pc_branch_target : 
                                      bp_e_was_hit != 3'd7 ? bp_mem_target_pcs[bp_e_was_hit]:
                                      bp_mem_target_pcs[0];

    assign bp_out_f_predicted_en =  bp_mem_target_valid[0] == 1'b1 && bp_in_f_pc == bp_mem_tags[0] ? 1'b1 :
                                    bp_mem_target_valid[1] == 1'b1 && bp_in_f_pc == bp_mem_tags[1] ? 1'b1 :
                                    bp_mem_target_valid[2] == 1'b1 && bp_in_f_pc == bp_mem_tags[2] ? 1'b1 :
                                    bp_mem_target_valid[3] == 1'b1 && bp_in_f_pc == bp_mem_tags[3] ? 1'b1 :
                                    1'b0;

    assign bp_out_f_predicted_taken_en =  bp_mem_target_valid[0] == 1'b1 && bp_in_f_pc == bp_mem_tags[0] ? bp_mem_taken_state[0][1] :
                                          bp_mem_target_valid[1] == 1'b1 && bp_in_f_pc == bp_mem_tags[1] ? bp_mem_taken_state[1][1] :
                                          bp_mem_target_valid[2] == 1'b1 && bp_in_f_pc == bp_mem_tags[2] ? bp_mem_taken_state[2][1] :
                                          bp_mem_target_valid[3] == 1'b1 && bp_in_f_pc == bp_mem_tags[3] ? bp_mem_taken_state[3][1] :
                                          1'bx;

    assign bp_out_f_predicted_pc =  bp_mem_target_valid[0] == 1'b1 && bp_in_f_pc == bp_mem_tags[0] ? bp_mem_target_pcs[0] :
                                    bp_mem_target_valid[1] == 1'b1 && bp_in_f_pc == bp_mem_tags[1] ? bp_mem_target_pcs[1] :
                                    bp_mem_target_valid[2] == 1'b1 && bp_in_f_pc == bp_mem_tags[2] ? bp_mem_target_pcs[2] :
                                    bp_mem_target_valid[3] == 1'b1 && bp_in_f_pc == bp_mem_tags[3] ? bp_mem_target_pcs[3] :
                                    32'bx;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
            bp_mem_target_valid[0] <= 1'b0;
            bp_mem_target_valid[1] <= 1'b0;
            bp_mem_target_valid[2] <= 1'b0;
            bp_mem_target_valid[3] <= 1'b0;
            bp_mem_iterator <= 2'b00;
		end else begin // if (reset)
            bp_mem_tags[bp_mem_idx]         <= next_bp_mem_tags;
            bp_mem_target_pcs[bp_mem_idx]   <= next_bp_mem_target_pcs;
            bp_mem_target_valid[bp_mem_idx] <= next_bp_mem_target_valid;
            bp_mem_taken_state[bp_mem_idx]  <= next_bp_mem_taken_state;
            bp_mem_iterator[bp_mem_idx]     <= next_bp_mem_iterator;
		end
	end // always @ (posedge clk, posedge reset)

endmodule
