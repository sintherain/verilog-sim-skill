# Installation

`verilog-sim` has two installation targets: the **tools** it simulates with,
and the **skill itself** (how your agent picks it up).

## 1. Tools

| Platform | Command |
|----------|---------|
| Debian / Ubuntu | `sudo apt install iverilog gtkwave` |
| Fedora / RHEL | `sudo dnf install iverilog gtkwave` |
| Arch / Manjaro | `sudo pacman -S iverilog gtkwave` |
| macOS (Homebrew) | `brew install icarus-verilog` and `brew install --cask gtkwave` |
| MSYS2 (Windows) | `PATH="/usr/bin:$PATH" pacman -S --noconfirm mingw-w64-ucrt-x86_64-iverilog mingw-w64-ucrt-x86_64-gtkwave` |
| Windows (native) | use the MSYS2 route above, or the Win32 iverilog release — GTKWave is easiest via MSYS2 |
| WSL | same as your distro (use the WSL userland: `sudo apt install iverilog gtkwave`) |

Python 3.8+ is required for the helper scripts (stdlib only — no pip installs).

Optional (P1 tooling):
- **Verilator**: `apt install verilator` / `dnf install verilator` / `pacman -S verilator` / `brew install verilator`
- **cocotb**: `pip install cocotb`

Verify your setup at any time:

```bash
python3 scripts/env_detect.py --plain
```

## 2. The skill

Copy (or symlink) this folder into your agent's skills directory:

| Harness | Location |
|---------|----------|
| DeepSeek Harness (DSH) | `<workspace>/.dsh/skills/verilog-sim/` |
| Claude Skills | `<skills-dir>/verilog-sim/` (same folder shape) |
| Cline / Codex / generic | any folder listed in the agent's skill search path |

The entry point is `SKILL.md`; the agent resolves `scripts/`, `templates/`,
`examples/` relative to it. Nothing is global: you can keep separate copies
for different projects.

## 3. Sanity check

```bash
bash scripts/ci_verify.sh        # runs every example; all must print TEST PASSED
```