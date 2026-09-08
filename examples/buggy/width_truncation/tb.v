`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// width_truncation — 自检测试：重点覆盖"溢出"用例。
// ---------------------------------------------------------------------------
module tb;
    reg  [3:0] a, b;
    wire [3:0] sum;
    wire       carry;
    integer fail = 0;

    adder4 u_dut (.a(a), .b(b), .sum(sum), .carry(carry));

    task check;
        input [3:0] esum;
        input       ecarry;
        begin
            #1;
            if (sum !== esum || carry !== ecarry) begin
                $display("FAIL a=%h b=%h sum=%h carry=%b (exp sum=%h carry=%b)",
                         a, b, sum, carry, esum, ecarry);
                fail = fail + 1;
            end else begin
                $display("PASS a=%h b=%h -> sum=%h carry=%b", a, b, sum, carry);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
        a = 5;  b = 3;  check(8, 0);        // 5+3, 无进位
        a = 7;  b = 8;  check(15, 0);       // 7+8 = 15
        a = 15; b = 1;  check(0, 1);        // 15+1 -> sum=0, carry=1  << BUG 版在此失败
        a = 15; b = 15; check(14, 1);       // 15+15 -> sum=14, carry=1 << BUG 版在此失败
        if (fail == 0) begin
            $display("TEST PASSED");
            $finish;
        end else begin
            $fatal(1, "TEST FAILED: %0d case(s)", fail);
        end
    end
endmodule