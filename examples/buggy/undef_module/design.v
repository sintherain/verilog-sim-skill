`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// undef_module — BUG: 顶层实例化了不存在的模块（模块名拼写错误）。
// 症状: iverilog 编译报 "Unknown module type: sub_modulee"。
// 修复: 见 design_fixed.v —— 把实例化的模块名改成实际定义的名称。
// ---------------------------------------------------------------------------
module top (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] y
);
    // BUG: 下面的模块定义叫 sub_module，这里却实例化了 sub_modulee
    sub_modulee u_sub (.a(a), .b(b), .y(y));
endmodule

module sub_module (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] y
);
    assign y = a + b;
endmodule