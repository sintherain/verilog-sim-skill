`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// undef_module — FIXED: 实例化名与模块定义名一致。
// ---------------------------------------------------------------------------
module top (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] y
);
    sub_module u_sub (.a(a), .b(b), .y(y));
endmodule

module sub_module (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] y
);
    assign y = a + b;
endmodule