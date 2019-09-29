module fpaddtree #(
  parameter DW = 32     , // data width
  parameter TW = 16       // tree width
)(
  input              clk, // global clock
  input              ena, // registers enable
  input              rst, // async reset
  input  [TW*DW-1:0] x  , // packed input x; TW inputs of DW bits each
  output [   DW-1:0] r    // result
);

wire [DW-1:0] rl;
wire [DW-1:0] rr;
	
generate
  if (TW == 2) begin : BASE
    fpop #(DW,0,0,1,"ADD") fpadd_base (clk,ena,rst,x[2*DW-1:DW],x[DW-1:0],r);
  end
  else begin : STEP
    fpaddtree #(DW,TW/2       ) fpaddtree_l (clk,ena,rst,x[TW*DW/2-1:0      ],rl);
    fpaddtree #(DW,TW/2       ) fpaddtree_r (clk,ena,rst,x[TW*DW-1  :TW*DW/2],rr);
    fpop      #(DW,0,0,1,"ADD") fpadd_merge (clk,ena,rst,rl,rr,r);
  end
endgenerate

endmodule
