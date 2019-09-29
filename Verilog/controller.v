 module controller #(
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
   input           clk  ,
   input           ena  ,
   input           rst  ,
	input           start,
	output reg      done ,
   output                     cb_dist_wena, // control: distances ram write enable
   output reg [`log2(Kt/Pt)-1:0] cb_dist_addr, // distances ram addresses
   output reg [`log2(Kt/Pt)-1:0] cb_cent_addr, // centroid ram addresses
   output reg [31:0]             offset        // Yt address offset
);

localparam Dt = D/M; // D_tilde (D~): subspace dimension
localparam DMAW = `log2(Kt/Pt)  ; // dist mem address width
localparam SQDL = 3+`log2(Dt); // latency of squared distance unit
localparam H = `log2(N)/`log2(alpha);
localparam VD = alpha*betta/Ph; // Voronoi cell depth for onr Yt ram block
localparam CMPL = VD+5+`log2(M)+`log2(Ph);

// FSM
// state declaration
reg [2:0] curstt, nxtstt;
localparam IDLE = 3'b000; // idle state
localparam CENT = 3'b001; // codebook centroid read
localparam DIST = 3'b010; // codebook distance write
localparam MIND = 3'b011; // minimum distance
localparam WAIT = 3'b100; // wait
localparam DONE = 3'b101; // done

reg cbaddr_rst;
reg cbaddr_inc;
reg offset_rst;
reg offset_inc;
reg wait_rst;
reg wait_inc;

// synchronous process
always @(posedge clk, posedge rst)
  if (rst) curstt <= IDLE;
  else     curstt <= nxtstt;

// combinatorial process
always @(*) begin
  // initial outputs
  cbaddr_rst = 1'b1; 
  cbaddr_inc = 1'b0;
  offset_rst = 1'b1;
  offset_inc = 1'b0;
  wait_rst   = 1'b1;
  wait_inc   = 1'b0; 
  done       = 1'b0;
  case (curstt)
    IDLE: begin // idle state until start
            nxtstt     = start ? CENT : IDLE;
          end
    CENT: begin // codebook centroid memory address count
            nxtstt     = cb_cent_done ? DIST : CENT;
            cbaddr_rst = 1'b0;
            cbaddr_inc = 1'b1;
          end
    DIST: begin // codebook disance memory address count (delayed)
            nxtstt     = cb_dist_done ? MIND : DIST;
          end
    MIND: begin // min distance: offset address scounter
            nxtstt     = offset_done ? WAIT : MIND;
            offset_rst = 1'b0;
            offset_inc = 1'b1;
            wait_rst  = 1'b0;
            wait_inc  = 1'b1;
          end
    WAIT: begin
            nxtstt     =  wait_done ? DONE : WAIT;
            wait_rst = 1'b0;
            wait_inc = 1'b1;
          end
    DONE: begin
            nxtstt     = IDLE;
            done       = 1'b1;
          end
  endcase
end

///////////////// codebooks address generation /////////////////

// counter for codebook centroids read addresses
always @(posedge clk, posedge rst)
  if (rst)
      cb_cent_addr <= {DMAW{1'b0}};
  else 
	   cb_cent_addr <= (cb_cent_addr+{{(DMAW-1){1'b0}},cbaddr_inc}) & {DMAW{!cbaddr_rst}};
wire cb_cent_done = (cb_cent_addr == (Kt/Pt-1)) ? 1'b1 : 1'b0;

// generate distance write address by delaying the read address
// use the latency of square distance computation SQDL as the delay
wire cbaddr_rst_d;
wire cbaddr_inc_d;
delayline #(
  .W(2) , // data width
  .L(SQDL)  // delayline latency in cycles
) addr_du_dl (
  .clk(clk      ), // global clock
  .ena(ena      ), // registers enable
  .rst(rst      ), // async reset
  .d  ({cbaddr_inc  ,cbaddr_rst}), // [W-1:0]: input
  .q  ({cbaddr_inc_d,cbaddr_rst_d})  // [W-1:0]: delyed output
);
assign cb_dist_wena = cbaddr_rst_d;

// counter for codebook centroids read addresses / avtivate after SQDL cycles
always @(posedge clk, posedge rst)
  if (rst)
      cb_dist_addr <= {DMAW{1'b0}};
  else 
	   cb_dist_addr <= (cb_dist_addr+{{(DMAW-1){1'b0}},cbaddr_inc_d}) & {DMAW{!cbaddr_rst_d}};
wire cb_dist_done = (cb_cent_addr == (Kt/Pt-1)) ? 1'b1 : 1'b0;

//////////////////////////////////

// offset addressing
always@(posedge clk, posedge rst)
  if (rst) offset <= 32'b0;
  else offset <= (offset+{{31{1'b0}},offset_inc}) & {32{!offset_rst}};
wire offset_done = (offset == (alpha*betta/Ph)) ? 1'b1 : 1'b0;

/////

// wait counter
reg [31:0] wait_cnt;
always@(posedge clk, posedge rst)
  if (rst) wait_cnt <= 32'b0;
  else wait_cnt <= (wait_cnt+{{31{1'b0}},wait_inc}) & {32{!wait_rst}};
wire wait_done = (wait_cnt == H*CMPL) ? 1'b1 : 1'b0;

endmodule
