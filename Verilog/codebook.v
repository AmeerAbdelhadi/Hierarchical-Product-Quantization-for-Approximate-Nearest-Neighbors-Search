`include "utils.vh"

module codebook
#(parameter W = 32    , // datawidth
  parameter Dt = 8    , // D_tilde (D~): subspace dimension
  parameter Kt = 32   , // k_tilde (k~): PQ codebook size
  parameter Pt = 16   , // p_tilde (p~): phase 1 (codebook updates) parallelism
  parameter Ph = 8      // p_hat   (p^): phase 2 (database search ) parallelism  
)(
  input           clk,  // global clock
  input           ena,  // registers enable
  input           rst,  // async reset
  input                     dist_wena, // control: distances ram write enable
  input  [`log2(Kt/Pt)-1:0] dist_addr, // distances ram addresses
  input  [`log2(Kt/Pt)-1:0] cent_addr, // centroid ram addresses
  input  [W*Dt   -1:0] u, // subspace vector
  input  [`log2(Kt)*Ph-1:0] ra, // Ph read addresses
  output [W        *Ph-1:0] sd  // Ph distances
);

localparam CBAW = `log2(Kt)  ; // codebook address width
localparam OSAW = `log2(Pt)  ; // output selector address wdith
localparam DMAW = CBAW-OSAW  ; // dist mem address width
localparam SQDL = 3+`log2(Dt); // latency of squared distance unit

// distances memory has Kt distances, each Pt packed in a line
// the input ra is a packed read addresses of the Kt distances
// dist_mem_ra is the address in the packed memory
reg [DMAW*Ph-1:0] dist_mem_ra;
reg [OSAW*Ph-1:0] out_sel;
integer i;
always @(*)
  for (i=0;i<Ph;i=i+1)
    {dist_mem_ra[i*DMAW +: DMAW],out_sel[i*OSAW +: OSAW]} = ra[i*CBAW +: CBAW];

wire [W*Pt*Ph-1:0] rdist; // read  square distances
wire [W*Pt   -1:0] wdist; // write square distances
mrdpramSS
#(.MD   (Kt/Pt), // memory depth
  .DW   ( W*Pt), // data width
  .nR   (   Ph), // number of reading ports
  .BYP  (1    ), // bypass? 0:none; 1: single-stage; 2:two-stages
  .INI  ("CLR")  // initialization: CLR for zeros, or hex/bin file name (file extension .hex/.bin)
) dist_ram (
  .clk  (clk), // clock
  .wEn  (dist_wena), // write enable  (1 port)
  .wAddr(dist_addr), // [`log2(MD)   -1:0]: write address (1 port)
  .wData(wdist), // [DW          -1:0]: write data    (1 port)
  .rAddr(dist_mem_ra), // [`log2(MD)*nR-1:0]: read  addresses - packed from nR read  ports
  .rData(rdist)  // [DW       *nR-1:0]: read  data      - packed from nR read ports
);

muxarr #(
  .DW(W ), // data width
  .MW(Pt), // mux width
  .NM(Ph)  // number of packed muxes
) muxarr_out (
  .inp(rdist  ), // [   DW*MW *NM-1:0]: MW, DW-wide inputs for NM muxes
  .sel(out_sel), // [`log2(MW)*NM-1:0]: log2(MW)-wide selectors for NM muxes
  .out(sd     )  // [   DW    *NM-1:0]: DW-wide outputs for NM muxes
);

wire [W*Dt*Pt-1:0] cent;
dpram_bbs #(
  .MD (Kt/Pt  ), // memory depth
  .DW (W*Dt*Pt), // data width
  .BYP(1      ), // bypass? 0:none; 1: single-stage; 2: two-stage
  .INI("CLR"  )  // initialization: CLR for zeros, or hex/bin file name (file extension .hex/.bin)
) cent_ram (
  .clk   (clk    ), // global clock
  .wEn0  (1'b0   ), // write enable for port 0
  .wEn1  (1'b0   ), // write enable for port 1
  .addr0 (       ), // [`log2(MD)-1:0]: write addresses - packed from nWP write ports
  .addr1 (cent_addr), // [`log2(MD)-1:0]: write addresses - packed from nWP write ports
  .wData0(       ), // [DW       -1:0]: write data      - packed from nRP read ports
  .wData1(       ), // [DW       -1:0]: write data      - packed from nRP read ports
  .rData0(       ), // [DW   -1:0]: read  data      - packed from nRP read ports
  .rData1(cent   )  // [DW   -1:0]: read  data      - packed from nRP read ports
);

genvar gi;
generate
  for (gi=0 ; gi<Pt ; gi=gi+1) begin: SQRD
    fpsqrdist #(
      .W(W), // data width
      .D(Dt)   // vector dim
    ) fpsqrdist_arr (
      .clk(clk), // global clock
      .ena(ena), // registers enable
      .rst(rst), // async reset
      .x  (u                     ), //[D*W-1:0]:  D-dim vector x
      .y  ( cent[gi*W*Dt +: W*Dt]), //[D*W-1:0]: D-dim vector y
      .sd (wdist[gi*W    +: W   ])  //[  W-1:0]:squared distance
    );
  end
endgenerate

endmodule
