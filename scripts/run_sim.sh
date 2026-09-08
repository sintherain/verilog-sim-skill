#!/usr/bin/env bash
# One-command build + simulate (+ optional VCD check) for the verilog-sim skill.
#
# usage: run_sim.sh [-d <workdir>] [--check] [SIM_TOP override?] <source.v> <tb.v>
#   -d DIR     work in DIR (default: current dir; created if missing)
#   --check    after simulation, run scripts/vcd_checker.py on waveform.vcd
#              (uses signals.json from the workdir when present)
#   SIM_TOP    env var, top module to compile (default: tb)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="."
CHECK=0
FILES=()

usage() { echo "usage: run_sim.sh [-d workdir] [--check] [--errmap] <file...> (SIM_TOP=tb)"; }
PY="${PY:-$(command -v python3 || command -v python || echo python3)}"
ERRMAP=0

while [ $# -gt 0 ]; do
  case "$1" in
    -d) WORK="$2"; shift 2 ;;
    --check) CHECK=1; shift ;;
    --errmap) ERRMAP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) FILES+=("$1"); shift ;;
  esac
done

[ ${#FILES[@]} -gt 0 ] || { usage; exit 2; }

# resolve sources against the ORIGINAL cwd (we cd into $WORK below)
for i in "${!FILES[@]}"; do
  case "${FILES[$i]}" in
    /*) ;;
    *) FILES[$i]="$PWD/${FILES[$i]}" ;;
  esac
done

mkdir -p "$WORK"
cd "$WORK"

# ---- locate tools (detector first, PATH fallback) ----
"${PY:-python3}" "$HERE/env_detect.py" > /dev/null 2>&1 || true
IVERILOG="$("${PY:-python3}" - "$HERE" <<'PY' 2>/dev/null || true
import json, subprocess, sys
r = subprocess.run([sys.executable, sys.argv[1] + "/env_detect.py"],
                   capture_output=True, text=True)
try:
    d = json.loads(r.stdout)
    print(d["tools"]["iverilog"]["path"])
except Exception:
    pass
PY
)"
VVP="$("${PY:-python3}" - "$HERE" <<'PY' 2>/dev/null || true
import json, subprocess, sys
r = subprocess.run([sys.executable, sys.argv[1] + "/env_detect.py"],
                   capture_output=True, text=True)
try:
    d = json.loads(r.stdout)
    print(d["tools"]["vvp"]["path"])
except Exception:
    pass
PY
)"
[ -n "$IVERILOG" ] || IVERILOG="$(command -v iverilog || true)"
[ -n "$VVP" ] || VVP="$(command -v vvp || true)"
if [ -z "$IVERILOG" ] || [ -z "$VVP" ]; then
  echo "ERROR: iverilog/vvp not found — install them or fix PATH." >&2
  "${PY:-python3}" "$HERE/env_detect.py" --plain >&2 || true
  exit 3
fi

SIM_TOP="${SIM_TOP:-tb}"
echo "== [1/3] compile (top=$SIM_TOP) =="
if ! "$IVERILOG" -g2012 -s "$SIM_TOP" -o sim.vvp "${FILES[@]}" 2> build.log; then
  echo "!! compilation failed" >&2
  sed 's/^/    /' build.log >&2
  if [ "$ERRMAP" = 1 ]; then
    echo "?? error analysis (scripts/errmap.py):" >&2
    "$PY" "$HERE/errmap.py" --log build.log >&2 || true
  fi
  exit 4
fi

echo "== [2/3] simulate =="
"$VVP" sim.vvp | tee sim.log
STATUS=${PIPESTATUS[0]}
if [ "$STATUS" -ne 0 ] && [ "$ERRMAP" = 1 ] && [ -f sim.log ]; then
  echo "?? error analysis (scripts/errmap.py):" >&2
  "$PY" "$HERE/errmap.py" --log sim.log >&2 || true
fi

if [ "$CHECK" = 1 ]; then
  if [ -f waveform.vcd ]; then
    echo "== [3/3] vcd check =="
    CFG=()
    [ -f signals.json ] && CFG=(--config signals.json)
    "${PY:-python3}" "$HERE/vcd_checker.py" waveform.vcd "${CFG[@]}" || STATUS=$?
  else
    echo "!! waveform.vcd not found, skip vcd check" >&2
  fi
else
  echo "== [3/3] done (use --check to validate waveform.vcd) =="
fi

exit "$STATUS"