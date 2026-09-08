---
name: verilog-sim
description: >-
  Verilog module simulation, waveform generation and automated verification.
  Uses Icarus Verilog (iverilog) + GTKWave, supports self-checking testbenches,
  bulk test-vector generation (100+ cases), automatic VCD validation and
  cross-platform tool detection. Suitable for ALUs, counters, FSMs, datapaths
  and any synthesizable/behavioral Verilog design.
---

# verilog-sim — Simulation & Verification Skill

Simulate and verify **any** Verilog module with Icarus Verilog (iverilog),
produce VCD/FST waveforms for GTKWave, and get case-by-case, machine-checked
pass/fail results. The skill is design-agnostic: never assume fixed signal
names (A, B, Sel, F, ...) — **discover** them from the actual code.

> Skill base directory: all `scripts/`, `templates/`, `examples/` paths below
> are relative to the directory containing this SKILL.md. Resolve them against
> that directory before use.

---

## 1. Tool detection (first step, always)

Never hardcode tool paths. Ask the environment or run the detector:

```bash
python3 scripts/env_detect.py            # prints tools as JSON (path + version)
```

The detector checks (in order): PATH → MSYS2/Cygwin (Windows) → Homebrew
(macOS) → common distro install dirs (Linux) → conda. If a tool is missing,
it prints install hints for the detected platform, e.g.:

- Debian/Ubuntu: `sudo apt install iverilog gtkwave`
- Fedora: `sudo dnf install iverilog gtkwave`
- Arch: `sudo pacman -S iverilog gtkwave`
- MSYS2: `PATH="/usr/bin:$PATH" pacman -S --noconfirm mingw-w64-ucrt-x86_64-iverilog mingw-w64-ucrt-x86_64-gtkwave`
- macOS: `brew install icarus-verilog gtkwave`

If the detector cannot run (no Python), fall back to `command -v iverilog`
(Unix) / `where iverilog` (Windows) plus the same lookup order.

**Working directory**: use a scratch dir under the user's project (e.g.
`<project>/sim_work/`) or the OS temp dir — never a machine-specific absolute
path baked into the skill.

---

## 2. Analyze the design

Read every provided `.v` file (sources + testbench) before touching anything:

- module names, port lists, parameterization (`parameter`, `#(...)`),
- instantiation hierarchy (top → submodules) for dump depth,
- clock/reset/active-edge conventions (never guess: check `always @(posedge ...)`),
- bit widths and signedness of the signals you plan to check,
- existing `$dumpfile`/`$dumpvars`/`$monitor` in the testbench.

Discover the **interface contract** of the DUT so the testbench can drive it:
- inputs to drive, outputs to observe,
- combinational vs sequential (does the result settle after `#delay` or after a
  clock edge?),
- active-low resets / inverted control signals — read the code, do not assume.

---

## 3. Build the testbench with self-checking (default)

A testbench must verify itself and exit non-zero on failure. Template:
`templates/tb_comb.v` (combinational), `templates/tb_seq.v` (clocked),
`templates/tb_fsm.v` (FSM), `templates/tb_counter.v` (counters).

Core pattern (adapt signal names to the DUT):

```verilog
module tb;
  reg  [W-1:0] a, b;
  reg  [S-1:0] sel;
  wire [W-1:0] f;
  integer fail = 0;

  task check; // one test case
    input [W-1:0] exp;
    begin
      #1;                                   // let combinational logic settle
      if (f !== exp) begin
        $display("FAIL #%0d: a=%h b=%h sel=%h got=%h exp=%h",
                 $time, a, b, sel, f, exp);
        fail = fail + 1;
      end else begin
        $display("PASS #%0d: a=%h b=%h sel=%h -> %h", $time, a, b, sel, f);
      end
    end
  endtask

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);
    // stimulus + checks ...
    if (fail == 0) $display("TEST PASSED");
    else           $fatal(1, "TEST FAILED: %0d case(s)", fail);
  end
endmodule
```

Notes:

- Compare with `!==`/`!==` (case inequality) so `x`/`z` are caught, not hidden.
- On sequential DUTs, apply stimulus, then wait for the relevant clock edge or
  `@(negedge clk)` before `check`.
- Use `$fatal` with non-zero code (or `$stop`) so `vvp` returns an error exit
  code — this is what makes CI and the scripts trustworthy.
- Keep one `FAIL` line per case: the VCD checker and users need stable tags.

Defaults inside this skill:

- `$dumpfile("waveform.vcd")` (+ FST when using Verilator trace),
- `$dumpvars(0, <tb_top>)` records the whole hierarchy; for deep hierarchies
  use `$dumpvars(0, dut)` to trim the file size.

---

## 4. Bulk test vectors (100+ cases)

When the user asks for many cases (e.g. "每种运算不低于 N 条", "100+ cases"),
use `scripts/gen_testbench.py` instead of hand-writing stimulus:

