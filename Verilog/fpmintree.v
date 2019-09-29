`include "utils.vh"

module fpmintree
#( parameter DW = 32     , // data width
   parameter TW = 8      , // tree width
   parameter IW = 3        // index width - log2(TW)
)( input              clk, // global clock
   input              ena, // registers enable
   input              rst, // async reset
   input  [TW*IW-1:0] xi , // packed indicies xi; TW indicies of log2(TW) bits each
   input  [TW*DW-1:0] xd , // packed input    xd; TW inputs   of DW       bits each
   output [   IW-1:0] mi , // index of min
   output [   DW-1:0] md   // min data
);

wire [DW-1:0] md_l, md_r;
wire [IW-1:0] mi_l, mi_r;

generate
  if (TW == 2) begin : BASE
    fpmin #(DW,IW) fpmin_base (
      clk, ena, rst,
      xi[2*IW-1:IW],xd[2*DW-1:DW],
      xi[  IW-1:0 ],xd[  DW-1:0 ],
      mi, md
    );
  end
  else begin : STEP
    fpmintree #(DW,TW/2) fpmintree_r (
      clk, ena, rst,
      xi[TW*IW/2-1:0],
      xd[TW*DW/2-1:0],
      mi_r, md_r
    );
    fpmintree #(DW,TW/2) fpmintree_l (
      clk, ena, rst,
      xi[TW*IW-1:TW*IW/2],
      xd[TW*DW-1:TW*DW/2],
      mi_l, md_l
    );
    fpmin #(DW,IW) fpmin_merge (
      clk, ena, rst,
      mi_l, md_l,
      mi_r, md_r,
      mi,   md
    );
  end
endgenerate

endmodule
