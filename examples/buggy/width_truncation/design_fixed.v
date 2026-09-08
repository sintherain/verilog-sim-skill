`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// width_truncation — FIXED: 拓宽临时结果到 5 位再拆位。
// ---------------------------------------------------------------------------
module adder4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum,
    output wire       carry
);
    wire [4:0] tmp = {1'b0, a} + {1'b0, b};   // 5-bit 加法，进位保留在 tmp[4]
    assign sum   = tmp[3:0];
    assign carry = tmp[4];
endmodule