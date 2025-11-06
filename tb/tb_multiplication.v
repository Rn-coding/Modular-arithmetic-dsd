module tb_mont_redc;

    localparam integer WIDTH   = 32;
    localparam integer MOD     = 998244353;
    localparam integer NPRIME  = 32'd998244351;
    localparam integer TESTS   = 20;
    localparam integer R2MOD   = 32'd932051910;

    reg  [WIDTH-1:0] a, b;
    wire [WIDTH-1:0] result;

    // Instantiate DUT
    mod_mul #(
        .WIDTH(WIDTH),
        .MOD(MOD),
        .NPRIME(NPRIME),
        .R2MOD(R2MOD)
    ) dut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Internal variables
    integer i;
    reg [63:0] ref_result;
    integer errors = 0;

    // Task to run test case
    task run_test(input [WIDTH-1:0] a_in, input [WIDTH-1:0] b_in);
        begin
            a = a_in;
            b = b_in;
            #10;

            // check normal computation
            ref_result = ( (a_in * b_in) % MOD );

            if (result !== ref_result[WIDTH-1:0]) begin
                $display("Error: a=%0d b=%0d | Expected=%0d Got=%0d",
                          a_in, b_in, ref_result, result);
                errors = errors + 1;
            end
            else begin
                $display("Done: a=%0d b=%0d -> %0d", a_in, b_in, result);
            end
        end
    endtask

    initial begin
        errors = 0;

        $display("Starting multiplication tests.");

        // manual corner cases
        run_test(0, 0);
        run_test(0, 123456);
        run_test(1, 1);
        run_test(1, MOD-1);
        run_test(MOD-1, MOD-1);

        // Randomized tests
        for (i = 0; i < TESTS; i = i + 1) begin
            run_test($random, $random);
        end

        // Summary
        if (errors == 0)
            $display("All tests passed");
        else
            $display("%0d tests failed.", errors);

        $finish;
    end

endmodule
