`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_race_counter - BUG is in the TESTBENCH (the design is fine):
// the reference value is updated AFTER sampling, so every check compares the
// DUT against an expected value that is one clock BEHIND the actual count.
// Symptom: large FAIL count, count is always one more than exp_cnt.
// NOTE: do not name a variable "expect" - it is a SystemVerilog keyword
// (assertion statement) and iverilog -g2012 rejects it (same trap as "ref").
// Fix: see tb_fixed.v (race-free cycle() pattern from templates/tb_counter.v).
// ---------------------------------------------------------------------------
module tb;
  localparam CLK_HALF = 5;
  localparam W        = 4;
  localparam MAX      = (1 << W) - 1;

  reg clk = 0;
  reg rst_n = 0;
  reg en = 0;
  wire [W-1:0] count;
  reg [W-1:0] exp_cnt = 0;
  integer fail = 0;

  always #CLK_HALF clk = ~clk;
  counter #(.WIDTH(W)) u_dut (.clk(clk), .rst_n(rst_n), .en(en), .count(count));

  // BUG: exp_cnt is set too late - the sample compares against the PREVIOUS
  // clock's expectation, so count is always one ahead of exp_cnt.
  task step;
    input [W-1:0] next_exp;
    begin
      @(posedge clk);                   // DUT updates
      @(negedge clk); #1;               // sample
      if (count !== exp_cnt) begin
        $display("FAIL t=%0t count=%h exp=%h", $time, count, exp_cnt);
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t count=%h", $time, count);
      end
      exp_cnt = next_exp;               // BUG POINT: must be set BEFORE the posedge
    end
  endtask

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);
    rst_n = 0;
    repeat (2) @(negedge clk);
    @(negedge clk); rst_n = 1;          // release on a safe edge
    en = 1;

    step(1);                            // count 0->1, but exp_cnt is still 0
    step(2);
    step(3);
    step(4);

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