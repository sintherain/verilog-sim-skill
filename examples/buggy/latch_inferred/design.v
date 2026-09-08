`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// latch_inferred — BUG: 组合 always 块分支未覆盖完全，推断出意外锁存。
// 症状: sel=0 时 dout 保持上一次的值（锁存行为），而不是组合跟随 y。
//      不做综合也能仿真出"保持旧值"——这是 iverilog 按推断行为仿真的结果。
// 根因: always @(*) 只在 sel=1 时赋值 dout，sel=0 时无赋值 → 电平敏感锁存。
// 修复: 见 design_fixed.v —— 补上 else 分支（或先赋默认值）。
// ---------------------------------------------------------------------------
module mux_latch (
    input  wire       sel,
    input  wire [3:0] x,
    input  wire [3:0] y,
    output reg  [3:0] dout
);
    // BUG: 没有 else 分支；y 端口完全没被使用
    always @(*) begin
        if (sel) dout = x;
    end
endmodule