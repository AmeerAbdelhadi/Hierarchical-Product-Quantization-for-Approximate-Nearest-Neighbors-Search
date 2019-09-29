////////////////////////////////////////////////////////////////////////////////////
//                      dpram.v: Generic dual-ported RAM                          //
//                                                                                //
//          Author: Ameer M.S. Abdelhadi (ameer.abdelhadi@gmail.com)              //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module dpram
#( parameter MD = 16, // memory depth
   parameter DW = 32, // data width
   parameter INI = ""  // initialization: CLR for zeros, or hex/bin file name (file extension .hex/.bin)
)( input                  clk   , // global clock
   input                  wEn0  , // write enable for port 0
   input                  wEn1  , // write enable for port 1
   input  [`log2(MD)-1:0] addr0 , // address      for port 0
   input  [`log2(MD)-1:0] addr1 , // address      for port 1
   input  [DW       -1:0] wData0, // write data   for port 0
   input  [DW       -1:0] wData1, // write data   for port 1
   output reg [DW   -1:0] rData0, // read  data   for port 0
   output reg [DW   -1:0] rData1  // read  data   for port 1
);

// local parameters
localparam INIEXT = INI[23:0]; // extension of initializing file (if exists)

// initialize RAM, with zeros if CLR or file if INI.
integer i;
reg [DW-1:0] mem [0:MD-1]; // memory array
initial
  if (INI=="CLR") // if "CLR" initialize with zeros
    for (i=0; i<MD; i=i+1) mem[i] = {DW{1'b0}};
  else
    case (INIEXT) // check if file extension
       "hex": $readmemh(INI, mem); // if ".hex" use readmemh
       "bin": $readmemb(INI, mem); // if ".bin" use readmemb
    endcase

// PORT A
always @(posedge clk) begin
  // write/read; nonblocking statement to read old data
  if (wEn0) begin
    mem[addr0] <= wData0; // Change into blocking statement (=) to read new data
    rData0     <= wData0; // flow-through
  end else
    rData0 <= mem[addr0]; //Change into blocking statement (=) to read new data
end

// PORT B
always @(posedge clk) begin
  // write/read; nonblocking statement to read old data
  if (wEn1) begin
    mem[addr1] <= wData1; // Change into blocking statement (=) to read new data
    rData1     <= wData1; // flow-through
  end else
    rData1 <= mem[addr1]; //Change into blocking statement (=) to read new data
end

endmodule
