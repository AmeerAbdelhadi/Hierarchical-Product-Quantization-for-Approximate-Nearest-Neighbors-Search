module fpmin #(
  parameter DW = 32  , // data  wdith
  parameter IW = 4     // index width
)(
  input           clk, // global clock
  input           ena, // output reg enable
  input           rst, // async reset
  input  [IW-1:0] xi , // input x: index
  input  [DW-1:0] xd , // input x: data
  input  [IW-1:0] yi , // input y: index
  input  [DW-1:0] yd , // input y: data
  output [IW-1:0] mi , // min   m: index
  output [DW-1:0] md   // min   m: data
);

wire [DW-1:0] r;
fpop #(DW,0,0,1,"SUB") fpsub (clk,ena,rst,xd,yd,r);
assign {mi,md} = r[DW-1] ? {xi,xd} : {yi,yd};

endmodule
