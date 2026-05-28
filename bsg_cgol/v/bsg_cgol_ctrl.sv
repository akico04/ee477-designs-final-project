`include "bsg_defines.v"

module bsg_cgol_ctrl #(
   parameter `BSG_INV_PARAM(max_game_length_p),
   localparam game_len_width_lp=`BSG_SAFE_CLOG2(max_game_length_p+1)
) (
  input clk_i,
  input reset_i,

  input en_i,

  // Input Data Channel
  input  [game_len_width_lp-1:0] frames_i,
  input  v_i,
  output ready_o,

  // Output Data Channel
  input yumi_i,
  output v_o,

  /// Cell Array
  /// At start this goes high for one cycle
  output update_o,
  output en_o
);

  (* maybe_unused *)
  wire unused = en_i; // for clock gating, unused
  
  // TODO: Design your control logic
    
  typedef enum logic [1:0] {
    /// Waiting for game to start
    IDLE,

    /// Update
    UPDATE,

    /// Playing the game
    GAMING,

    /// Output ready
    DONE
  } state_t;

  state_t state;
  logic [1:0] state_r;
  state_t next_state;

  assign state = state_t'(state_r);

  assign ready_o = (state == IDLE);
  assign update_o = state == UPDATE;
  assign en_o = state == GAMING;
  assign v_o = (state == DONE);

  logic [game_len_width_lp-1:0] max_frames;

  logic [game_len_width_lp-1:0] frame_count;

  wire accept_input = v_i & ready_o;

  wire output_accepted = yumi_i & v_o;

  /// Latches Frames
  bsg_dff_en #(
      .width_p(game_len_width_lp)
  ) max_frames_latch (
      .clk_i (clk_i),
      .en_i (accept_input),
      .data_i(frames_i),
      .data_o(max_frames)
  );

  logic [game_len_width_lp-1:0] next_frame_count;

  always_comb begin
    if (reset_i) begin
      next_frame_count = 0;
    end else begin
      case(state)
        IDLE: begin
          next_frame_count = 0;
        end

        UPDATE: begin
          next_frame_count = frame_count;
        end

        GAMING: begin
          next_frame_count = frame_count + 1;
        end

        DONE: begin
          next_frame_count = frame_count;
        end
      endcase
    end
  end

  /// Latches Frames Count
  bsg_dff #(
      .width_p(game_len_width_lp)
  ) frame_count_latch (
      .clk_i (clk_i),
      .data_i(next_frame_count),
      .data_o(frame_count)
  );

  always_comb begin
    if (reset_i) begin
      next_state = IDLE;
    end else begin
      case(state)
        IDLE: begin
          next_state = accept_input ? UPDATE : IDLE;
        end

        UPDATE: begin
          next_state = GAMING;
        end

        GAMING: begin
          next_state = (frame_count == max_frames - 1'b1) ? DONE : GAMING;
        end

        DONE: begin
          next_state =  output_accepted ? IDLE : DONE;
        end
      endcase
    end
  end

  bsg_dff #(
    .width_p(2)
  ) state_latch (
    .clk_i (clk_i),
    .data_i(next_state),
    .data_o(state_r)
  );

endmodule
