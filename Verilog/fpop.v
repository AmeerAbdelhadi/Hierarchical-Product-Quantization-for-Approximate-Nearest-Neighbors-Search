module fpop
#(parameter DW = 32   , // datawidth
  parameter RI = 0    , // register inputs
  parameter RP = 1    , // register pipeline
  parameter RO = 1    , // register output
  parameter OP = "ADD" // operation: "ADD","SUB","MUL","SQR"
)(
  input           clk,  // global clock
  input           ena,  // registers enable
  input           rst,  // async reset
  input  [DW-1:0] x  ,  // input x
  input  [DW-1:0] y  ,  // input y
  output [DW-1:0] r     // result
);

localparam ADD = (OP=="ADD"); // add
localparam SUB = (OP=="SUB"); // subtract
localparam MUL = (OP=="MUL"); // multiply
localparam SQR = (OP=="SQR"); // square
localparam FPA = ADD||SUB   ; // activate FP adder
localparam FPM = MUL||SQR   ; // activate FP multiplier

wire [DW-1:0] nc; // not connected

// generate and instantiate FP-DSP with specific implementation
generate
  if      (OP=="ADD") begin : FPADD
    // instantiate FP adder with addition operation
	 fpadd #(DW,RI,RP,RO,"ADD") fpaddi (clk,ena,rst,x,y,r);
  end
  else if (OP=="SUB") begin : FPSUB
    // instantiate FP adder with subtract operation
	 fpadd #(DW,RI,RP,RO,"SUB") fpsubi (clk,ena,rst,x,y,r);
  end
  else if (OP=="MUL") begin : FPMUL
    // instantiate FP multiplier with multiply operation
	 fpmul #(DW,RI,RP,RO     )  fpmuli (clk,ena,rst,x,y,r);
  end
  else                begin : FPSQR
    // instantiate FP multiplier with square operation
    fpmul #(DW,RI,RP,RO     )  fpsqri (clk,ena,rst,x,x,r);
  end
endgenerate
   
//twentynm_fp_mac  #(
//  .ax_clock            ((FPA&&RI)?"0":"NONE"   ), // adder's input only
//  .ay_clock            (      RI ?"0":"NONE"   ),
//  .az_clock            ((FPM&&RI)?"0":"NONE"   ), // multiplier's input only
//  .output_clock        (      RO ?"0":"NONE"   ),
//  .accumulate_clock    (              "NONE"   ),
//  .ax_chainin_pl_clock (              "NONE"   ),
//  .accum_pipeline_clock(              "NONE"   ),
//  .mult_pipeline_clock ((FPM&&RP)?"0":"NONE"   ), // multiplier pipelining
//  .adder_input_clock   ((FPM||RP)?"0":"NONE"   ),
//  .accum_adder_clock   (              "NONE"   ),
//  .use_chainin         (              "false"  ),
//  .operation_mode      (FPA?"sp_add" :"sp_mult"),
//  .adder_subtract      (SUB?"true"   :"false"  )
//) sp_fpop (
//  .clk     ({1'b0,1'b0,clk} ),
//  .ena     ({1'b0,1'b0,ena} ),
//  .aclr    ({rst ,rst     } ),
//  .ax      (FPA?x:nc        ), // input 1, adder only
//  .ay      (FPA?y:x         ), // input 2 for adder/ input 1 for multiplier
//  .az      (MUL?y:(SQR?x:nc)), // input 2 for multiplier, y for MUL, x for SQR
//  .chainin (32'b0           ),
//  .resulta (r               ),
//  .chainout(                )
//);

endmodule
