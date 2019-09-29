module fpmul
#(parameter DW = 32   , // datawidth
  parameter RI = 0    , // register inputs
  parameter RP = 1    , // register pipeline
  parameter RO = 1      // register output
)(
  input           clk,  // global clock
  input           ena,  // registers enable
  input           rst,  // async reset
  input  [DW-1:0] x  ,  // input x
  input  [DW-1:0] y  ,  // input y
  output [DW-1:0] m     // multiplication x*y
);

twentynm_fp_mac  #(
  .ax_clock("NONE"),
  .ay_clock(RI?"0":"NONE"),
  .az_clock(RI?"0":"NONE"),
  .output_clock(RO?"0":"NONE"),
  .accumulate_clock("NONE"),
  .ax_chainin_pl_clock("NONE"),
  .accum_pipeline_clock("NONE"),
  .mult_pipeline_clock(RP?"0":"NONE"),
  .adder_input_clock("0"),
  .accum_adder_clock("NONE"),
  .use_chainin("false"),
  .operation_mode("sp_mult"),
  .adder_subtract("false")
) sp_mult (
  .clk({1'b0,1'b0,clk}),
  .ena({1'b0,1'b0,ena}),
  .aclr({rst,rst}),
  .ay(x),
  .az(y),
  .chainin(32'b0),
  .resulta(m),
  .chainout()
);

endmodule
