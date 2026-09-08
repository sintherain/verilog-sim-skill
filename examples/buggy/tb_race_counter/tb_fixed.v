`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_race_counter - FIXED: race-free cycle() pattern (same convention as
// templates/tb_counter.v). exp_cnt is updated mid-cycle AFTER sampling, so
// it always equals the value the DUT will have after the NEXT posedge.
// ---------------------------------------------------------------------------
module tb;
  localparam CLK_HALF = 5;
  localparam W        = 4;

  reg clk = 0;
  reg rst_n = 0;
  reg en = 0;
  wire [W-1:0] count;
  reg [W-1:0] exp_cnt = 0;              // expected value after the NEXT posedge
  integer fail = 0;

  always #CLK_HALF clk = ~clk;
  counter #(.WIDTH(W)) u_dut (.clk(clk), .rst_n(rst_n), .en(en), .count(count));

  task cycle;                           // one full clock: update -> sample -> prep next
    input new_en;
    input [W-1:0] next_exp;
    begin
      @(posedge clk);                   // DUT updates; count becomes exp_cnt
      @(negedge clk); #1;               // sample
      if (count !== exp_cnt) begin
        $display("FAIL t=%0t count=%h exp=%h", $time, count, exp_cnt);
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t count=%h", $time, count);
      end
      en     = new_en;                  // prep next clock (mid-cycle, race-free)
      exp_cnt = next_exp;
    end
  endtask

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);
    rst_n = 0; en = 0;
    repeat (2) @(negedge clk);
    @(negedge clk); rst_n = 1;

    cycle(0, 0);                        // check count=0 after reset (en=0)
    cycle(1, 1);                        // enable; check 0 -> next expect 1
    cycle(1, 2);                        // check 1
    cycle(1, 3);                        // check 2
    cycle(1, 4);                        // check 3

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