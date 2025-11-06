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

    wire [2*WIDTH-1:0] m_full;
    assign m_full = t_low * NPRIME;

    wire [WIDTH-1:0] m;
    assign m = m_full[WIDTH-1:0];

    wire [2*WIDTH-1:0] u_full;
    assign u_full = t + (m * MOD);

    wire [WIDTH-1:0] u;
    assign u = u_full >> WIDTH;

    assign result = (u >= MOD) ? u - MOD : u;

endmodule