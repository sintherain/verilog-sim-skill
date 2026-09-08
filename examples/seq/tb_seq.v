`timescale 1ns/1ps
// ============================================================================
// tb_seq.v — self-checking testbench template for CLOCKED (sequential) DUTs.
//
// HOW TO USE:
//   1. Replace signal names, reset polarity and the DUT instantiation.
//   2. Race-free, edge-exact conventions (use them in ALL sequential tbs):
//        - `cycle()` covers exactly ONE clock: waits the posedge (DUT samples),
//          samples the outputs at the next negedge, compares, then drives the
//          inputs for the NEXT posedge in the middle of the cycle. Every clock
//          is checked exactly once — no skipped clocks, no edge races.
//        - `exp_q` mirrors the register(s): it must be updated the same way
//          the DUT behaves (clocked-in value, held value when disabled...).
// Compile: iverilog -g2012 -s tb -o sim.vvp <dut.v> tb_seq.v && vvp sim.vvp
// ============================================================================
module tb;
  localparam CLK_HALF = 5;               // 10 ns clock period
  localparam W        = 8;

  reg  clk = 0;
  reg  rst_n = 0;
  reg  en = 0;
  reg  [W-1:0] din;
  wire [W-1:0] dout;
  reg  [W-1:0] exp_q = 0;                // expected current register value
  integer fail = 0;

  always #CLK_HALF clk = ~clk;

  task cycle;                            // one full clock: update -> sample -> prep next
    input [W-1:0] next_din;
    input        next_en;
    begin
      @(posedge clk);                    // DUT samples din/en
      @(negedge clk); #1;                // sample output after settling
      if (dout !== exp_q) begin
        $display("FAIL t=%0t dout=%h exp=%h", $time, dout, exp_q);
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t dout=%h", $time, dout);
      end
      exp_q = next_en ? next_din : exp_q; // mirror the DUT register behaviour
      din = next_din;                    // drive inputs mid-cycle (race-free)
      en  = next_en;
    end
  endtask

  // TODO: replace with the real DUT instantiation
  seq_reg #(.WIDTH(W)) u_dut (.clk(clk), .rst_n(rst_n), .en(en),
                              .din(din), .dout(dout));

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);

    // async reset held for two cycles, released on a safe (negative) edge
    rst_n = 0; en = 0; din = 0;
    repeat (2) @(negedge clk);
    @(negedge clk); rst_n = 1;

    cycle(8'h5A, 1);                     // dout=0 checked; clock in 5A
    cycle(8'hA5, 1);                     // dout=5A checked; clock in A5
    cycle(8'h00, 0);                     // dout=A5 checked; hold
    cycle(8'h00, 0);                     // dout=A5 checked; hold
    cycle(8'hC3, 1);                     // dout=A5 checked; clock in C3

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