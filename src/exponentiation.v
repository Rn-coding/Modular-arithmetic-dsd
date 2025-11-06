module mont_modexp #(
    parameter integer WIDTH   = 32,
    parameter integer MOD     = 998244353,
    parameter integer NPRIME  = 32'd998244351,
    parameter integer R2MOD   = 32'd932051910   // R^2 mod MOD (precomputed)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,  // pulse to start operation
    input  wire [WIDTH-1:0]      base,   // base (normal)
    input  wire [WIDTH-1:0]      exp,    // exponent (normal)
    output reg                   done,
    output reg  [WIDTH-1:0]      result  // final result (normal)
);

    // States
    localparam IDLE    = 2'd0;
    localparam CONVERT = 2'd1; // convert base and init result (Mont form)
    localparam LOOP    = 2'd2; // exponent loop
    localparam FINISH  = 2'd3; // convert out and done
    
    
    localparam [WIDTH-1:0] ONE = 1;

    reg [1:0] state, nstate;

    // Registers used during loop (all Montgomery form)
    reg [WIDTH-1:0] base_reg;
    reg [WIDTH-1:0] res_reg;
    reg [WIDTH-1:0] exp_reg;

    // convert base: a * R^2 -> aR (Mont form)
    wire [WIDTH-1:0] conv_base;
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) conv_base_inst (
        .a(base),
        .b(R2MOD[WIDTH-1:0]),
        .result(conv_base)
    );

    // convert 1 -> R mod M (Mont representation of 1)
    wire [WIDTH-1:0] conv_one;
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) conv_one_inst (
        .a(ONE),
        .b(R2MOD[WIDTH-1:0]),
        .result(conv_one)
    );

    // compute product candidate: res * base
    wire [WIDTH-1:0] prod_candidate;
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) prod_inst (
        .a(res_reg),
        .b(base_reg),
        .result(prod_candidate)
    );

    // compute base^2 candidate: base * base
    wire [WIDTH-1:0] base_sq;
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) sq_inst (
        .a(base_reg),
        .b(base_reg),
        .result(base_sq)
    );

    // convert out (Mont -> normal): multiply by 1
    wire [WIDTH-1:0] out_normal;
    mont_redc #(.WIDTH(WIDTH), .MOD(MOD), .NPRIME(NPRIME)) out_inst (
        .a(res_reg),
        .b(ONE),
        .result(out_normal)
    );

    // control FSM and datapath: sequential logic
    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            base_reg <= {WIDTH{1'b0}};
            res_reg  <= {WIDTH{1'b0}};
            exp_reg  <= {WIDTH{1'b0}};
            done     <= 1'b0;
            result   <= {WIDTH{1'b0}};
        end
        else begin
            state <= nstate;
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // load exponent and move to convert
                        exp_reg <= exp;
                    end
                end

                CONVERT: begin
                    // latch conversion results into registers
                    base_reg <= conv_base;
                    res_reg  <= conv_one;
                    // exp_reg already loaded in IDLE on start
                end

                LOOP: begin
                    // If LSB of exponent is 1 -> multiply result by base
                    if (exp_reg[0]) begin
                        res_reg <= prod_candidate;
                    end
                    // square base each iteration
                    base_reg <= base_sq;
                    // shift exponent right
                    exp_reg <= exp_reg >> 1;
                end

                FINISH: begin
                    // convert out: out_normal computed combinationally from res_reg
                    result <= out_normal;
                    done   <= 1'b1;
                end
            endcase
        end
    end

    // next-state logic
    always @(*) begin
        nstate = state;
        case (state)
            IDLE: begin
                if (start)
                    nstate = CONVERT;
            end
            CONVERT: begin
                // one cycle to latch conversions, then start looping
                nstate = LOOP;
            end
            LOOP: begin
                if (exp_reg == 0)
                    nstate = FINISH;
                else
                    nstate = LOOP; // continue looping
            end
            FINISH: begin
                // remain in FINISH until start goes low; then go back to IDLE when start is 0
                if (!start)
                    nstate = IDLE;
            end
        endcase
    end

endmodule
