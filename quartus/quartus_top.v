module quartus_top (
    input                   clk,
    input                   rst_n,
    input  signed [7:0]     x_in,
    input  signed [7:0]     w_in,
    input  signed [31:0]    acc_in,
    output reg signed [31:0] acc_out
);

    reg signed [7:0]  x_r;
    reg signed [7:0]  w_r;
    reg signed [31:0] acc_r;
    wire signed [31:0] mac_result;

    int8_mac_accum u_mac (
        .x       (x_r),
        .w       (w_r),
        .acc_in  (acc_r),
        .acc_out (mac_result)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_r     <= 8'sd0;
            w_r     <= 8'sd0;
            acc_r   <= 32'sd0;
            acc_out <= 32'sd0;
        end else begin
            x_r     <= x_in;
            w_r     <= w_in;
            acc_r   <= acc_in;
            acc_out <= mac_result;
        end
    end

endmodule
