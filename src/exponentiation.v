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

    localparam [WIDTH-1:0] ONE = {{(WIDTH-1){1'b0}}, 1'b1};

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
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            base_reg <= {WIDTH{1'b0}};
            res_reg  <= {WIDTH{1'b0}};
            exp_reg  <= {WIDTH{1'b0}};
            done     <= 1'b0;
            result   <= {WIDTH{1'b0}};
        end else begin
            state <= nstate;
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        exp_reg <= exp;
                    end
                end

                CONVERT: begin
                    base_reg <= conv_base;
                    res_reg  <= conv_one;
                end

                LOOP: begin
                    if (exp_reg[0])
                        res_reg <= prod_candidate;

                    base_reg <= base_sq;
                    exp_reg  <= exp_reg >> 1;
                end

                FINISH: begin
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
            IDLE:    if (start) nstate = CONVERT;
            CONVERT: nstate = LOOP;
            LOOP:    if (exp_reg == 0) nstate = FINISH;
            FINISH:  if (!start) nstate = IDLE;
        endcase
    end

endmodule