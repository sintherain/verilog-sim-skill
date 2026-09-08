#!/usr/bin/env bash
# Open a waveform in GTKWave across platforms.
#
# usage: gtkwave_open.sh <waveform.vcd|.fst>
set -euo pipefail

FILE="${1:?usage: gtkwave_open.sh <waveform.vcd|.fst>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

G="$(command -v gtkwave || true)"
if [ -z "$G" ]; then
  G="$(python3 "$HERE/env_detect.py" --plain 2>/dev/null | sed -n 's/^gtkwave: //p' | cut -d' ' -f1 || true)"
fi
if [ -z "$G" ]; then
  echo "ERROR: gtkwave not found — see scripts/env_detect.py --plain" >&2
  exit 1
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # MSYS2: launch via cmd so the GUI detaches from this shell
    cmd //c start "" "$(cygpath -w "$G")" "$(cygpath -w "$FILE")" ;;
  Darwin)
    open -a "$G" "$FILE" ;;
  *)
    nohup "$G" "$FILE" >/dev/null 2>&1 & ;;
esac