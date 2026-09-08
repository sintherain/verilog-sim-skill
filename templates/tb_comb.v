`timescale 1ns/1ps
// ============================================================================
// tb_comb.v — self-checking testbench template for COMBINATIONAL DUTs.
//
// HOW TO USE:
//   1. Replace W, the port list of `dut` and the stimulus list.
//   2. Keep `ref` (reference model) in sync with the DUT spec.
//   3. For 100+ cases use scripts/gen_testbench.py instead of hand-writing.
// Compile: iverilog -g2012 -s tb -o sim.vvp <dut.v> tb_comb.v && vvp sim.vvp
// ============================================================================
module tb;
  localparam W = 4;                       // TODO: operand width of the DUT

  reg  [W-1:0] a, b;                      // TODO: inputs of the DUT
  reg  [2:0]   sel;                       // TODO: control/opcode input
  wire [W-1:0] f;                         // TODO: outputs of the DUT

  integer fail = 0;

  // ---- reference model (must match the DUT spec) ----
  function [W-1:0] ref;
    input [W-1:0] x, y;
    input [2:0]   op;
    begin
      case (op)
        0:       ref = (x + y);
        1:       ref = (x - y);
        2:       ref = (x & y);
        3:       ref = (x | y);
        4:       ref = (x ^ y);
        default: ref = 0;
      endcase
    end
  endfunction

  // ---- one test case ----
  task apply;
    input [W-1:0] x, y;
    input [2:0]   op;
    begin
      a = x; b = y; sel = op;
      #1;                                  // combinational settle delay
      if (f !== ref(a, b, sel)) begin
        $display("FAIL t=%0t a=%h b=%h sel=%h got=%h exp=%h",
                 $time, a, b, sel, f, ref(a, b, sel));
        fail = fail + 1;
      end else begin
        $display("PASS t=%0t a=%h b=%h sel=%h -> %h", $time, a, b, sel, f);
      end
    end
  endtask

  // TODO: replace with the real DUT instantiation
  dut #(.WIDTH(W)) u_dut (.a(a), .b(b), .sel(sel), .f(f));

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);

    // boundary / carry / zero / negative cases (extend freely):
    apply(0, 0, 0);           // 0+0
    apply(15, 15, 0);         // carry
    apply(0, 15, 1);          // 0-15 -> borrow / two's complement
    apply(5, 5, 4);           // 5^5 = 0
    apply(5, 10, 2);          // 5&10
    apply(3, 6, 3);           // 3|6
    apply(15, 1, 0);          // 16 -> W truncation
    apply(1, 0, 1);           // 1-0

    if (fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED: %0d case(s)", fail);
    end
  end
endmodule