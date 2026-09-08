---
name: verilog-sim
description: >-
  Verilog project simulation & debug loop. Analysis-driven testbench authoring,
  Icarus Verilog (iverilog) compilation and simulation, reading simulation
  output and error messages, localizing bugs in the RTL source, fixing the
  source files and re-running until the design passes. Works for ALUs,
  counters, FSMs, datapaths and any synthesizable/behavioral Verilog design.
---

# verilog-sim — Simulation & Debug Skill

The user hands you **Verilog source files** (possibly with bugs) and wants them
simulated and made to work. The core loop of this skill is:

```
read source files
    → derive the interface + expected behavior
    → write / complete a testbench for it
    → compile & simulate (iverilog/vvp)
    → read the simulation output + error messages (and waveform if needed)
    → localize the bug, modify the SOURCE files
    → re-run the SAME testbench
    → repeat until the design passes
```

The deliverable is a **fixed source + evidence** (passing simulation, clean
output, a case-by-case report). Waveforms and verification tables are tools
serving that loop, not the goal itself.

> Skill base directory: all `scripts/`, `templates/`, `examples/` paths below
> are relative to the directory containing this SKILL.md. Resolve them against
> that directory before use. Never assume fixed signal names (A, B, Sel, F,
> ...) — discover the interface from the actual code.

---

## 1. Tool detection (always first)

Never hardcode tool paths — detect them:

```bash
python3 scripts/env_detect.py            # prints tools as JSON (path + version)
```

It checks PATH → MSYS2/Cygwin (Windows) → Homebrew (macOS) → distro dirs
(Linux) → conda, and prints install hints for the detected platform
(`apt install iverilog`, `pacman -S ...iverilog`, `brew install icarus-verilog`,
...). If Python is unavailable, fall back to `command -v iverilog`.

**Working directory**: a scratch dir under the user's project (e.g.
`<project>/sim_work/`) or the OS temp dir — never a machine-specific absolute
path.

---

## 2. Read and understand the source files

Read ALL provided `.v` files completely before writing anything. For each
module determine:

- **Interface**: module name, port list, widths, parameterization, signedness.
- **Behavior**: combinational or sequential; clock/reset edges & polarity;
  what each module is supposed to compute / sequence.
- **Hierarchy**: top module, instantiation names (needed for dump depth and
  waveform paths).
- **Existing testbench**: what it covers, whether it dumps a waveform, whether
  it self-checks.

While reading, keep a short **suspect list** — the places most likely to hide a
bug (see §6 for the taxonomy): width/sign mismatches, wrong port connections,
uninitialized state, missing reset, off-by-one in counters, bit-ordering in
concatenations, truncating arithmetic, always blocks without `*` or missing
sensitivity edges, `x`/`z` leaking from uninitialized signals.

Example suspect checks to do by inspection:

| Check | Why it matters |
|-------|----------------|
| `a + b` where result feeds a narrower reg | truncation loses carry |
| `always @(a or b)` on a multi-bit expression | incomplete sensitivity list |
| reg used before assignment | undefined `x` at t=0 |
| counter/FSM without reset | starts in unknown state |
| busy-loop/`while` without `#delay` | simulation hangs |
| port widths differ from declarations | silent truncation/zero-extension |

---

## 3. Write / complete the testbench (derived from the source)

The testbench is **derived from the source**, not from the templates blindly:

1. **Drive signals**: each input of the DUT — what sequence exercises its
   contract (reset, enable, opcode, data...). Read the RTL to learn reset
   polarity and active edges — never guess.
2. **Expected results**: compute them independently — a reference model
   (Verilog `function`/`task` mirroring the spec), a truth table, or an
   assertion. This is what turns "仿真结果" into "通过/失败".
3. **Choose a template** from `templates/` matching the design shape:
   - `tb_comb.v` — combinational DUTs,
   - `tb_seq.v` / `tb_counter.v` — clocked designs and counters,
   - `tb_fsm.v` — state machines.
   Adapt the signal names to the actual ports (TODO markers show where).
4. **Always self-check** and exit non-zero on failure:

```verilog
task check;                      // combinational: settle then compare
  input [W-1:0] exp;
  begin
    #1;
    if (f !== exp) begin
      $display("FAIL #%0t: a=%h b=%h sel=%h got=%h exp=%h", $time, a, b, sel, f, exp);
      fail = fail + 1;
    end else begin
      $display("PASS #%0t: a=%h b=%h sel=%h -> %h", $time, a, b, sel, f);
    end
  end
endtask
// ...
if (fail == 0) $display("TEST PASSED");
else           $fatal(1, "TEST FAILED: %0d case(s)", fail);
```

   Use `!==` (case inequality) so `x`/`z` are caught, not hidden. Sequential
   designs: drive inputs **mid-cycle** (not at the clock edge) and sample after
   the update edge — the `cycle()`/`step()` patterns in the templates are the
   race-free way.

5. **Waveform output** (needed for debugging): if absent, insert at the front
   of the `initial` block:

```verilog
initial begin
  $dumpfile("waveform.vcd");
  $dumpvars(0, tb);              // whole hierarchy; use $dumpvars(0, dut) to trim
end
```

6. **Bulk cases** (100+ vectors, every op ≥ N cases): use
   `scripts/gen_testbench.py` with a `spec.json` (inputs/outputs widths + ops +
   reference expressions) instead of hand-writing:

```bash
python3 scripts/gen_testbench.py --spec spec.json --workdir sim_work --out tb_gen.v
```

   Coverage patterns it guarantees: boundaries (0, 1, max-1, max), carry/borrow
   (max+max, 0-min), zero results, negative results (A<B).

---

## 4. Compile

```bash
iverilog -g2012 -s <top_module> -o sim.vvp <sources...> <tb.v>
```

