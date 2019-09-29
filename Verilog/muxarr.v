// packed mux array

`include "utils.vh"

module muxarr #(
  parameter DW = 4, // data width
  parameter MW = 4, // mux width
  parameter NM = 4  // number of packed muxes
)(
  input  [   DW*MW *NM-1:0] inp, // MW, DW-wide inputs for NM muxes
  input  [`log2(MW)*NM-1:0] sel, // log2(MW)-wide selectors for NM muxes
  output [   DW    *NM-1:0] out  // DW-wide outputs for NM muxes
);

localparam SW=`log2(MW); // selector width

genvar i;
generate
  for (i=0;i<NM;i=i+1) begin : MUX
    mux #(DW,MW) mux_0 (
      inp[i*DW*MW +: DW*MW],
      sel[i*SW    +: SW   ],
      out[i*DW    +: DW   ]
   );
  end
endgenerate

endmodule