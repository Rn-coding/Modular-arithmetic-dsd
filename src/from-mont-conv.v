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