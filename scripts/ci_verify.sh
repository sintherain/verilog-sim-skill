#!/usr/bin/env bash
# Full verification suite for the verilog-sim repository.
# Run it locally, or let .github/workflows/ci.yml call it.
#
# Every example must simulate green; the ALU example also runs the generator,
# the self-checking testbench AND the independent VCD checker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# portable interpreters: prefer python3, fall back to python (Windows)
PY="$(command -v python3 || command -v python)"
IV="$(command -v iverilog || echo iverilog)"
echo "using python: $PY"
echo "using iverilog: $IV"

echo "== [0] python scripts compile =="
$PY -m py_compile scripts/*.py

echo "== [1] alu: generator -> compile -> simulate -> vcd check =="
W="examples/alu/sim_work"
$PY scripts/gen_testbench.py --spec examples/alu/spec.json --workdir "$W" --out tb_gen.v
(
  cd examples/alu
  iverilog -g2012 -s tb_gen -o sim.vvp alu.v sim_work/tb_gen.v
  (cd sim_work && vvp ../sim.vvp | tee sim.log)
  grep -q "TEST PASSED" sim_work/sim.log || { echo "!! alu: TEST PASSED not found"; exit 1; }
  $PY "$ROOT/scripts/vcd_checker.py" sim_work/waveform.vcd \
          --config signals.json --report sim_work/report.md
)

echo "== [2] counter =="
(
  cd examples/counter
  iverilog -g2012 -s tb -o sim.vvp counter.v tb_counter.v
  vvp sim.vvp | tee sim.log
  grep -q "TEST PASSED" sim.log
)

echo "== [3] fsm =="
(
  cd examples/fsm
  iverilog -g2012 -s tb -o sim.vvp fsm.v tb_fsm.v
  vvp sim.vvp | tee sim.log
  grep -q "TEST PASSED" sim.log
)

echo "== [4] seq =="
(
  cd examples/seq
  iverilog -g2012 -s tb -o sim.vvp seq_reg.v tb_seq.v
  vvp sim.vvp | tee sim.log
  grep -q "TEST PASSED" sim.log
)

echo ""
echo "ALL CHECKS PASSED ✅"