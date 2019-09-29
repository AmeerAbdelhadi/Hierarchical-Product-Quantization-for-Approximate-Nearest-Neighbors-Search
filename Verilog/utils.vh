////////////////////////////////////////////////////////////////////////////////////
//                utils.vh: Design utilities (pre-compile macros)                 //
//                                                                                //
//            Author: Ameer M.S. Abdelhadi (ameer.abdelhadi@gmail.com)            //
////////////////////////////////////////////////////////////////////////////////////

`ifndef __UTILS_VH__
`define __UTILS_VH__

// Initiate Array structure - use once before calling packing/unpacking modules
`define ARRINIT integer _i_,_j_
// pack/unpack 1D/2D/3D arrays; use in "always @*" if combinatorial
`define ARR2D1D(D1W,D2W,    SRC,DST) for(_i_=1;_i_<=(D1W);_i_=_i_+1)                                 DST[((D2W)*_i_-1)-:D2W] = SRC[_i_-1]
`define ARR1D2D(D1W,D2W,    SRC,DST) for(_i_=1;_i_<=(D1W);_i_=_i_+1)                                 DST[_i_-1] = SRC[((D2W)*_i_-1)-:D2W]
`define ARR2D3D(D1W,D2W,D3W,SRC,DST) for(_i_=0;_i_< (D1W);_i_=_i_+1) for(_j_=1;_j_<=(D2W);_j_=_j_+1) DST[_i_][_j_-1] = SRC[_i_][((D3W)*_j_-1)-:D3W]
`define ARR3D2D(D1W,D2W,D3W,SRC,DST) for(_i_=0;_i_< (D1W);_i_=_i_+1) for(_j_=1;_j_<=(D2W);_j_=_j_+1) DST[_i_][((D3W)*_j_-1)-:D3W] = SRC[_i_][_j_-1]

// print a 2-D array in a comma-delimited list
`define ARRPRN(ARRLEN,PRNSRC) for (_i_=(ARRLEN)-1;_i_>=0;_i_=_i_-1) $write("%c%h%c",(_i_==(ARRLEN)-1)?"[":"",PRNSRC[_i_],!_i_?"]":",")
// Initialize a vector with a specific width random number; extra bits are zero padded
`define RNDVEC(RAND,SEEDVAR,RANDW) RAND=0; repeat ((RANDW)/32) RAND=(RAND<<32)|{$random(SEEDVAR)}; RAND=(RAND<<((RANDW)%32))|({$random(SEEDVAR)}>>(32-(RANDW)%32))
`define RNDUNI(RAND,SEEDVAR,RANDMIN,RANDMAX) RAND=(RANDMIN)+{$random(SEEDVAR)}%((RANDMAX)-(RANDMIN)+1)


// MAX and MIN
`define MAX(SRCA,SRCB) ( ((SRCA)>(SRCB)) ? (SRCA) : (SRCB) )
`define MIN(SRCA,SRCB) ( ((SRCA)<(SRCB)) ? (SRCA) : (SRCB) )

// Zero padding
`define ZPAD(SRC,DSTW) ( {(DSTW){1'b0}} | SRC )

// priority encoder (for simulation), VLDBIN is a valid bit concatenated to a binary priority encoded output
`define PRIENC(WIDTH,ONEHOT,VLDBIN) for(VLDBIN=0 ; (VLDBIN<(WIDTH)) && !ONEHOT[VLDBIN] ; VLDBIN=VLDBIN+1) VLDBIN=VLDBIN

// factorial (n!)
`define fact(n)  ( ( ((n) >= 2      ) ? 2  : 1) * \
                   ( ((n) >= 3      ) ? 3  : 1) * \
                   ( ((n) >= 4      ) ? 4  : 1) * \
                   ( ((n) >= 5      ) ? 5  : 1) * \
                   ( ((n) >= 6      ) ? 6  : 1) * \
                   ( ((n) >= 7      ) ? 7  : 1) * \
                   ( ((n) >= 8      ) ? 8  : 1) * \
                   ( ((n) >= 9      ) ? 9  : 1) * \
                   ( ((n) >= 10     ) ? 10 : 1)   )

// ceiling of log2
`define log2(x)  ( ( ((x) >  1      ) ? 1  : 0) + \
                   ( ((x) >  2      ) ? 1  : 0) + \
                   ( ((x) >  4      ) ? 1  : 0) + \
                   ( ((x) >  8      ) ? 1  : 0) + \
                   ( ((x) >  16     ) ? 1  : 0) + \
                   ( ((x) >  32     ) ? 1  : 0) + \
                   ( ((x) >  64     ) ? 1  : 0) + \
                   ( ((x) >  128    ) ? 1  : 0) + \
                   ( ((x) >  256    ) ? 1  : 0) + \
                   ( ((x) >  512    ) ? 1  : 0) + \
                   ( ((x) >  1024   ) ? 1  : 0) + \
                   ( ((x) >  2048   ) ? 1  : 0) + \
                   ( ((x) >  4096   ) ? 1  : 0) + \
                   ( ((x) >  8192   ) ? 1  : 0) + \
                   ( ((x) >  16384  ) ? 1  : 0) + \
                   ( ((x) >  32768  ) ? 1  : 0) + \
                   ( ((x) >  65536  ) ? 1  : 0) + \
                   ( ((x) >  131072 ) ? 1  : 0) + \
                   ( ((x) >  262144 ) ? 1  : 0) + \
                   ( ((x) >  524288 ) ? 1  : 0) + \
                   ( ((x) >  1048576) ? 1  : 0) + \
                   ( ((x) >  2097152) ? 1  : 0) + \
                   ( ((x) >  4194304) ? 1  : 0)   )

// floor of log2
`define log2f(x) ( ( ((x) >= 2      ) ? 1  : 0) + \
                   ( ((x) >= 4      ) ? 1  : 0) + \
                   ( ((x) >= 8      ) ? 1  : 0) + \
                   ( ((x) >= 16     ) ? 1  : 0) + \
                   ( ((x) >= 32     ) ? 1  : 0) + \
                   ( ((x) >= 64     ) ? 1  : 0) + \
                   ( ((x) >= 128    ) ? 1  : 0) + \
                   ( ((x) >= 256    ) ? 1  : 0) + \
                   ( ((x) >= 512    ) ? 1  : 0) + \
                   ( ((x) >= 1024   ) ? 1  : 0) + \
                   ( ((x) >= 2048   ) ? 1  : 0) + \
                   ( ((x) >= 4096   ) ? 1  : 0) + \
                   ( ((x) >= 8192   ) ? 1  : 0) + \
                   ( ((x) >= 16384  ) ? 1  : 0) + \
                   ( ((x) >= 32768  ) ? 1  : 0) + \
                   ( ((x) >= 65536  ) ? 1  : 0) + \
                   ( ((x) >= 131072 ) ? 1  : 0) + \
                   ( ((x) >= 262144 ) ? 1  : 0) + \
                   ( ((x) >= 524288 ) ? 1  : 0) + \
                   ( ((x) >= 1048576) ? 1  : 0) + \
                   ( ((x) >= 2097152) ? 1  : 0) + \
                   ( ((x) >= 4194304) ? 1  : 0)   )

`endif //__UTILS_VH

