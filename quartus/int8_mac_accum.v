module int8_mac_accum (
    input  signed [7:0]  x,
    input  signed [7:0]  w,
    input  signed [31:0] acc_in,
    output signed [31:0] acc_out
);
    wire signed [15:0] product;
    assign product = x * w;
    assign acc_out = acc_in + {{16{product[15]}}, product};
endmodule
