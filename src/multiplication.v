module mod_mul #(
    parameter WIDTH   = 32,
    parameter MOD     = 998244353,
    parameter NPRIME  = 998244351,
    parameter R2MOD   = 932051910 
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);

    wire [WIDTH-1:0] a_mont;
    wire [WIDTH-1:0] b_mont;
    wire [WIDTH-1:0] prod_mont;
    wire [WIDTH-1:0] prod_normal;

    to_mont #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME), .R2MOD(R2MOD))
    conv_a (.x(a), .x_mont(a_mont));

    to_mont #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME), .R2MOD(R2MOD))
    conv_b (.x(b), .x_mont(b_mont));

    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) 
    mul1 (.a(a_mont), .b(b_mont), .result(prod_mont));

    from_mont #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) 
    conv_res (.x_mont(prod_mont), .x_normal(prod_normal));

    assign result = prod_normal;

endmodule