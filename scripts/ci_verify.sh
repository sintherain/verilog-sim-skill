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

echo "== [0] python scripts compile + errmap selftest =="
$PY -m py_compile scripts/*.py
$PY scripts/errmap.py --selftest

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

echo "== [5] buggy regression (bug versions must fail, fixed must pass) =="
B="examples/buggy"

# undef_module: compile MUST fail with the expected message
(
  cd "$B/undef_module"
  if iverilog -g2012 -s tb -o sim.vvp design.v tb.v 2> compile.log; then
    echo "!! undef_module: expected compile failure, got success"; exit 1
  fi
  grep -qi "Unknown module type" compile.log || { echo "!! undef_module: expected message not found"; exit 1; }
  iverilog -g2012 -s tb -o sim_fixed.vvp design_fixed.v tb.v
  vvp sim_fixed.vvp | tee sim_fixed.log
  grep -q "TEST PASSED" sim_fixed.log
)

# width_truncation / latch_inferred / tb_race_counter:
# bug version must NOT print TEST PASSED; fixed version must print it.
for case in "width_truncation:design.v:design_fixed.v" \
            "latch_inferred:design.v:design_fixed.v" \
            "tb_race_counter:counter.v+tb.v:counter.v+tb_fixed.v"; do
  dir="${case%%:*}"; rest="${case#*:}"
  bug_files="${rest%%:*}"; fixed_files="${rest#*:}"
  (
    cd "$B/$dir"
    # shellcheck disable=SC2086
    iverilog -g2012 -s tb -o sim.vvp $bug_files
    if vvp sim.vvp 2>&1 | tee sim.log | grep -q "TEST PASSED"; then
      echo "!! $dir: bug version passed unexpectedly"; exit 1
    fi
    # shellcheck disable=SC2086
    iverilog -g2012 -s tb -o sim_fixed.vvp $fixed_files
    vvp sim_fixed.vvp | tee sim_fixed.log
    grep -q "TEST PASSED" sim_fixed.log
  )
done

echo ""
echo "ALL CHECKS PASSED ✅"