`timescale 1ns/1ps

module tb_mont_modexp;

    localparam integer WIDTH   = 32;
    localparam integer MOD     = 998244353;
    localparam integer NPRIME  = 32'd998244351;  // (-MOD^-1) mod 2^WIDTH
    localparam integer R2MOD   = 32'd932051910;  // (2^(2*WIDTH)) mod MOD
    localparam integer TESTS   = 10;             // number of random testcases

    reg                    clk;
    reg                    rst;
    reg                    start;
    reg  [WIDTH-1:0]       base;
    reg  [WIDTH-1:0]       exp;
    wire                   done;
    wire [WIDTH-1:0]       result;

    // Instantiate Dut
    mont_modexp #(
        .WIDTH(WIDTH),
        .MOD(MOD),
        .NPRIME(NPRIME),
        .R2MOD(R2MOD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .base(base),
        .exp(exp),
        .done(done),
        .result(result)
    );

    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Software-style modular exponentiation
    function automatic [WIDTH-1:0] modexp_ref(
        input [WIDTH-1:0] b,
        input [WIDTH-1:0] e
    );
        reg [63:0] acc;
        reg [63:0] bb;
        reg [WIDTH-1:0] ee;
        begin
            acc = 1;
            bb = b;
            ee = e;
            while (ee > 0) begin
                if (ee[0]) acc = (acc * bb) % MOD;
                bb = (bb * bb) % MOD;
                ee = ee >> 1;
            end
            modexp_ref = acc[WIDTH-1:0];
        end
    endfunction

    
    integer i;
    reg [WIDTH-1:0] ref;
    integer errors = 0;

    
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        base = 0;
        exp = 0;
        #20; rst = 0;

        // Fixed tests
        run_test(2, 0);
        run_test(2, 1);
        run_test(2, 2);
        run_test(5, 13);
        run_test(MOD-1, 2);
        run_test(MOD-1, 3);

        // Random tests
        for (i = 0; i < TESTS; i = i + 1) begin
            run_test($random, $random % (1 << (WIDTH-2))); // smaller exponents for fast sim
        end

        // Results summary
        if (errors == 0)
            $display("All tests passed!");
        else
            $display("%0d tests failed.", errors);

        $finish;
    end

    // Task to run test case
    task run_test(input [WIDTH-1:0] base_in, input [WIDTH-1:0] exp_in);
        begin
            base = base_in;
            exp  = exp_in;
            ref  = modexp_ref(base_in, exp_in);

            $display("\nStarting test: base=%0d, exp=%0d (expect %0d)", base_in, exp_in, ref);
            
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done == 1);
            @(posedge clk);

            if (result === ref)
                $display("Done: base=%0d exp=%0d -> result=%0d", base_in, exp_in, result);
            else begin
                $display("Error: base=%0d exp=%0d | Got %0d Expected %0d", base_in, exp_in, result, ref);
                errors = errors + 1;
            end
        end
    endtask

endmodule
