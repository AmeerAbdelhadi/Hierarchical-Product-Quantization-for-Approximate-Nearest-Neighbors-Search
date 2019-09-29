`include "utils.vh"

module hpq_slice #(
   parameter N = 1024,	
	parameter D = 32,
	parameter W = 32,
	parameter M = 8,
   parameter alpha = 32,
   parameter betta = 1,
   parameter Kt = 32   , // k_tilde (k~): PQ codebook size
   parameter Pt = 16   , // p_tilde (p~): phase 1 (codebook updates) parallelism
   parameter Ph = 8      // p_hat   (p^): phase 2 (database search ) parallelism  
)(
   input           clk ,
   input           ena ,
   input           rst,
	
   // codebook
   input                     cb_dist_wena, // control: distances ram write enable
   input  [`log2(Kt/Pt)-1:0] cb_dist_addr, // distances ram addresses
   input  [`log2(Kt/Pt)-1:0] cb_cent_addr, // centroid ram addresses
   input  [31:0]             offset_in, // Yt address offset
   output [31:0]             offset_out, // Yt address offset
   input  [W*D-1:0] x, // query vector
   input  [31:0] minidx_in ,
   output [31:0] minidx_out
);


	//codebook
  localparam Dt = D/M; // D_tilde (D~): subspace dimension
  localparam CW = `log2(Kt)  ; // code width
  localparam VD = alpha*betta/Ph; // Voronoi cell depth for onr Yt ram block

// delayed offset

localparam CMPL = VD+5+`log2(M)+`log2(Ph);
delayline #(
  .W(32) , // data width
  .L(CMPL)  // delayline latency in cycles
) addr_du_dl (
  .clk(clk      ), // global clock
  .ena(ena      ), // registers enable
  .rst(rst      ), // async reset
  .d  (offset_in), // [W-1:0]: input
  .q  (offset_out)  // [W-1:0]: delyed output
);
  
// codebooks
wire [M*CW*Ph-1:0] cb_ra; // M*Ph read addresses
wire [M*W *Ph-1:0] cb_sd;  // M*Ph square distances
genvar gi;
generate
  for (gi=0;gi<M;gi=gi+1) begin : CB
    codebook #(
	   .W (W ), // datawidth
      .Dt(Dt), // D_tilde (D~): subspace dimension
      .Kt(Kt), // k_tilde (k~): PQ codebook size
      .Pt(Pt), // p_tilde (p~): phase 1 (codebook updates) parallelism
      .Ph(Ph)  // p_hat   (p^): phase 2 (database search ) parallelism  
    ) codebook_inst (
      .clk     (clk     ),  // input : global clock
      .ena     (ena     ),  // input : registers enable
      .rst     (rst     ),  // input : async reset
      .dist_wena(cb_dist_wena), // control: distances ram write enable
      .dist_addr(cb_dist_addr), // input : [`log2(Kt/Pt)-1:0] distances ram addresses
      .cent_addr(cb_cent_addr), // input : [`log2(Kt/Pt)-1:0] centroid ram addresses		
      .u       (    x[gi* W*Dt  +: W*Dt]), // input : [W*Dt   -1:0]subspace vector
      .ra      (cb_ra[gi*CW*Ph +: CW*Ph]), // input : [`log2(Kt)*Ph-1:0]: Ph read addresses
      .sd      (cb_sd[gi* W*Ph +:  W*Ph])  // output: [W        *Ph-1:0]: Ph distances
    );
  end
endgenerate



wire  [`log2(N*betta/Ph)-1:0] addr_Yt = VD*minidx_in+offset_in;

// encoded dataset Yt
wire [Ph*M*CW-1:0] codesYt;
generate
  for (gi=0;gi<Ph;gi=gi+1) begin : Yt
    dpram_bbs #(
      .MD (N*betta/Ph), // memory depth
      .DW (M*CW), // data width
      .BYP(1      ), // bypass? 0:none; 1: single-stage; 2: two-stage
      .INI("CLR"  )  // initialization: CLR for zeros, or hex/bin file name (file extension .hex/.bin)
    ) cent_ram (
      .clk   (clk    ), // global clock
      .wEn0  (1'b0   ), // write enable for port 0
      .wEn1  (1'b0   ), // write enable for port 1
      .addr0 (       ), // [`log2(MD)-1:0]: write addresses - packed from nWP write ports
      .addr1 (addr_Yt), // [`log2(MD)-1:0]: write addresses - packed from nWP write ports
      .wData0(       ), // [DW       -1:0]: write data      - packed from nRP read ports
      .wData1(       ), // [DW       -1:0]: write data      - packed from nRP read ports
      .rData0(       ), // [DW   -1:0]: read  data      - packed from nRP read ports
      .rData1(codesYt[gi*M*CW +: M*CW])  // [DW   -1:0]: read  data      - packed from nRP read ports
    );
  end
