`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// undef_module — 正确的 testbench（bug 在 design 里，不在 tb 里）。
// 编译失败时本 tb 不会运行；修复后可自检并打印 TEST PASSED。
// ---------------------------------------------------------------------------
module tb;
    reg  [3:0] a, b;
    wire [3:0] y;
    integer fail = 0;

    top u_top (.a(a), .b(b), .y(y));

    task check;
        input [3:0] exp;
        begin
            #1;
            if (y !== exp) begin
                $display("FAIL a=%h b=%h got=%h exp=%h", a, b, y, exp);
                fail = fail + 1;
            end else begin
                $display("PASS a=%h b=%h -> %h", a, b, y);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
        a = 5;  b = 3;  check(8);      // 5+3
        a = 15; b = 1;  check(0);      // 4-bit 截断: 16 -> 0
        if (fail == 0) begin
            $display("TEST PASSED");
            $finish;
        end else begin
            $fatal(1, "TEST FAILED: %0d case(s)", fail);
        end
    end
endmodule