`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// latch_inferred — FIXED: 补全 else 分支，组合行为完整。
// ---------------------------------------------------------------------------
module mux_latch (
    input  wire       sel,
    input  wire [3:0] x,
    input  wire [3:0] y,
    output reg  [3:0] dout
);
    always @(*) begin
        if (sel) dout = x;
        else     dout = y;
    end
endmodule