endgenerate


// rearrange codes to address codebooks
genvar gm;
genvar gp;
generate
  for (gm=0;gm<M;gm=gm+1) begin: WIREm
    for (gp=0;gp<Ph;gp=gp+1) begin: WIREp
      assign cb_ra[(gp+gm*Ph)*CW +: CW] = codesYt[(gp*M+gm)*CW +: CW];
    end
  end
endgenerate

// rearrange codebooks outputs to feed the adder-tree
wire [Ph*M*W-1:0] sd;  // M*Ph square distances
generate
  for (gm=0;gm<M;gm=gm+1) begin: WIREm2
    for (gp=0;gp<Ph;gp=gp+1) begin: WIREg2
      assign sd[(gp*M+gm)*W +: W] = cb_sd[(gp+gm*Ph)*W +: W];
    end
  end
endgenerate

// generate adder-trees
wire [Ph*W-1:0] sd_sum;
generate
  for (gp=0;gp<Ph;gp=gp+1) begin :ADDTREE
    fpaddtree #(
      .DW(W), // data width
      .TW(M)  // tree width
    ) fpaddtree_sqrdst (
      .clk(clk), // global clock
      .ena(ena), // registers enable
      .rst(rst), // async reset
      .x(sd[gp*M*W +: M*W]), // [TW*DW-1:0]: packed input x; TW inputs of DW bits each
      .r(sd_sum[gp*W +: W])  // [   DW-1:0]: result
    );
  end
endgenerate

// generate and pack sequential indices 
integer cnt;
reg [Ph*`log2(Ph)-1:0] idx;  // M*Ph square distances
always @*
  for (cnt=0;cnt<Ph;cnt=cnt+1)
     idx[cnt*`log2(Ph) +: `log2(Ph)] = cnt[`log2(Ph)-1:0];

// generate min-tree
wire [`log2(Ph)-1:0] minidx_t;
wire [        W-1:0] minval_t;
fpmintree #(
  .DW(W       ), // data width
  .TW(      Ph), // tree width
  .IW(`log2(Ph)) // index width - log2(TW)
) fpmintree_sd (
  .clk(clk), // global clock
  .ena(ena), // registers enable
  .rst(rst), // async reset
  .xi(idx) , // input  [TW*IW-1:0]: packed indicies xi; TW indicies of log2(TW) bits each
  .xd(sd_sum) , // input  [TW*DW-1:0]: packed input    xd; TW inputs   of DW       bits each
  .mi(minidx_t) , // output [   IW-1:0]: index of min
  .md(minval_t)   // output [   DW-1:0]: min data
);

wire [W-1:0] minval;
reg  [W-1:0] minval_r;
always @(posedge clk, posedge rst)
  if (rst) minval_r <= {W{1'b0}};
  else     minval_r <= minval;

wire [31:0] minidx;
reg  [31:0] minidx_r;
always @(posedge clk, posedge rst)
  if (rst) minidx_r <= 31'b0;
  else     minidx_r <= minidx;

fpmin #(
  .DW(W), // data  wdith
  .IW(32) // index width
) fpmin_out (
  .clk(clk), // global clock
  .ena(ena), // output reg enable
  .rst(rst), // async reset
  .xi(minidx_t*VD+offset_in), // input x: [IW-1:0] index
  .xd(minval_t), // input x: [DW-1:0]data
  .yi(minidx_r), // input y: [IW-1:0]index
  .yd(minval_r), // input y: [DW-1:0] data
  .mi(minidx  ), // out: min   m: [IW-1:0]index
  .md(minval  )  // out: min   m: [DW-1:0]data
);

assign minidx_out = minidx ;

endmodule
