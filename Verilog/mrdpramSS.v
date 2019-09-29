////////////////////////////////////////////////////////////////////////////////////
// mrram.v: Multiread-RAM based on bank replication using generic dual-ported RAM //
//          with optional single-stage or two-stage bypass/ for normal mode ports //
//                                                                                //
//          Author: Ameer M.S. Abdelhadi (ameer.abdelhadi@gmail.com)              //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module mrdpramSS
#( parameter MD  = 16, // memory depth
   parameter DW  = 32, // data width
   parameter nR  = 3 , // number of reading ports
   parameter BYP = 1 , // bypass? 0:none; 1: single-stage; 2:two-stages
   parameter INI = ""  // initialization: CLR for zeros, or hex/bin file name (file extension .hex/.bin)
)( input                         clk  , // clock
   input                         wEn  , // write enable  (1 port)
   input      [`log2(MD)   -1:0] wAddr, // write address (1 port)
   input      [DW          -1:0] wData, // write data    (1 port)
   input      [`log2(MD)*nR-1:0] rAddr, // read  addresses - packed from nR read  ports
   output reg [DW       *nR-1:0] rData  // read  data      - packed from nR read ports
);

  // local parameters
  localparam AW = `log2(MD); // address width

  // unpacked read addresses/data
  reg  [AW-1:0] rAddr_upk [nR-1:0]; // read addresses - unpacked 2D array 
  wire [DW-1:0] rData_upk [nR-1:0]; // read data      - unpacked 2D array 

  // unpack read addresses; pack read data
  `ARRINIT;
  always @* begin
    `ARR1D2D(nR,AW,rAddr    ,rAddr_upk);
    `ARR2D1D(nR,DW,rData_upk,rData    );
  end

  // generate and instantiate generic RAM blocks
  genvar rpi;
  generate
    for (rpi=0 ; rpi<nR ; rpi=rpi+1) begin: RPORTrpi
      // generic dual-ported ram instantiation
      dpram_bbs   #( .MD    (MD            ), // memory depth
                     .DW    (DW            ), // data width
                     .BYP   (BYP           ), // bypass? 0: none; 1: single-stage; 2:two-stages
                     .INI   (INI           )  // initialization file, optional
      ) dpram_bbsi ( .clk   (clk           ), // global clock  - in
                     .wEn0  (1'b0          ), // write enable  - in
                     .wEn1  (wEn           ), // write enable  - in
                     .addr0 (rAddr_upk[rpi]), // write address - in : [`log2(MD)-1:0]
                     .addr1 (wAddr         ), // write address - in : [`log2(MD)-1:0]
                     .wData0({DW{1'b0}}    ), // write data    - in : [DW       -1:0] / constant
                     .wData1(wData         ), // write data    - in : [DW       -1:0]
                     .rData0(rData_upk[rpi]), // read  data    - out: [DW       -1:0]
                     .rData1(              )  // read  data    - out: [DW       -1:0]
      );
    end
  endgenerate

endmodule
