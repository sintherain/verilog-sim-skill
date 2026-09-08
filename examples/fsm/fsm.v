`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// fsm.v — tiny 3-state machine: IDLE -> RUN -> DONE -> IDLE.
//   IDLE: stays until `start`
//   RUN : stays until `input_ok` (succeeds; otherwise stays in RUN)
//   DONE: pulse `done` for one cycle, then back to IDLE
// ---------------------------------------------------------------------------
module my_fsm (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire input_ok,
    output reg done,
    output reg [1:0] state_out
);
    localparam S_IDLE = 2'd0, S_RUN = 2'd1, S_DONE = 2'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_out <= S_IDLE;
            done      <= 1'b0;
        end else begin
            case (state_out)
                S_IDLE: begin
                    if (start) state_out <= S_RUN;
                end
                S_RUN: begin
                    if (input_ok) state_out <= S_DONE;
                end
                S_DONE: begin
                    state_out <= S_IDLE;
                end
                default: state_out <= S_IDLE;
            endcase
            done <= (state_out == S_DONE);
        end
    end
endmodule