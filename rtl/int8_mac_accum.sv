module int8_mac_accum (
    input  logic signed [7:0]  x,
    input  logic signed [7:0]  w,
    input  logic signed [31:0] acc_in,
    output logic signed [31:0] acc_out
);
    logic signed [15:0] product;

    always_comb begin
        product = x * w;
        acc_out = acc_in + {{16{product[15]}}, product};
    end
endmodule


module bitflip32 (
    input  logic signed [31:0] din,
    input  logic        [4:0]  bit_index,
    output logic signed [31:0] dout
);
    always_comb begin
        dout = din ^ (32'h00000001 << bit_index);
    end
endmodule
