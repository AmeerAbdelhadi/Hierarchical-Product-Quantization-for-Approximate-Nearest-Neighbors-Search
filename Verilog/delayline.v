module delayline #(
  parameter W = 4 , // data width
  parameter L = 10  // delayline latency in cycles
)(
  input  clk, // global clock
  input  ena, // registers enable
  input  rst, // async reset
  input  [W-1:0] d, // input
  output [W-1:0] q  // delyed output
);

reg [W-1:0] qi [L-1:0];
integer i;
always@(posedge clk or posedge rst)
  if (rst)
    for (i=0;i<L;i=i+1)
      qi[i] <= {W{1'b0}};
  else
    for (i=0;i<L;i=i+1)
	   qi[i] <= (i==0) ? d : qi[i-1];

assign q=qi[L-1];

/*
// add 'reg' to output if you use this version
reg [L-1:0] qi [W-1:0];
integer i;
always@(posedge clk or posedge rst)
  if (rst) for (i=0;i<W;i=i+1)
    qi[i] <= {L{1'b0}    };
  else for (i=0;i<W;i=i+1)
    qi[i] <= {qi[i][L-2:0],d[i]};

always @(*)
  for (i=0;i<W;i=i+1) q[i]=qi[i][L-1];
*/
 
endmodule
