`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// latch_inferred — 自检测试：连续切换 sel，期望 dout 始终等于选中输入。
// BUG 版会在 sel=0 时保持旧值 -> FAIL。
// ---------------------------------------------------------------------------
module tb;
    reg        sel;
    reg  [3:0] x, y;
    wire [3:0] dout;
    integer fail = 0;

    mux_latch u_dut (.sel(sel), .x(x), .y(y), .dout(dout));

    task check;
        input [3:0] exp;
        begin
            #1;
            if (dout !== exp) begin
                $display("FAIL sel=%b x=%h y=%h got=%h exp=%h", sel, x, y, dout, exp);
                fail = fail + 1;
            end else begin
                $display("PASS sel=%b x=%h y=%h -> %h", sel, x, y, dout);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
        x = 12; y = 3;  sel = 1; check(12);   // 选中 x
        x = 12; y = 3;  sel = 0; check(3);    // 选中 y  << BUG 版: 保持 12 -> FAIL
        x = 5;  y = 9;  sel = 1; check(5);    // 再选 x
        x = 5;  y = 9;  sel = 0; check(9);    // 再选 y  << BUG 版: 保持 5  -> FAIL
        if (fail == 0) begin
            $display("TEST PASSED");
            $finish;
        end else begin
            $fatal(1, "TEST FAILED: %0d case(s)", fail);
        end
    end
endmodule