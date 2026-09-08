# verilog-sim

> An agent-ready skill for simulating, verifying, and debugging Verilog designs —
> powered by Icarus Verilog (iverilog) + GTKWave, with self-checking testbenches,
> large-scale test-vector generation and automatic VCD validation.

`verilog-sim` is a structured instruction bundle ("skill") that a coding agent
(e.g. DeepSeek Harness, Claude Code, Codex, Cline, ...) can load to reliably
simulate Verilog modules, generate waveforms, and verify results case by case.
It ships with ready-made templates, cross-platform tool detection, and helper
scripts, so both humans and agents can run it anywhere.

> 中文简介：本仓库是一个面向开源生态的「Verilog 仿真」agent 技能包，使用
> Icarus Verilog + GTKWave，支持自动补全 testbench、100+ 测试向量生成、
> 结果自动比对（自检式 testbench + VCD 校验），并附带跨平台工具探测与
> 模板库。详见 `docs/` 目录与 `SKILL.md`。

---

## Features

- **Self-checking by default** — testbenches compare results in-harness and
  exit non-zero on failure; no more eyeballing waveforms.
- **Bulk test generation** — a configurable Python generator produces 100+ test
  cases (boundaries, carry/borrow, zero results, negative results, edge values)
  and a checkable testbench.
- **Automatic VCD validation** — `scripts/vcd_checker.py` parses the VCD,
  rebuilds the pass/fail table and reports totals (✅/❌) with exit codes for CI.
- **Cross-platform tool detection** — finds iverilog / vvp / gtkwave on
  Windows (MSYS2, Cygwin), Linux (apt/yum/pacman/dnf), macOS (Homebrew) and WSL.
- **Template library** — combinational / sequential / FSM / counter testbench
  templates that work for any design, not just ALUs.
- **Error-message mapping** — `scripts/errmap.py` matches simulator output
  against a curated error library (root cause + fix + source + reproducible
  example), with a self-test; integrated into `run_sim.sh --errmap`.
- **Bug corpus** — `examples/buggy/` ships four real bug projects (module-name
  typo, silent width truncation, inferred latch, testbench sync race); CI
  asserts the buggy versions fail and the fixed versions pass.
- **Waveform guidance** — GTKWave signal-drag instructions and optional
  batch-mode waveform rendering for docs and reports.

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| Icarus Verilog (`iverilog`, `vvp`) | compile + simulate | MSYS2: `pacman -S mingw-w64-ucrt-x86_64-iverilog` · Debian/Ubuntu: `apt install iverilog` · macOS: `brew install icarus-verilog` |
| GTKWave (`gtkwave`) | waveform viewer | MSYS2: `pacman -S mingw-w64-ucrt-x86_64-gtkwave` · Debian/Ubuntu: `apt install gtkwave` · macOS: `brew install gtkwave` |
| Python 3.8+ | generator + VCD checker | any platform |

Optional: **Verilator** (lint, fast simulation, FST traces) and **cocotb**
(Python-driven testbenches) are supported by the templates and scripts.

## Installation

Copy the whole folder where your agent looks for skills. The layout follows the
common "one folder = one skill" convention:

```text
<skills-dir>/verilog-sim/
├── SKILL.md            # agent instructions (the entry point)
├── scripts/            # helper programs
├── templates/          # reusable testbench templates
├── examples/           # demo projects (clone-and-run)
└── docs/               # installation & troubleshooting
```

- **DeepSeek Harness / DSH**: put it under `.dsh/skills/verilog-sim/` (or the
  skills dir configured in your setup).
- **Claude Skills**: compatible directory shape; `SKILL.md` lives at the root.

## Quick start (human)

```bash
git clone https://github.com/<you>/verilog-sim
cd verilog-sim/examples/alu
# generate a self-checking testbench (108 cases), then build + simulate + validate
python ../../scripts/gen_testbench.py --spec spec.json --workdir sim_work --out tb_gen.v
../../scripts/run_sim.sh -d sim_work alu.v sim_work/tb_gen.v
../../scripts/gtkwave_open.sh sim_work/waveform.vcd        # open the waveform
```

```bash
iverilog -o sim.vvp alu.v tb_alu_auto.v
vvp sim.vvp                          # self-checking: prints PASSED / FAILED
python ../../scripts/vcd_checker.py waveform.vcd \
  --signals A[3:0],B[3:0],Sel[2:0],F[3:0],Cn_4
```

## Usage as an agent skill

When the agent loads `SKILL.md` it gets the full standard workflow:

1. Detect tools (`scripts/env_detect.py`).
2. Read the source files; derive the interface and expected behavior, keeping a
   suspect list of likely bug spots.
3. Write/complete the testbench **from the source** (templates, or the
   generator for 100+ cases).
4. Compile → simulate → read ALL output: errors, `$display` results, warnings,
   exit code, `x`/`z` propagation (use `scripts/vcd_checker.py` for a timeline).
5. Localize the bug, fix the **source files**, re-run the SAME testbench and
   diff the logs until the design passes.
6. Open GTKWave for visual confirmation when needed.
7. Report: errors with line numbers, root cause, the fix, before/after re-run,
   and a case-by-case ✅/❌ table.

## Repository layout

```text
scripts/       env_detect.py · run_sim.sh · gen_testbench.py · vcd_checker.py
               errmap.py · errmap.json · ci_verify.sh · gtkwave_open.sh
templates/     tb_comb.v · tb_seq.v · tb_fsm.v · tb_counter.v
examples/      alu/ (flagship) · counter/ · fsm/ · seq/ · buggy/ (bug corpus)
docs/          installation.md · troubleshooting.md
.github/       ci.yml (lints + simulates all examples)
```

## Extending the skill

- Add a new template: copy `templates/tb_comb.v`, parameterize signals, and add
  it to `docs/` with one usage paragraph.
- Add a new example: mirror `examples/counter/` (RTl + tb + README).
- Contributions are welcome — see `CONTRIBUTING.md`.

## License

[MIT](LICENSE) — do whatever you want, attribution appreciated.