module mont_redc #(
    parameter WIDTH   = 32,
    parameter MOD     = 998244353,
    parameter NPRIME  = 998244351    // precomputed
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);

    wire [2*WIDTH-1:0] t;
    assign t = a * b;

    wire [WIDTH-1:0] t_low;
    assign t_low = t[WIDTH-1:0];

    wire [WIDTH-1:0] m;
    assign m = (t_low * NPRIME)[WIDTH-1:0];

    wire [2*WIDTH-1:0] u_full;
    assign u_full = t + (m * MOD);

    wire [WIDTH-1:0] u;
    assign u = u_full >> WIDTH;

    assign result = (u >= MOD) ? u - MOD : u;

endmodule

module to_mont #(
    parameter WIDTH   = 32,
    parameter MOD     = 998244353,
    parameter NPRIME  = 998244351,
    parameter R2MOD   = 932051910   // precomputed R^2 mod MOD
)(
    input  wire [WIDTH-1:0] x,
    output wire [WIDTH-1:0] x_mont
);
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME))
        mul1 (.a(x), .b(R2MOD), .result(x_mont));
endmodule


module from_mont #(
    parameter WIDTH   = 32,
    parameter MOD     = 998244353,
    parameter NPRIME  = 998244351
)(
    input  wire [WIDTH-1:0] x_mont,
    output wire [WIDTH-1:0] x_normal
);
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME))
        mul1 (.a(x_mont), .b(1), .result(x_normal));
endmodule
