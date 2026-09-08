`timescale 1ns/1ps
// ============================================================================
// tb_counter.v — self-checking testbench template for COUNTERS.
//
// HOW TO USE:
//   1. Replace WIDTH, reset/enable polarity and the DUT instantiation.
//   2. Race-free, edge-exact conventions (use them in ALL sequential tbs):
//        - `cycle()` covers exactly ONE clock cycle: it waits the posedge
//          (DUT updates), samples at the next negedge, compares, and then
//          drives the inputs for the NEXT posedge in the middle of the cycle.
//          Every posedge is therefore checked exactly once — no skipped
//          clocks, no races at the clock edge.
//        - `ref_cnt` is the value the DUT should have after the next posedge
//          (i.e. what it sampled at the posedge we are about to verify).
//   3. Extend the stimulus chain freely; keep one `cycle` call per simulated clock.
// Compile: iverilog -g2012 -s tb -o sim.vvp <counter.v> tb_counter.v && vvp sim.vvp
// ============================================================================
module tb;
  localparam CLK_HALF = 5;
  localparam W        = 4;
  localparam MAX      = (1 << W) - 1;

  reg clk = 0;
  reg rst_n = 0;
  reg en = 0;
  wire [W-1:0] count;
  reg [W-1:0] ref_cnt = 0;             // expected value after the NEXT posedge
  integer fail = 0;

  always #CLK_HALF clk = ~clk;

  task cycle;                          // one full clock: update -> sample -> prep next
    input        new_en;
    input [W-1:0] ref_next;
    begin
      @(posedge clk);                  // DUT updates
      @(negedge clk); #1;              // sample after settling
      if (count !== ref_cnt) begin
        $display("FAIL t=%0t count=%h ref=%h", $time, count, ref_cnt);
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t count=%h", $time, count);
      end
      en = new_en;                     // drive inputs mid-cycle (race-free)
      ref_cnt = ref_next;              // expected after the NEXT posedge
    end
  endtask

  // TODO: replace with the real counter instantiation
  counter #(.WIDTH(W)) u_dut (.clk(clk), .rst_n(rst_n), .en(en), .count(count));

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);

    // hold async reset for two cycles, release on a safe (negative) edge
    rst_n = 0; en = 0; ref_cnt = 0;
    repeat (2) @(negedge clk);
    @(negedge clk); rst_n = 1;

    cycle(1, 1);                       // count was 0; enable -> expect 1
    cycle(1, 2);                       // 1 -> expect 2
    cycle(0, 2);                       // disable: hold at 2
    cycle(1, 3);                       // resume -> expect 3
    cycle(1, 4);                       // 3 -> expect 4

    // drive to the top of the range; `cycle` keeps ref_cnt one step ahead
    while (ref_cnt !== MAX)
      cycle(1, ref_cnt + 1'b1);
    cycle(1, 0);                       // MAX -> 0 (wrap)

    // async reset mid-operation
    @(negedge clk); rst_n = 0;
    cycle(0, 0);                       // reset forces 0
    @(negedge clk); rst_n = 1;         // release
    cycle(0, 0);                       // still 0 after release

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