Or one command with detection, build, run and optional VCD check:

```bash
bash scripts/run_sim.sh -d sim_work <dut1.v> <dut2.v> <tb.v> --check
```

Quote every path that may contain spaces or non-ASCII characters.

**Common compile errors and fixes**

| Symptom | Cause / fix |
|---------|-------------|
| `Unknown module type: x` | missing/changed module name, wrong source order, missing `-I` include dir |
| `port ... width X but width Y` | width mismatch: pad/truncate or fix the declaration |
| `v ... is not a constant` | variable used where a constant was expected |
| `reference to x is not a constant` | parameter arithmetic issue, use `localparam` |
| `Syntax error in variable list` | an identifier shadows a keyword (`ref`, `step`, `wait`...) |
| `can't open input file` | path broken by spaces/quotes; re-quote |

On compile errors: report the **exact line number and the root cause**, then
fix the **source file** and re-compile before touching the testbench.

> Full message-to-fix mapping (4-stage taxonomy, ~40 entries with sources):
> docs/troubleshooting.md (syntax → semantics → warnings → runtime) and its
> source list in docs/references.md.

---

## 5. Simulate and READ the results (gather all diagnostics)

```bash
vvp sim.vvp
```

Capture and classify EVERYTHING:

| Message / state | Meaning | Look at |
|-----------------|---------|---------|
| compile/runtime error | syntax or elaboration problem | line number, fix source |
| `x` values in `$display` output | uninitialized signal / unconnected port | find first `x` in time, trace back |
| `$fatal` / `TEST FAILED` | self-check caught a mismatch | the FAIL lines, then the waveform at that time |
| never `$finish` / process hangs | missing terminator, busy loop, no `#delay` | add watchdog/timeouts |
| warnings (`Width mismatch`, truncation...) | latent bugs | each warning = candidate fix |
| exit code ≠ 0 | something failed | use it for CI/regression |

Save the full stdout (`vvp sim.vvp | tee sim.log`) — you will diff it against
the re-run after a fix.

When the messages are not enough, open the VCD and interrogate it:

```bash
python3 scripts/vcd_checker.py waveform.vcd \
  --signals "A=tb.dut.a,B=tb.dut.b,F=tb.dut.f" --sample 30
```

to get a compact timeline, or point GTKWave at it (see §8). Look for: the **first
time** a signal becomes `x`/`z` and what it depended on; a value that changed
one cycle later than expected; a control signal that never asserted.

---

## 6. Localize the bug and modify the SOURCE files (the core loop)

Map the observation to a class, then a location, then a minimal fix:

| Error class | Typical symptom | Root cause | Fix location |
|-------------|-----------------|------------|--------------|
| Syntax | compile error at line N | typo, missing `;`, wrong keyword | that line/block |
| Declaration/width | truncation warnings, carry lost | reg/wire width too narrow, signed mismatch | the declaration, plus a wider temp for arithmetic |
| Ports/instantiation | values stuck at 0/`x`, wrong bits | port not connected, order swapped, wrong name | the port map of the instance |
| Combinational logic | wrong truth table on select cases | wrong op, wrong bit order, incomplete sensitivity | the always/case/assign block |
| Sequential logic | counter off by one, output lags | race at clock edge, missing reset, wrong edge | the clocked block + reset logic |
| Data interpretation | "result wrong" but actually fine | signed vs unsigned, truncated subtraction | report, or fix if the spec demands |

**Rules for modifying:**

1. Fix the **source**, not the testbench — unless the testbench itself is
   provably wrong (never silently change an expectation to make a test pass;
   say so explicitly).
2. Change the **smallest** part that removes the root cause; one fix per
   iteration, so the effect is observable.
3. After each fix: **re-run the same testbench**, compare `sim.log` against the
   previous run (previous errors gone, no new warnings, PASS count up / FAIL
   count down).
4. Keep the failing case in the regression set.

Example of a documented fix report:

```
ERROR: tb.dut count stops at 13 instead of 15 (counter.v:18)
ROOT CAUSE: `count <= count + 1'b1` — rst_n released at the same edge as en
  was driven (testbench race at counter.v:44), so the DUT saw one extra clock.
FIX: drive `en` mid-cycle (after @(negedge clk)); no source change needed.
RE-RUN: same tb -> TEST PASSED (was: 7 FAIL).
```

---

## 7. Re-run until green — report

Iterate until the design passes (or report precisely what remains). Then
present the result as a **debug report**:

1. What the source files contained and what was wrong (each issue: file, line,
   symptom).
2. What you changed (or that the problem was in the testbench) and why.
3. Simulation evidence: `TEST PASSED`, total/all cases in a table:
   | # | A | B | Sel | F | Cn_4 | 期望 | 比对 |
   |---|----|----|-----|----|------|------|
   | 1 | 15 | 15 | 000 | 14 | 1 | 15+15=30 → F=14, C=1 | ✅ |
4. Any remaining limitations or warnings.

---

## 8. Waveforms (GTKWave)

When a fix needs visual confirmation or the user asks:

```bash
bash scripts/gtkwave_open.sh waveform.vcd     # cross-platform launcher
```

Instruct the user: ① SST panel — expand the tree to the DUT instance;
② drag signals into the Signals pane; ③ Zoom Fit. For reports, a batch render:

```bash
gtkwave waveform.vcd -S scripts/wave_to_png.tcl -o wave.png   # best-effort
```

---

## 9. Reply style

- Reply in the **user's language** (follow the user's prompt).
- Errors first: exact line number, the message, and the root cause in one
  sentence — then the fix.
- Show before/after: what changed in the source (file + line), and the re-run
  output proving it.
- Results in tables with ✅/❌ and a pass/fail summary.
- When the user asks about waveform contents, give explicit signal paths and
  drag instructions.