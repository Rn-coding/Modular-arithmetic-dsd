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