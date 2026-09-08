`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// seq_reg.v — width-parameterized enabled register with async active-low reset.
// ---------------------------------------------------------------------------
module seq_reg #(parameter WIDTH = 8) (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {WIDTH{1'b0}};
        else if (en)
            dout <= din;
    end
endmodule