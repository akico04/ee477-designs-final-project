/**
* Conway's Game of Life Cell
*
* data_i[7:0] is status of 8 neighbor cells
* data_o is status this cell
* 1: alive, 0: death
*
* when en_i==1:
*   simulate the cell transition with 8 given neighors
* else when update_i==1:
*   update the cell status to update_val_i
* else:
*   cell status remains unchanged
**/

module bsg_cgol_cell (
    input clk_i

    , input en_i
    , input [7:0] data_i

    , input update_i
    , input update_val_i

    , output logic data_o
);

  // TODO: Design your bsg_cgl_cell
  // Hint: Find the module to count the number of neighbors from basejump

  logic state;

  logic [3:0] count_ones;

  bsg_popcount #(
      .width_p(8)
  ) popcount (
      .i(data_i),
      .o(count_ones)
  );

  wire next_state;
  wire w0;
  wire w1;

  assign next_state = ((count_ones == 2) && state) || (count_ones == 3);

  bsg_mux #(
      .width_p(1),
      .els_p  (2)
  ) state_mux (
      .data_i({next_state, state}),
      .sel_i (en_i),
      .data_o(w0)
  );

  bsg_mux #(
      .width_p(1),
      .els_p  (2)
  ) update_mux (
      .data_i({update_val_i, w0}),
      .sel_i (update_i),
      .data_o(w1)
  );

  bsg_dff #(
      .width_p(1)
  ) dff (
      .clk_i (clk_i),
      .data_i(w1),
      .data_o(state)
  );

  assign data_o = state;

endmodule
