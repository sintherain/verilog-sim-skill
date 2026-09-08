`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// alu.v — 4-bit ALU, 6 operations, carry/borrow flag.
//
// Flagship example of the verilog-sim skill.
// Operations selected by `sel` (3 bits):
//   0: add   1: sub (borrow flag)   2: and
//   3: or    4: xor                 5: nand
// ---------------------------------------------------------------------------
module alu #(parameter WIDTH = 4) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0]       sel,
    output reg  [WIDTH-1:0] f,
    output reg              cn_4
);
    localparam [WIDTH-1:0] MASK = {WIDTH{1'b1}};
    wire [WIDTH:0] wide_sum = {1'b0, a} + {1'b0, b};   // wide sum keeps carry

    always @(*) begin
        cn_4 = 1'b0;
        case (sel)
            3'd0: begin
                f    = wide_sum[WIDTH-1:0];
                cn_4 = wide_sum[WIDTH];               // carry out
            end
            3'd1: begin
                f    = a - b;
                cn_4 = (a < b);                       // borrow
            end
            3'd2: f = a & b;
            3'd3: f = a | b;
            3'd4: f = a ^ b;
            3'd5: f = ~(a & b);
            default: f = {WIDTH{1'b0}};
        endcase
    end
endmodule