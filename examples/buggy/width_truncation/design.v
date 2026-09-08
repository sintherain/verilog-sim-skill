`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// width_truncation — BUG: 加法结果只有 4 位宽，进位被静默截断。
// 症状: 15+1 得 sum=0、carry=0（期望 carry=1）；15+15 得 sum=14、carry=0（期望 carry=1）。
//      不报错、无 warning —— 典型的"沉默的功能 bug"，只能靠结果比对发现。
// 根因: `a + b` 表达式位宽 = 操作数位宽（4 位），高位进位直接丢失。
// 修复: 见 design_fixed.v —— 先拓宽到 5 位做加法，再拆出 sum 与 carry。
// ---------------------------------------------------------------------------
module adder4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum,
    output wire       carry
);
    // BUG: 4-bit 的 a+b 截断了进位；比较的也是截断后的 4 位值，恒为 false
    // 陷阱提示: 这里必须写 4'hF 而不是 15 —— 字面量 15 是 32 位常数，
    // 会把 a+b 宽化成 32 位加法、进位得以保留，bug 反而被掩盖。
    wire [3:0] tmp = a + b;
    assign sum   = tmp;
    assign carry = (a + b) > 4'hF;
endmodule