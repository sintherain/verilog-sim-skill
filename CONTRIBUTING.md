# Contributing

Thanks for improving `verilog-sim`! Three things matter most:

1. **Everything you add must actually run.** No template or example ships
   without a green `scripts/ci_verify.sh` run on your machine.
2. **Design-agnostic.** No hardcoded signal names (A/B/Sel/F...), no
   machine-specific paths, no absolute paths in scripts or docs.
3. **Keep SKILL.md the single source of truth** for the agent workflow;
   scripts are helpers, not replacements.

## Workflow

```bash
git clone <your-fork> && cd verilog-sim
# ...edit...
bash scripts/ci_verify.sh        # all examples must print TEST PASSED
git add -A && git commit -m "..." && git push
```

## What makes a good change

- **New template** (`templates/tb_*.v`): copy an existing one, parameterize the
  signals, add a `HOW TO USE` comment, and add a `examples/<name>/` demo that
  the CI runs. Follow the race-free conventions in the templates.
- **New example** (`examples/<name>/`): `README.md` + RTL + testbench.
- **Script fix** (`scripts/`): stdlib-only Python 3.8+, cross-platform, add a
  regression check to `ci_verify.sh` when a bug is fixed (we have hit: VCD id
  aliasing, `ref` keyword, edge races, `$timescale` spanning lines).

## Conventions

- Shell scripts: POSIX `bash`, `set -euo pipefail`, no Windows-only calls
  (platform branches allowed).
- Python: standard library only; argparse-free CLI (tiny scripts); English
  docstrings; `python3 scripts/<name>.py --help` must work.
- Verilog templates: `` `timescale 1ns/1ps ``, self-checking with `$fatal`
  non-zero on failure, watchdogs for sequential designs.
- Commit messages: conventional-ish (`feat:`, `fix:`, `docs:`, `test:`).

## License

By contributing you agree that your work is licensed under the MIT License
(`LICENSE`).