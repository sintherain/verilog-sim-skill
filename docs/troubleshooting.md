# Troubleshooting

Real-world pitfalls, ordered by how often they bite. Each entry: symptom →
cause → fix.

## Compile errors

### `Unknown module type: x`
- **Cause:** module name mismatch, wrong file order (instantiated module must be
  compiled before/with the instantiator is fine — iverilog needs all files, but
  the *top* module is selected with `-s`), or a typo in the instance name.
- **Fix:** `iverilog -g2012 -s <top> -o sim.vvp <all files>`, check each
  module name and that every RTL file is on the command line.

### `port ... width X but width Y`
- **Cause:** width mismatch between a port declaration and the connected net.
- **Fix:** pad/truncate deliberately (`{1'b0, a}`) or fix the declaration.

### `ref is a reserved word` / `Syntax error in variable list`
- **Cause:** `ref` is a SystemVerilog keyword (task/function argument type).
- **Fix:** rename the signal (`ref_cnt`, `expected`, ...). We have been bitten
  by this when porting templates — never name a wire `ref` in `-g2012`.

### File paths with spaces / Chinese characters
- **Cause:** iverilog does not re-quote paths for you.
- **Fix:** quote the file list, e.g. `iverilog -g2012 -s tb -o sim.vvp "my dir/x.v" "y.v"`.

## Runtime errors & wrong results

### DUT counts one more than the testbench expects
- **Cause:** the **classic testbench race** — inputs were driven at the same
  time as a clock edge (e.g. releasing reset or setting `en` right at
  `@(posedge clk)`), so the DUT may or may not see the new value on that edge.
- **Fix:** drive inputs **mid-cycle** (after a negedge or with `#1`), and use
  the `cycle()` / `step()` patterns from the templates: exactly one check per
  clock, sample at the negedge *after* the update edge.

### Waveform shows values jumping 2x between checks
- **Cause:** same race, or a free-running clock advanced the DUT between
  checks because the testbench waited for the wrong edge.
- **Fix:** keep one `cycle()` per clock (see `templates/tb_counter.v`).

### `x`/`z` leak into results
- **Cause:** uninitialized registers or unconnected ports; sometimes the
  comparison hides them.
- **Fix:** compare with `!==` (not `!=`) so `x`/`z` are caught, and reset all
  state in the testbench before checking.

### Signed vs unsigned mismatch
- **Cause:** e.g. `4'b1000` is 8 unsigned but `-8` signed; subtraction results
  are two's complement.
- **Fix:** pick one interpretation, make the reference model match, and write
  it into the report.

## VCD checker

### `WARNING: signal not found in VCD: ...`
- **Cause:** the hierarchical name is wrong, e.g. `tb.dut.a` vs `tb_gen.dut.a`,
  or the variable was optimized away.
- **Fix:** run `python3 scripts/vcd_checker.py wave.vcd` with no `--signals`
  to list every VCD signal, then adjust `signals.json`.

### Checker sees the same value for two different names
- **Cause:** VCD allows the same identifier id to be declared in several
  scopes (aliases of the same net). The checker handles this; if you asked for
  two signals that are actually one net you will see identical columns.

### Report prints `timescale: unknown`
- **Cause:** some simulators write `$timescale` and its value on separate
  lines; older versions of the script only read one line.
- **Fix:** update the checker (fixed in this repo) — or just ignore it; only
  affects display, not validation.

## Git / platform (repo publisher notes)

### `fatal: detected dubious ownership in repository ...`
- **Cause:** the repository lives on a filesystem that does not record
  ownership (common for mounted/network volumes on Windows).
- **Fix:** `git config --global --add safe.directory <repo path>` — or the
  machine keeps it as a per-command env override (`GIT_CONFIG_COUNT=1
  GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=<repo path> git ...`).

### GTKWave does not open on Windows
- **Cause:** GTKWave is a GTK app; on MSYS2 it needs the X/win32 windowing
  support of the MSYS2 shell.
- **Fix:** launch it from the MSYS2 terminal (`gtkwave waveform.vcd`) or via
  `scripts/gtkwave_open.sh`; never from a plain `cmd` session.