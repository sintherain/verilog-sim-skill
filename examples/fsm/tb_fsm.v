`timescale 1ns/1ps
// ============================================================================
// tb_fsm.v — self-checking testbench template for FINITE STATE MACHINES.
//
// HOW TO USE:
//   1. Replace states, I/O signals and the DUT instantiation.
//   2. Race-free, edge-exact conventions (use them in ALL sequential tbs):
//        - `step()` covers exactly ONE clock: waits the posedge (FSM
//          transitions), samples the state at the next negedge, compares with
//          `exp_state`, then drives the inputs for the NEXT posedge mid-cycle.
//        - the expected states below must mirror the FSM's transition table.
// Compile: iverilog -g2012 -s tb -o sim.vvp <fsm.v> tb_fsm.v && vvp sim.vvp
// ============================================================================
module tb;
  localparam CLK_HALF = 5;

  reg clk = 0;
  reg rst_n = 0;
  reg start = 0;
  reg input_ok = 0;
  wire done;
  wire [1:0] state_out;
  integer fail = 0;

  always #CLK_HALF clk = ~clk;

  // TODO: mirror the FSM spec
  localparam S_IDLE = 2'd0, S_RUN = 2'd1, S_DONE = 2'd2;

  task step;                            // one full clock: transition -> sample -> prep next
    input [1:0]  exp_state;             // state expected AT THIS SAMPLE POINT
    input        next_start;
    input        next_ok;
    begin
      @(posedge clk);                   // FSM transitions
      @(negedge clk); #1;               // settle + sample
      if (state_out !== exp_state) begin
        $display("FAIL t=%0t state=%b exp=%b", $time, state_out, exp_state);
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t state=%b", $time, state_out);
      end
      start    = next_start;            // drive inputs mid-cycle (race-free)
      input_ok = next_ok;
    end
  endtask

  // TODO: replace with the real FSM instantiation
  my_fsm u_dut (.clk(clk), .rst_n(rst_n), .start(start),
                .input_ok(input_ok), .done(done), .state_out(state_out));

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);

    // async reset held for two cycles, released on a safe (negative) edge
    repeat (2) @(negedge clk);
    @(negedge clk); rst_n = 1;

    step(S_IDLE, 0, 0);                 // stays IDLE
    step(S_IDLE, 0, 0);                 // stays IDLE
    step(S_IDLE, 1, 0);                 // stays IDLE, start asserted for next
    step(S_RUN,  1, 0);                 // IDLE -> RUN
    step(S_RUN,  0, 1);                 // stays RUN, input_ok for next
    step(S_DONE, 0, 0);                 // RUN -> DONE (pulse done)
    step(S_IDLE, 0, 0);                 // DONE -> IDLE

    if (fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED: %0d case(s)", fail);
    end
  end

  initial begin
    #20000 $display("TIMEOUT"); $fatal(1, "simulation timeout");
  end
endmodule