module mod_sub #(parameter WIDTH = 32, MOD = 998244353) (
    input [WIDTH-1:0] a, b, 
    output [WIDTH-1:0] result
);
    assign result = (a >= b) ?
                    a - b :
                    a - b + MOD;
endmodule

/*
In this design, since all operands are restricted to the modular range [0, MOD−1]
and MOD < 2^31, the expression a + MOD does not overflow a 32-bit wire.
Therefore, no width extension is necessary for correctness.”
*/