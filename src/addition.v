module mod_add #(parameter WIDTH = 32, MOD = 998244353) (
    input [WIDTH-1:0] a, b, 
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] sum = a + b;
    assign result = (sum >= MOD) ? (sum - MOD) : sum;
endmodule