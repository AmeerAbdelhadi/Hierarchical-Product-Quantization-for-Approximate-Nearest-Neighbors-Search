// packed mux array

`include "utils.vh"

module mux #(
  parameter DW = 4, // data width
  parameter MW = 4  // mux width
)(
  input      [   DW*MW -1:0] inp, // MW, DW-wide inputs
  input      [`log2(MW)-1:0] sel, // log2(MW)-wide selectors
  output reg [   DW    -1:0] out  // DW-wide outputs
);

localparam SW=`log2(MW); // selector width

integer i;
reg [MW-1:0] sel_onehot;
always @* begin
  out = {DW{1'b0}};
  for (i=0;i<MW;i=i+1) begin
    sel_onehot[i] = (i==sel)?1'b1:1'b0;
    out = out | (inp[DW*i +: DW] & {DW{sel_onehot[i]}});
  end
end

endmodule
