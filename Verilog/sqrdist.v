module fpsqrdist #(
  parameter W = 32, // data width
  parameter D = 8   // vector dim
)(
  input          clk, // global clock
  input          ena, // registers enable
  input          rst, // async reset
  input  [D*W-1:0] x, // D-dim vector x
  input  [D*W-1:0] y, // D-dim vector y
  output [  W-1:0] sd // squared distance
);

wire [D*W-1:0] diff, sqrdiff;

genvar gi;
generate
  for (gi=0 ; gi<D ; gi=gi+1) begin: DIFFSQR
    fpop #(W,0,0,1,"SUB") fpsub (clk,ena,rst,   x[gi*W +: W],y[gi*W +: W],   diff[gi*W +: W]);
    fpop #(W,0,1,1,"SQR") fpsqr (clk,ena,rst,diff[gi*W +: W],            ,sqrdiff[gi*W +: W]);
  end
endgenerate

fpaddtree #(W,D) fpaddtree_0 (clk,ena,rst,sqrdiff,sd);

endmodule
