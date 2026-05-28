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
  logic [1:0] next_state;

  assign state = state_t'(state_r);

  assign ready_o = (state == IDLE);
  assign update_o = state == UPDATE;
  assign en_o = state == GAMING;
  assign v_o = (state == DONE);

  logic [game_len_width_lp-1:0] max_frames;

  logic [game_len_width_lp-1:0] frame_count;

  wire accept_input = v_i & ready_o;

  wire output_accepted = yumi_i & v_o;

  wire last_frame = frame_count == max_frames - 1'b1;

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

  wire [game_len_width_lp-1:0] frame_count_plus_one = frame_count + {{(game_len_width_lp-1){1'b0}}, 1'b1};

  wire [3:0][game_len_width_lp-1:0] next_frame_count_options;

  assign next_frame_count_options[IDLE]   = '0;
  assign next_frame_count_options[UPDATE] = '0;
  assign next_frame_count_options[GAMING] = frame_count_plus_one;
  assign next_frame_count_options[DONE]   = frame_count;

  bsg_mux #(
     .width_p(game_len_width_lp),
     .els_p(4)
  ) next_frame_count_mux (
     .data_i(next_frame_count_options),
     .sel_i(state),
     .data_o(next_frame_count)
  );

  /// Latches Frames Count
  bsg_dff #(
      .width_p(game_len_width_lp)
  ) frame_count_latch (
      .clk_i (clk_i),
      .data_i(next_frame_count),
      .data_o(frame_count)
  );

  wire [3:0][1:0] next_state_options;

  assign next_state_options[IDLE]   = accept_input ? UPDATE : IDLE;
  assign next_state_options[UPDATE] = max_frames == '0 ? DONE : GAMING;
  assign next_state_options[GAMING] = last_frame ? DONE : GAMING;
  assign next_state_options[DONE]   = output_accepted ? IDLE : DONE;

  bsg_mux #(
     .width_p(2)
    ,.els_p(4)
  ) next_state_mux (
     .data_i(next_state_options)
    ,.sel_i(state)
    ,.data_o(next_state)
  );

  bsg_dff #(
    .width_p(2)
  ) state_latch (
    .clk_i (clk_i),
    .data_i(next_state),
    .data_o(state_r)
  );

endmodule