```bash
python3 scripts/gen_testbench.py \
  --template templates/tb_comb.v \
  --out tb_auto.v \
  --width 4 --ops 6 --cases-per-op 18 \
  --dut signals.json
```

What the generator guarantees (configurable):

- boundary values (0, 1, max-1, max),
- carry/borrow scenarios (max+max, 0-min, ...),
- zero-result cases (x^x, x&0, x-x, ...),
- negative results (subtraction A < B),
- arbitrary Python reference model per op (delta between HDL result and
  reference is reported case by case).

If the generator's assumptions do not fit the DUT, write the stimulus manually
but keep the same `check`/`fail` pattern above.

---

## 5. Compile

```bash
iverilog -g2012 -s tb -o sim.vvp <sources...> <tb.v>
```

Or, when the testbench is self-checking and paths are messy:

```bash
bash scripts/run_sim.sh <dut1.v> <dut2.v> <tb.v>
# == env_detect + compile + run + (optional) vcd checker ==
```

Quote every path that may contain spaces or non-ASCII characters.

**Common compile errors and fixes**

| Symptom | Cause / fix |
|---------|-------------|
| `Unknown module type: x` | missing/changed module name, wrong source order, missing `-I` include dir |
| `port ... connected to ... has width X but ... width Y` | width mismatch: pad/truncate or fix the declaration |
| `v ... is not a constant` | used a variable where a parameter/constant was expected |
| `can't open input file` | path broken by spaces/unquoted quoting; re-quote |
| `reference to x is not a constant` / `Expected constant` | parameter arithmetic issue, check `localparam` |
| multidim/`reg [3:0] [3:0]` loops | use `$readmemh` or `genvar` correctly; template available |

---

## 6. Run

```bash
vvp sim.vvp
```

Success criteria: `TEST PASSED` (or zero FAIL lines), `$finish`/`$fatal`
triggered, exit code 0 on pass / non-zero on fail. If the run hangs, check the
`#` delays in the testbench and the reset sequence (clocked designs need a
proper release of reset before checks).

---

## 7. Validate results (two layers)

**Layer 1 — in-harness:** the testbench already printed PASS/FAIL lines and set
the exit code. Summarize: total cases, passed, failed; list the FAIL lines.

**Layer 2 — independent VCD check** (trust nothing, especially when the
testbench was user-supplied):

```bash
python3 scripts/vcd_checker.py waveform.vcd --config signals.json
```

`signals.json` maps checker names → hierarchical VCD identifiers, e.g.:

```json
{
  "signals": {"A": "tb.dut.u_alu.A", "B": "tb.dut.u_alu.B",
              "Sel": "tb.dut.u_alu.Sel", "F": "tb.dut.u_alu.F",
              "Cn_4": "tb.dut.u_alu.Cn_4"},
  "expected": "expected.csv",      // optional: time,<sig>=<value> rows
  "report": "report.md"            // optional output table
}
```

The checker asserts each value-change and prints a case table; it exits
non-zero when anything mismatches. Use this when the testbench has no
self-check, or when the user asks for "逐条验证".

Report format for the user:

| # | A | B | Sel | F | Cn_4 | 期望结果 | 比对 |
|---|----|----|-----|----|------|----------|------|
| 1 | 15 | 15 | 000 | 14 | 1 | 15+15=30 → F=14, C=1 | ✅ |

---

## 8. Waveforms (GTKWave)

Open the VCD/FST:

```bash
bash scripts/gtkwave_open.sh waveform.vcd        # cross-platform launcher
# Windows fallback: start "" "<gtkwave>" waveform.vcd
```

Instruct the user:
1. **SST** (left panel): expand the module tree to the DUT instance.
2. Drag signals into the **Signals** pane.
3. Click **Zoom Fit** to see the whole run; use `Zoom to Cursor` for details.

Optional batch render to PNG (docs/READMEs, no GUI):

```bash
gtkwave waveform.vcd -S scripts/wave_to_png.tcl -o wave.png
```

---

## 9. Verification-first debugging loop

If the simulation fails:

1. Reproduce from the first FAIL line; zoom the waveform at that timestamp.
2. Classify: logic error vs. testbench error vs. interpretation error
   (signed vs unsigned! e.g. 4-bit `1000` = 8 unsigned or -8 signed).
3. Fix the **design** when the DUT is wrong, fix the **testbench** when the
   stimulus/expectation is wrong. Never silently change an expectation to make
   the test pass — document the decision to the user.
4. Re-run until green; keep the failing test case in the regression set.

---

## 10. Reply style

- Reply in the **user's language** (follow the user's prompt).
- Present results as tables; mark each case ✅/❌; end with a pass/fail summary.
- Report exact file paths and exact commands you ran.
- On errors: first locate the line + root cause, then propose the fix — and
  explain the root cause in one sentence before the fix.
- When the user asks about waveform contents, give explicit drag instructions
  plus the signal names/paths you dumped.