`include "utils.vh"

module hpq #(
   parameter N     = 1024, // N: dataset size
   parameter D     = 32   , // D: vector dimension	
   parameter W     = 32  , // W: datawidth
   parameter M     = 8   , // M: number of subspaces
   parameter alpha = 32  , // alpha
   parameter betta = 1   , // betta
   parameter Kt    = 32  , // k_tilde (k~): PQ codebook size
   parameter Pt    = 16  , // p_tilde (p~): phase 1 (codebook updates) parallelism
   parameter Ph     = 8     // p_hat   (p^): phase 2 (database search ) parallelism  
)(
   input            clk  , // global clock
   input            ena  , // registers enable
   input            rst  , // async reset
   input            start, // start search
   input  [W*D-1:0] x    , // query vector
	output           done , // search is done
   output [31:0]    minidx // index of nearest vector
);

//localparam IW = `log2(TW);
localparam H = `log2(N)/`log2(alpha);
// minidx chain
wire [31:0] minidx_t [H:0];
assign minidx_t[0] = 31'b0;

wire                    cb_dist_wena;
wire [`log2(Kt/Pt)-1:0] cb_dist_addr;
wire [`log2(Kt/Pt)-1:0] cb_cent_addr;
wire [31:0] offset [H:0];
controller #(
      .N    (N    ),
	   .D    (D    ),
	   .W    (W    ),
	   .M    (M    ),
      .alpha(alpha),
      .betta(betta),
      .Kt   (Kt   ), // k_tilde (k~): PQ codebook size
      .Pt   (Pt   ), // p_tilde (p~): phase 1 (codebook updates) parallelism
      .Ph   (Ph   )  // p_hat   (p^): phase 2 (database search ) parallelism  
) hpq_controller(
      .clk(clk),
      .ena(ena),
      .rst(rst),
		.start(start),
	   .done(done),
      .cb_dist_wena(cb_dist_wena), // control: distances ram write enable
      .cb_dist_addr(cb_dist_addr), // [`log2(Kt/Pt)-1:0] distances ram addresses
      .cb_cent_addr(cb_cent_addr), // [`log2(Kt/Pt)-1:0] centroid ram addresses
      .offset      (offset[0]   )  // Yt address offset
);

genvar gi;
generate
  for (gi=0 ; gi<H ; gi=gi+1) begin: HPQSLICE
    hpq_slice #(
      .N    (N/(alpha**(H-gi-1))),
	   .D    (D    ),
	   .W    (W    ),
	   .M    (M    ),
      .alpha(alpha),
      .betta(betta),
      .Kt   (Kt   ), // k_tilde (k~): PQ codebook size
      .Pt   (Pt   ), // p_tilde (p~): phase 1 (codebook updates) parallelism
      .Ph   (Ph   )  // p_hat   (p^): phase 2 (database search ) parallelism  
   ) hpq_slice_0(
      .clk(clk),
      .ena(ena),
      .rst(rst),
      .cb_dist_wena(cb_dist_wena), // control: distances ram write enable
      .cb_dist_addr(cb_dist_addr), // [`log2(Kt/Pt)-1:0] distances ram addresses
      .cb_cent_addr(cb_cent_addr), // [`log2(Kt/Pt)-1:0] centroid ram addresses
      .offset_in   (offset[gi]  ), // Yt address offset
      .offset_out  (offset[gi+1]), // Yt address offset		
      .x         (x             ), // [W*D   -1:0]: query vector
      .minidx_in (minidx_t[gi  ]),
      .minidx_out(minidx_t[gi+1])
   );
  end
endgenerate

assign minidx = minidx_t[H];

endmodule
