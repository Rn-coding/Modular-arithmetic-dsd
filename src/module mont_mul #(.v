module mont_mul #(
    parameter WIDTH   = 32,
    parameter MOD     = 998244353,
    parameter NPRIME  = 998244351    // precomputed (-MOD^-1 mod 2^WIDTH)
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // Step 1: full product
    wire [2*WIDTH-1:0] t = a * b;

    // Step 2: low WIDTH bits of t
    wire [WIDTH-1:0] t_low = t[WIDTH-1:0];

    // Step 3: m = (t_low * NPRIME) mod 2^WIDTH
    wire [WIDTH-1:0] m = (t_low * NPRIME)[WIDTH-1:0];

    // Step 4: u = (t + m * MOD) / R = (t + m*M) >> WIDTH
    wire [2*WIDTH-1:0] t_plus_mM = t + m * MOD;
    wire [WIDTH-1:0] u = t_plus_mM[2*WIDTH-1:WIDTH];

    // Step 5: conditional subtraction if u >= MOD
    assign result = (u >= MOD) ? (u - MOD) : u;

endmodule
